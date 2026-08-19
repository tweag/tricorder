{-# OPTIONS_GHC -fforce-recomp #-}

-- | Build-time version information.
--
-- The git hash is spliced in at compile time via Template Haskell, so it
-- carries zero runtime overhead and requires no file I/O at startup.
--
-- The @-fforce-recomp@ pragma ensures GHC re-evaluates the TH splice on every
-- build invocation. Without it, GHC may skip recompilation when no source
-- files have changed (e.g. after a @git commit@), leaving the old hash baked
-- in until something else triggers a rebuild.
module Tricorder.Version (gitHash, VersionMismatch (..), checkVersion) where

import Data.Version (showVersion)
import Language.Haskell.TH (litE, runIO, stringL)
import System.Environment (lookupEnv)
import System.IO.Error (tryIOError)
import System.Process (readProcess)

import Paths_tricorder qualified as Pack


-- | Short git hash of the commit this binary was built from.
--
-- Resolution order at compile time:
--
-- 1. @TRICORDER_VERSION@ environment variable — useful for non-git VCS
--    (e.g. Jujutsu workspaces without a colocated @.git@) and for CI
--    pipelines that inject the version externally.
-- 2. @git rev-parse --short HEAD@ — the common case for git checkouts.
-- 3. @"unknown"@ — fallback when @git@ is unavailable.
gitHash :: Text
gitHash =
    "v"
        <> toText (showVersion Pack.version)
        <> " ("
        <> toText
            ( $( do
                    hash <- runIO $ do
                        override <- lookupEnv "TRICORDER_VERSION"
                        case override of
                            Just v -> pure v
                            Nothing ->
                                either (const "unknown") (filter (/= '\n'))
                                    <$> tryIOError (readProcess "git" ["rev-parse", "--short", "HEAD"] "")
                    litE (stringL hash)
               )
                :: String
            )
        <> ")"


data VersionMismatch = VersionMismatch
    { expected :: Text
    , received :: Text
    }
    deriving stock (Show)


checkVersion :: Text -> Either VersionMismatch ()
checkVersion clientVersion
    | clientVersion == gitHash = Right ()
    | otherwise = Left VersionMismatch {expected = gitHash, received = clientVersion}
