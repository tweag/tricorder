-- | An effect for reading process environment variables.
--
-- 'runEnv' reads the real process environment; 'runEnvConst' supplies a fixed
-- association list for tests.
module Atelier.Effects.Env
    ( Env
    , getEnvironment
    , lookupEnv
    , runEnv
    , runEnvConst
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)

import Data.List qualified as List
import System.Environment qualified as System


-- | Effect for reading the process environment.
data Env :: Effect where
    -- | The full environment as a list of @(name, value)@ pairs.
    GetEnvironment :: Env m [(String, String)]
    -- | Pick out one value from the environment.
    LookupEnv :: String -> Env m (Maybe String)


makeEffect ''Env


-- | Interpret 'Env' against the real process environment.
runEnv :: (IOE :> es) => Eff (Env : es) a -> Eff es a
runEnv = interpret_ $ \case
    GetEnvironment -> liftIO System.getEnvironment
    LookupEnv key -> liftIO $ System.lookupEnv key


-- | Interpret 'Env' with a fixed environment, for tests.
runEnvConst :: [(String, String)] -> Eff (Env : es) a -> Eff es a
runEnvConst env = interpret_ $ \case
    GetEnvironment -> pure env
    LookupEnv key -> pure $ List.lookup key env
