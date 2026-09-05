-- | Database connection configuration and pool acquisition.
--
-- 'DBConfig' describes how to reach a database as one user, and 'PoolConfig'
-- tunes its connection pool. 'acquireDatabasePools' builds separate reader and
-- writer pools ('DBPools'), typically using distinct least-privilege roles.
module Atelier.Effects.DB.Config
    ( DBConfig (..)
    , DBPools (..)
    , PoolConfig (..)
    , acquireDatabasePool
    , acquireDatabasePools
    )
where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson (FromJSON)

import Hasql.Connection.Setting qualified as Setting
import Hasql.Connection.Setting.Connection qualified as Connection
import Hasql.Connection.Setting.Connection.Param qualified as Param
import Hasql.Pool qualified as Pool
import Hasql.Pool.Config qualified as Pool


-- | Connection pool configuration.
data PoolConfig = PoolConfig
    { size :: Int
    -- ^ Maximum number of connections in the pool.
    , acquisitionTimeoutSeconds :: Int
    -- ^ How long to wait for a free connection before failing.
    , agingTimeoutSeconds :: Int
    -- ^ Maximum lifetime of a connection before it is retired.
    , idlenessTimeoutSeconds :: Int
    -- ^ How long an idle connection is kept before being closed.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake PoolConfig


-- | Connection details for reaching a database as a single user.
data DBConfig = DBConfig
    { host :: Text
    -- ^ Database server host.
    , port :: Word16
    -- ^ Database server port.
    , user :: Text
    -- ^ Role to connect as.
    , password :: Text
    -- ^ Password for the role.
    , databaseName :: Text
    -- ^ Name of the database to connect to.
    , pool :: PoolConfig
    -- ^ Connection pool settings.
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON) via QuietSnake DBConfig


-- | Separate connection pools for read and write operations.
data DBPools = DBPools
    { readerPool :: Pool.Pool
    -- ^ Pool for read-only queries.
    , writerPool :: Pool.Pool
    -- ^ Pool for write transactions.
    }


-- | Acquire a single database connection pool
acquireDatabasePool :: DBConfig -> IO Pool.Pool
acquireDatabasePool config = do
    let settings =
            [ Pool.staticConnectionSettings
                [ Setting.connection
                    $ Connection.params
                        [ Param.host config.host
                        , Param.port config.port
                        , Param.user config.user
                        , Param.password config.password
                        , Param.dbname config.databaseName
                        ]
                ]
            , Pool.size config.pool.size
            , Pool.acquisitionTimeout (fromIntegral config.pool.acquisitionTimeoutSeconds)
            , Pool.agingTimeout (fromIntegral config.pool.agingTimeoutSeconds)
            , Pool.idlenessTimeout (fromIntegral config.pool.idlenessTimeoutSeconds)
            ]

    Pool.acquire $ Pool.settings settings


-- | Acquire both read and write connection pools
-- Uses different database users for read-only and read-write operations
acquireDatabasePools
    :: DBConfig
    -- ^ Read-only user config
    -> DBConfig
    -- ^ Read-write user config
    -> IO DBPools
acquireDatabasePools readerConfig writerConfig = do
    readerPool <- acquireDatabasePool readerConfig
    writerPool <- acquireDatabasePool writerConfig
    pure $ DBPools {readerPool, writerPool}
