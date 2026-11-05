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

import Tricorder.Runtime.ProjectRoot (ProjectRoot (..), findFileUpwards)


data Repl = StackMulti | Stack | Cabal | Unknown
    deriving stock (Eq, Generic, Show)
    deriving (ToJSON) via Generically Repl


-- | Resolve the project's REPL kind from the filesystem, independent of any
-- @build@\/@test@\/@eval@ command template — this decides both the
-- automatically resolved templates and how targets are rendered for all
-- three phases.
resolveRepl :: (FileSystem :> es) => ProjectRoot -> Eff es Repl
resolveRepl (ProjectRoot projectRoot) = do
    stackDir <- findFileUpwards stackYaml projectRoot
    case stackDir of
        Just dir -> stackReplKind $ dir </> stackYaml
        Nothing -> pure Cabal
  where
    stackYaml = Path.rel @"stack.yaml"


stackReplKind :: (FileSystem :> es) => Path.Absolute -> Eff es Repl
stackReplKind stackYamlPath = do
    stackYaml <- File.read stackYamlPath
    case decodeEither' stackYaml of
        Left err -> throwIO $ userError $ "Could not read and decode stack.yaml: " <> show err
        Right value -> pure $ case value of
            Aeson.Object km -> case KM.lookup "packages" km of
                Just (Aeson.Array arr) | length arr > 1 -> StackMulti
                _ -> Stack
            _ -> Stack
