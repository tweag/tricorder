-- | Hspec helpers for running tests against a real, ephemeral PostgreSQL
-- database.
--
-- 'withCleanTestDatabase' starts a temporary PostgreSQL server once per test
-- process, applies your migrations into a template database, and hands each spec
-- group a fresh database (as 'DBPools') that is truncated between individual
-- tests. Configure it with a 'TmpDbConfig'.
module Atelier.Testing.Database
    ( TmpDbConfig (..)
    , withCleanTestDatabase
    )
where

import Atelier.Effects.DB.Config (DBConfig (..), DBPools (..), PoolConfig (..), acquireDatabasePool, acquireDatabasePools)
import Atelier.Exception (trySyncIO)
import Control.Concurrent (MVar, forkIO, modifyMVar, newEmptyMVar, newMVar, putMVar, takeMVar, threadDelay, tryPutMVar, withMVar)
import Database.PostgreSQL.Simple.Options (Options (..))
import Hasql.Session (Session, statement)
import Hasql.Statement (Statement (..))
import System.IO.Unsafe (unsafePerformIO)
import System.Posix.User (getEffectiveUserName)
import Test.Hspec (Spec, SpecWith, around, runIO)

import Data.Text qualified as Text
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as UUIDv4
import Database.Postgres.Temp qualified as TmpPostgres
import Hasql.Decoders qualified as Decoders
import Hasql.Pool qualified as Pool


-- | Project-specific configuration for the temporary test database.
data TmpDbConfig = TmpDbConfig
    { readerUser :: Text
    -- ^ Role used for read-only connections
    , writerUser :: Text
    -- ^ Role used for read-write connections
    , schemaName :: Text
    -- ^ Application schema name
    , excludedTables :: [Text]
    -- ^ Tables to exclude from truncation between tests (e.g. migration tracking tables)
    , setupTemplate :: DBConfig -> Text -> IO ()
    -- ^ Called with admin config and template DB name; should apply all migrations
    }


-- | Shared postgres server and migrated template database, created once for
-- the entire test process. All calls to 'withCleanTestDatabase' share this
-- server, so all callers must use the same 'TmpDbConfig'.
data SharedServer = SharedServer
    { socketDir :: String
    , portNum :: Word16
    , tmpUser :: String
    , templateDbName :: Text
    , defaultPool :: PoolConfig
    }


