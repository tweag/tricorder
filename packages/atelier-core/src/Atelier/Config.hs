{-# LANGUAGE AllowAmbiguousTypes #-}

-- | Layered application configuration.
--
-- A configuration is assembled from a base JSON\/YAML document plus environment
-- variable overrides, then decoded on demand by type-level key:
--
-- * 'envOverrides' turns @PREFIX__A__B=value@ variables into a nested JSON
--   'Value';
-- * 'deepMerge' overlays that onto the base document, producing a
--   'LoadedConfig';
-- * 'extractConfig' and 'extractNestedConfig' decode a section by 'Symbol' key,
--   falling back to the target type's 'Default' instance when the key is
--   missing or fails to decode;
-- * 'runConfig' hands a decoded section to a computation as a 'Reader'.
--
-- == Worked example
--
-- Given a base document (say, decoded from a @base.yaml@ holding
-- @server: { port: 8080, host: localhost }@) and a @MYAPP@ environment prefix:
--
-- @
-- data Server = Server { port :: Int, host :: Text }
--     deriving stock (Generic)
--     deriving (FromJSON) via (QuietSnake Server)
--
-- instance Default Server where
--     def = Server { port = 80, host = \"0.0.0.0\" }
--
-- loadServer :: (Env :> es) => Value -> Eff es Server
-- loadServer base = do
--     overrides <- envOverrides \"MYAPP\"            -- e.g. MYAPP__SERVER__PORT=9090
--     let loaded = LoadedConfig (deepMerge base overrides)
--     pure (extractNestedConfig \@\"server\" loaded)
-- @
--
-- With @MYAPP__SERVER__PORT=9090@ set in the environment, @loadServer@ yields
-- @Server { port = 9090, host = \"localhost\" }@: the env override wins on
-- @port@, the base document supplies @host@, and the 'Default' instance would
-- cover any field absent from both.
module Atelier.Config
    ( envOverrides
    , deepMerge
    , extractConfig
    , extractNestedConfig
    , LoadedConfig (..)
    , runConfig
    )
where

import Data.Aeson (FromJSON (..), Value (..))
import Data.Default (Default (..))
import Effectful.Exception (evaluate)
import Effectful.Reader.Static (Reader, ask, runReader)
import GHC.TypeLits (KnownSymbol, Symbol, symbolVal)

import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE

import Atelier.Effects.Env (Env, getEnvironment)


-- | Build a nested JSON Object from environment variables with the given prefix.
-- Variables are expected in the form PREFIX__SEG1__SEG2=value.
-- Double underscore is the path separator; single underscore is preserved within segments.
envOverrides :: (Env :> es) => Text -> Eff es Value
envOverrides prefix = do
    allEnv <- getEnvironment
    let prefixStr = toString prefix <> "__"
        matching = [(k, v) | (k, v) <- allEnv, prefixStr `isPrefixOf` k]
        pairs = [(splitPath (drop (length prefixStr) k), parseScalar (toText v)) | (k, v) <- matching]
    pure $ foldl' insertNested (Object KM.empty) pairs
  where
    splitPath :: String -> [Text]
    splitPath = map T.toLower . T.splitOn "__" . toText

    insertNested :: Value -> ([Text], Value) -> Value
    insertNested base ([], _) = base
    insertNested base ([k], v) =
        let key = fromString (toString k)
        in  Object $ case base of
                Object m -> KM.insert key v m
                _ -> KM.singleton key v
    insertNested base (k : ks, v) =
        let key = fromString (toString k)
            child = case base of
                Object m -> fromMaybe (Object KM.empty) (KM.lookup key m)
                _ -> Object KM.empty
            merged = insertNested child (ks, v)
        in  Object $ case base of
                Object m -> KM.insert key merged m
                _ -> KM.singleton key merged


-- | Parse a scalar text value as its natural JSON type when possible,
-- falling back to a JSON String.
parseScalar :: Text -> Value
parseScalar t =
    fromMaybe (String t)
        $ Aeson.decodeStrict
        $ TE.encodeUtf8 t


-- | Deep merge two JSON values. Right wins on conflict for non-Object values;
-- Objects are merged recursively.
deepMerge :: Value -> Value -> Value
deepMerge (Object l) (Object r) = Object $ KM.unionWith deepMerge l r
deepMerge _ r = r


-- | A fully merged configuration document (base overlaid with overrides), ready
-- to have sections extracted from it by key.
newtype LoadedConfig = LoadedConfig Value


-- | Pure variant of 'runConfig': extract and decode a config section from a 'LoadedConfig'
-- without entering the effect stack. Falls back to the type's 'Default' instance on
-- missing key or decode failure.
extractConfig
    :: forall (key :: Symbol) r
     . (Default r, FromJSON r, KnownSymbol key)
    => LoadedConfig
    -> r
extractConfig (LoadedConfig root) =
    case root of
        Aeson.Object m ->
            case KM.lookup (fromString (symbolVal (Proxy @key))) m of
                Nothing -> def
                Just v -> case Aeson.fromJSON v of
                    Aeson.Success a -> a
                    Aeson.Error _ -> def
        _ -> def


-- | Variant of 'extractConfig' that extracts nested configuration values.
-- Nested properties are delimited by @"."@, so @foo.bar@ would attempt to
-- extract the nested property @bar@ contained in the top-level property @foo@.
--
-- Example:
--
-- Assuming @cfg@ is a 'LoadedConfig' representing the following JSON/YAML
-- structure:
--
-- @
-- {
--   "foo": {
--     "bar": "test"
--   }
-- }
-- @
--
-- The following will be @True@:
--
-- @
-- extractNestedConfig \@"foo.bar" \@Text cfg == "test"
-- @
extractNestedConfig
    :: forall (key :: Symbol) r. (Default r, FromJSON r, KnownSymbol key) => LoadedConfig -> r
extractNestedConfig (LoadedConfig root) = go props root
  where
    props = T.splitOn "." $ toText $ symbolVal $ Proxy @key

    go (p : ps) (Aeson.Object m) = maybe def (go ps) $ KM.lookup (fromString $ toString p) m
    go (_ : _) _ = def
    go [] x = fromJSON x

    fromJSON x = case Aeson.fromJSON x of
        Aeson.Success a -> a
        Aeson.Error _ -> def


-- | Extract and decode a (potentially nested) config section by type-level key
-- from the root config Value.
-- Falls back to the type's 'Default' instance if the (nested) key is absent.
runConfig
    :: forall (key :: Symbol) r es a
     . (Default r, FromJSON r, KnownSymbol key, Reader LoadedConfig :> es)
    => Eff (Reader r : es) a -> Eff es a
runConfig act = do
    loadedCfg <- ask
    cfg <- evaluate $ extractNestedConfig @key loadedCfg
    runReader (cfg) act
