module Tricorder.Session.Repl
    ( Repl (..)
    , resolveRepl
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Yaml (decodeEither')
import Effectful.Exception (throwIO)
import System.FilePath ((</>))
import System.IO.Error (userError)

import Atelier.Effects.FileSystem qualified as FileSystem
import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM

import Tricorder.Runtime (ProjectRoot (..))


data Repl = StackMulti | Stack | Cabal | Unknown
    deriving stock (Eq, Generic, Show)


-- | Resolve the project's REPL kind from the filesystem, independent of any
-- user-supplied @build@/@test@/@eval@ command template. This is the single
-- source of truth for 'Repl': it decides which automatically resolved
-- template applies to each of the three forms, and how targets are rendered
-- for all three, regardless of whether any of them has a custom
-- @command_template@.
resolveRepl :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
resolveRepl pr@(ProjectRoot projectRoot) = do
    hasStack <- FileSystem.doesFileExist $ projectRoot </> "stack.yaml"
    if hasStack
        then stackReplKind pr
        else pure Cabal


stackReplKind :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
stackReplKind (ProjectRoot projectRoot) = do
    stackYaml <- FileSystem.readFileBs $ projectRoot </> "stack.yaml"
    case decodeEither' stackYaml of
        Left err -> throwIO $ userError $ "Could not read and decode stack.yaml: " <> show err
        Right value -> pure $ case value of
            Aeson.Object km -> case KM.lookup "packages" km of
                Just (Aeson.Array arr) | length arr > 1 -> StackMulti
                _ -> Stack
            _ -> Stack