{-# NOINLINE sharedServerVar #-}
sharedServerVar :: MVar (Maybe SharedServer)
sharedServerVar = unsafePerformIO (newMVar Nothing)


acquireSharedServer :: TmpDbConfig -> IO SharedServer
acquireSharedServer cfg = modifyMVar sharedServerVar $ \case
    Just server -> pure (Just server, server)
    Nothing -> do
        server <- startSharedServer cfg
        pure (Just server, server)


-- | Starts a TmpPostgres server in a background thread, applies migrations
-- once into a template database, then keeps the server alive for the process
-- lifetime.
startSharedServer :: TmpDbConfig -> IO SharedServer
startSharedServer cfg = do
    effectiveUser <- getEffectiveUserName
    readyVar <- newEmptyMVar
    void $ forkIO $ do
        TmpPostgres.withDbCache $ \dbCache -> do
            let config = TmpPostgres.cacheConfig dbCache
            result <- TmpPostgres.withConfig config $ \db -> do
                let Options {host = Last mHost, port = Last mPort, user = Last mUser} =
                        TmpPostgres.toConnectionOptions db
                    socketDir = fromMaybe "localhost" mHost
                    portNum = fromIntegral (fromMaybe 5432 mPort)
                    tmpUser = fromMaybe effectiveUser mUser
                    pool =
                        PoolConfig
                            { size = 10
                            , acquisitionTimeoutSeconds = 5
                            , agingTimeoutSeconds = 1800
                            , idlenessTimeoutSeconds = 600
                            }
                    adminConfig =
                        DBConfig
                            { host = toText socketDir
                            , port = portNum
                            , user = toText tmpUser
                            , password = ""
                            , databaseName = "postgres"
                            , pool = pool
                            }
                setupResult <- trySyncIO $ do
                    templateName <- generateUniqueDatabaseName
                    adminPool <- acquireDatabasePool adminConfig
                    createDatabase adminPool templateName
                    cfg.setupTemplate adminConfig templateName
                    grantTruncatePrivileges adminConfig templateName cfg.schemaName cfg.writerUser
                    pure $ SharedServer {socketDir, portNum, tmpUser, templateDbName = templateName, defaultPool = pool}
                case setupResult of
                    Left e -> putMVar readyVar (Left (show e))
                    Right server -> do
                        putMVar readyVar (Right server)
                        forever $ threadDelay 1_000_000_000
            case result of
                Left e -> void $ tryPutMVar readyVar (Left (show e))
                Right _ -> pure ()
    takeMVar readyVar >>= either error pure


-- | Sets up a fresh database for the spec group (once, during spec
-- construction) and truncates all tables before each individual test.
-- The postgres server and template are shared across the process.
--
-- Usage:
-- @
-- spec :: Spec
-- spec = withCleanTestDatabase myConfig $ do
--   it "can read from the database" $ \pools -> do
--     -- Test code using pools
-- @
withCleanTestDatabase :: TmpDbConfig -> SpecWith DBPools -> Spec
withCleanTestDatabase cfg spec = do
    pools <- runIO $ setupTestDatabase cfg
    lock <- runIO $ newMVar ()
    around (\action -> withMVar lock $ \_ -> cleanDatabase cfg pools >> action pools) spec


-- | Create a database from the shared template and acquire connection pools.
-- The database is not explicitly dropped — TmpPostgres cleans up on exit.
setupTestDatabase :: TmpDbConfig -> IO DBPools
setupTestDatabase cfg = do
    server <- acquireSharedServer cfg
    dbName <- generateUniqueDatabaseName
    let adminConfig =
            DBConfig
                { host = toText server.socketDir
                , port = server.portNum
                , user = toText server.tmpUser
                , password = ""
                , databaseName = "postgres"
                , pool = server.defaultPool
                }
        readerConfig =
            DBConfig
                { host = toText server.socketDir
                , port = server.portNum
                , user = cfg.readerUser
                , password = ""
                , databaseName = dbName
                , pool = server.defaultPool
                }
        writerConfig =
            DBConfig
                { host = toText server.socketDir
                , port = server.portNum
                , user = cfg.writerUser
                , password = ""
                , databaseName = dbName
                , pool = server.defaultPool
                }
    createDatabaseFromTemplate adminConfig dbName server.templateDbName
    acquireDatabasePools readerConfig writerConfig


createDatabaseFromTemplate :: DBConfig -> Text -> Text -> IO ()
createDatabaseFromTemplate adminConfig dbName templateName = do
    pool <- acquireDatabasePool adminConfig
    runOrThrow pool
        $ statement ()
        $ Statement
            (encodeUtf8 $ "CREATE DATABASE " <> dbName <> " TEMPLATE " <> templateName)
            mempty
            Decoders.noResult
            False


createDatabase :: Pool.Pool -> Text -> IO ()
createDatabase pool dbName =
    runOrThrow pool
        $ statement ()
        $ Statement (encodeUtf8 $ "CREATE DATABASE " <> dbName) mempty Decoders.noResult False


-- | Grant TRUNCATE on all tables in the schema to the writer role.
-- Applied to the template database so all copies inherit the grant.
grantTruncatePrivileges :: DBConfig -> Text -> Text -> Text -> IO ()
grantTruncatePrivileges config dbName schema writerRole = do
    pool <- acquireDatabasePool (config {databaseName = dbName})
    runOrThrow pool
        $ statement ()
        $ Statement
            (encodeUtf8 $ "GRANT TRUNCATE ON ALL TABLES IN SCHEMA " <> schema <> " TO " <> writerRole)
            mempty
            Decoders.noResult
            False


-- | Truncate all tables in the schema except excluded ones.
cleanDatabase :: TmpDbConfig -> DBPools -> IO ()
cleanDatabase cfg pools =
    runOrThrow pools.writerPool $ do
        tableNames <- statement () queryTableNames
        unless (null tableNames)
            $ truncateTables (Text.intercalate "," (map (\t -> cfg.schemaName <> "." <> t) tableNames))
  where
    queryTableNames :: Statement () [Text]
    queryTableNames =
        Statement
            ( encodeUtf8
                $ "SELECT tablename FROM pg_tables WHERE schemaname = '"
                    <> cfg.schemaName
                    <> "'"
                    <> exclusions
            )
            mempty
            (decodeList Decoders.text)
            True

    exclusions =
        if null cfg.excludedTables then
            ""
        else
            " AND tablename NOT IN ("
                <> Text.intercalate "," (map (\t -> "'" <> t <> "'") cfg.excludedTables)
                <> ")"

    truncateTables :: Text -> Session ()
    truncateTables tableNames =
        statement ()
            $ Statement
                (encodeUtf8 $ "TRUNCATE TABLE " <> tableNames <> " CASCADE")
                mempty
                Decoders.noResult
                False


decodeList :: Decoders.Value a -> Decoders.Result [a]
decodeList val = Decoders.rowList $ Decoders.column $ Decoders.nonNullable val


runOrThrow :: Pool.Pool -> Session a -> IO a
runOrThrow pool sess =
    Pool.use pool sess >>= \case
        Left e -> error $ "Database operation failed: " <> show e
        Right a -> pure a


generateUniqueDatabaseName :: IO Text
generateUniqueDatabaseName = do
    uuid <- UUIDv4.nextRandom
    pure $ "testdb_" <> Text.replace "-" "_" (UUID.toText uuid)
