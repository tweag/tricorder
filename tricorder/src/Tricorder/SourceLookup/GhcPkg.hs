module Tricorder.SourceLookup.GhcPkg
    ( GhcPkg
    , findModule
    , runGhcPkgIO
    , runGhcPkgScripted
    , GhcPkgScript (..)
    )
where

import Atelier.Effects.Process (Process, readProcessSafe)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret, reinterpret)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import Tricorder.SourceLookup.SourceQuery (ModuleName (..))

import Data.Text qualified as T

import Tricorder.Session.Command (Repl (..))
import Tricorder.SourceLookup.PackageId (PackageId (..))


data GhcPkg :: Effect where
    FindModule :: Repl -> ModuleName -> GhcPkg m (Maybe PackageId)


makeEffect ''GhcPkg


runGhcPkgIO :: (Process :> es) => Eff (GhcPkg : es) a -> Eff es a
runGhcPkgIO = interpret \_ -> \case
    FindModule repl modName -> do
        let cmd = "ghc-pkg"
            args = ["find-module", "--simple-output", toString $ unModuleName modName]
            stack = readProcessSafe "stack" $ ["exec", "--", cmd] <> args
            direct = readProcessSafe cmd args
        out <- case repl of
            Stack -> stack
            StackMulti -> stack
            Cabal -> direct
            Unknown -> direct
        pure $ out >>= fmap PackageId . listToMaybe . filter (not . T.null) . map T.strip . T.lines


-- | Script element for the test interpreter.
newtype GhcPkgScript
    = -- | Return this value for the next 'findModule' call.
      NextFindModule (Maybe PackageId)


-- | Scripted interpreter for testing. Does not require 'IOE'.
runGhcPkgScripted :: [GhcPkgScript] -> Eff (GhcPkg : es) a -> Eff es a
runGhcPkgScripted script = reinterpret (evalState script) \_ -> \case
    FindModule _ _ ->
        get >>= \case
            NextFindModule result : rest -> put rest >> pure result
            _ -> error "GhcPkgScripted: expected NextFindModule but queue was empty or mismatched"
