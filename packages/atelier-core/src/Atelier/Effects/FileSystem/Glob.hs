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

import Atelier.FileSystem.Path qualified as Path


data Glob :: Effect where
    -- | Lifted 'Glob.globDir'.
    GlobDir :: [Pattern] -> Path.Absolute -> Glob m [[Path.Absolute]]
    -- | Lifted 'Glob.globDir1'.
    GlobDir1 :: Pattern -> Path.Absolute -> Glob m [Path.Absolute]
    -- | Lifted 'Glob.glob'.
    Glob :: String -> Glob m [Path.Absolute]
    -- | Lifted 'Glob.globDirWith'.
    GlobDirWith
        :: GlobOptions -> [Pattern] -> Path.Absolute -> Glob m ([[Path.Absolute]], Maybe [Path.Absolute])


makeEffect ''Glob


runIO :: (IOE :> es) => Eff (Glob : es) a -> Eff es a
runIO = interpret_ \case
    GlobDir patterns filePath ->
        -- Should be safe to use `rights` here, unless `glob` does not behave
        -- the way they describe. The only instance this is unsafe is if you
        -- pass a `Path.relative @""`, an empty relative path, which causes
        -- `glob` to use the current working directory as the prefix for the
        -- resulting matches, which makes them in actuality _absolute_ paths.
        -- Because of this gotcha, we restrict ourselves to 'Path.Absolute'
        -- here.
        fmap (fmap (rights . fmap Path.fromFilePath))
            $ liftIO
            $ Glob.globDir patterns
            $ Path.toFilePath filePath
    GlobDir1 pattern filePath ->
        fmap (rights . fmap Path.fromFilePath)
            $ liftIO
            $ Glob.globDir1 pattern
            $ Path.toFilePath filePath
    Glob pattern -> fmap (rights . fmap Path.fromFilePath) $ liftIO $ Glob.glob pattern
    GlobDirWith opts patterns filePath ->
        fmap
            ( bimap
                (fmap (rights . fmap Path.fromFilePath))
                (fmap (rights . fmap Path.fromFilePath))
            )
            $ liftIO
            $ Glob.globDirWith opts patterns
            $ Path.toFilePath filePath


-- | Script element for the test interpreter.
data GlobScript
    = -- | Return this result for the next 'globDir' call.
      NextGlobDir [[Path.Absolute]]
    | -- | Return this result for the next 'globDir1' call.
      NextGlobDir1 [Path.Absolute]
    | -- | Return this result for the next 'glob' call.
      NextGlob [Path.Absolute]
    | -- | Return this result for the next 'globDirWith' call.
      NextGlobDirWith ([[Path.Absolute]], Maybe [Path.Absolute])


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
