-- | An effect for reading process environment variables.
module Atelier.Effects.Env
    ( Env
    , all
    , lookup
    , runIO
    , runConst
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Prelude hiding (All (..), all)

import Data.List qualified as List
import System.Environment qualified as System


-- | Effect for reading the process environment.
data Env :: Effect where
    -- | The full environment as a list of @(name, value)@ pairs.
    All :: Env m [(String, String)]
    -- | Pick out one value from the environment.
    Lookup :: String -> Env m (Maybe String)


makeEffect ''Env


-- | Interpret 'Env' against the real process environment.
runIO :: (IOE :> es) => Eff (Env : es) a -> Eff es a
runIO = interpret_ $ \case
    All -> liftIO System.getEnvironment
    Lookup key -> liftIO $ System.lookupEnv key


-- | Interpret 'Env' with a fixed environment.
runConst :: [(String, String)] -> Eff (Env : es) a -> Eff es a
runConst env = interpret_ $ \case
    All -> pure env
    Lookup key -> pure $ List.lookup key env
