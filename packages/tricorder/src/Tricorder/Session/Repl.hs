module Tricorder.Session.Repl
    ( Repl (..)
    , resolveRepl
    )
where

import Atelier.FileSystem.Path ((</>))
import Data.Aeson (ToJSON)
import Data.Yaml (decodeEither')
import Effectful.Exception (throwIO)
import Effectful.FileSystem (FileSystem)
import GHC.Generics (Generically (..))
import System.IO.Error (userError)

import Atelier.FileSystem.File qualified as File
import Atelier.FileSystem.Path qualified as Path
import Data.Aeson qualified as Aeson
import Data.Aeson.KeyMap qualified as KM

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))


data Repl = StackMulti | Stack | Cabal | Unknown
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Generically Repl


-- | Resolve the project's REPL kind from the filesystem, independent of any
-- @build@\/@test@\/@eval@ command template — this decides both the
-- automatically resolved templates and how targets are rendered for all
-- three phases.
resolveRepl :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
resolveRepl pr@(ProjectRoot projectRoot) = do
    hasStack <- File.exists $ projectRoot </> Path.relative @"stack.yaml"
    if hasStack
        then stackReplKind pr
        else pure Cabal


stackReplKind :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
stackReplKind (ProjectRoot projectRoot) = do
    stackYaml <- File.read $ projectRoot </> Path.relative @"stack.yaml"
    case decodeEither' stackYaml of
        Left err -> throwIO $ userError $ "Could not read and decode stack.yaml: " <> show err
        Right value -> pure $ case value of
            Aeson.Object km -> case KM.lookup "packages" km of
                Just (Aeson.Array arr) | length arr > 1 -> StackMulti
                _ -> Stack
            _ -> Stack
