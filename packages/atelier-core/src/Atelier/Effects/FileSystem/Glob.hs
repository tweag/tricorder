module Atelier.Effects.FileSystem.Glob
    ( -- * Effect
      Glob (..)
    , globDir
    , globDir1
    , glob
    , globDirWith

      -- * Re-exports from 'System.FilePath.Glob'.
    , module GlobExports

      -- * Interpreters
    , runIO
    , runScripted
    , GlobScript (..)
    )
where

import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_, reinterpret)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.FilePath.Glob (GlobOptions, Pattern)

import System.FilePath.Glob qualified as Glob
import System.FilePath.Glob qualified as GlobExports hiding (glob, globDir, globDir1, globDirWith)


data Glob :: Effect where
    -- | Lifted 'Glob.globDir'.
    GlobDir :: [Pattern] -> FilePath -> Glob m [[FilePath]]
    -- | Lifted 'Glob.globDir1'.
    GlobDir1 :: Pattern -> FilePath -> Glob m [FilePath]
    -- | Lifted 'Glob.glob'.
    Glob :: String -> Glob m [FilePath]
    -- | Lifted 'Glob.globDirWith'.
    GlobDirWith :: GlobOptions -> [Pattern] -> FilePath -> Glob m ([[FilePath]], Maybe [FilePath])


makeEffect ''Glob


runIO :: (IOE :> es) => Eff (Glob : es) a -> Eff es a
runIO = interpret_ \case
    GlobDir patterns filePath -> liftIO $ Glob.globDir patterns filePath
    GlobDir1 pattern filePath -> liftIO $ Glob.globDir1 pattern filePath
    Glob pattern -> liftIO $ Glob.glob pattern
    GlobDirWith opts patterns filePath -> liftIO $ Glob.globDirWith opts patterns filePath


-- | Script element for the test interpreter.
data GlobScript
    = -- | Return this result for the next 'globDir' call.
      NextGlobDir [[FilePath]]
    | -- | Return this result for the next 'globDir1' call.
      NextGlobDir1 [FilePath]
    | -- | Return this result for the next 'glob' call.
      NextGlob [FilePath]
    | -- | Return this result for the next 'globDirWith' call.
      NextGlobDirWith ([[FilePath]], Maybe [FilePath])


-- | Scripted interpreter for testing. Pops the next matching entry off the
-- queue for each call; does not require 'IOE'.
runScripted :: [GlobScript] -> Eff (Glob : es) a -> Eff es a
runScripted script = reinterpret (evalState script) \_ -> \case
    GlobDir _ _ ->
        get >>= \case
            NextGlobDir r : rest -> put rest >> pure r
            _ -> error "GlobScripted: expected NextGlobDir but queue was empty or mismatched"
    GlobDir1 _ _ ->
        get >>= \case
            NextGlobDir1 r : rest -> put rest >> pure r
            _ -> error "GlobScripted: expected NextGlobDir1 but queue was empty or mismatched"
    Glob _ ->
        get >>= \case
            NextGlob r : rest -> put rest >> pure r
            _ -> error "GlobScripted: expected NextGlob but queue was empty or mismatched"
    GlobDirWith _ _ _ ->
        get >>= \case
            NextGlobDirWith r : rest -> put rest >> pure r
            _ -> error "GlobScripted: expected NextGlobDirWith but queue was empty or mismatched"
