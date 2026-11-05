module Tricorder.Session.Repl
    ( Repl (..)
    , resolveRepl
    )
where

import Atelier.Effects.FileSystem (FileSystem)
import Data.Aeson (ToJSON)
import Data.Yaml (decodeEither')
import Effectful.Exception (throwIO)
import GHC.Generics (Generically (..))
import System.FilePath ((</>))
import System.IO.Error (userError)

import Atelier.Effects.FileSystem qualified as FileSystem
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
    stackDir <- findFileUpwards "stack.yaml" projectRoot
    case stackDir of
        Just dir -> stackReplKind $ dir </> "stack.yaml"
        Nothing -> pure Cabal


stackReplKind :: (FileSystem :> es) => FilePath -> Eff es Repl
stackReplKind stackYamlPath = do
    stackYaml <- FileSystem.readFileBs stackYamlPath
    case decodeEither' stackYaml of
        Left err -> throwIO $ userError $ "Could not read and decode stack.yaml: " <> show err
        Right value -> pure $ case value of
            Aeson.Object km -> case KM.lookup "packages" km of
                Just (Aeson.Array arr) | length arr > 1 -> StackMulti
                _ -> Stack
            _ -> Stack
