module Tricorder.Daemon.Hpack (main) where

import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Clock (Clock)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.Debounce (Debounce)
import Atelier.Effects.FileWatcher (FileWatcher)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Effectful.Reader.Static (Reader)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.FileWatcher qualified as FileWatcher
import Atelier.Effects.Log qualified as Log
import Atelier.Effects.Publishing.Pub qualified as Pub
import Atelier.Effects.Publishing.Sub qualified as Sub
import Data.List qualified as List
import Effectful.Reader.Static qualified as Reader

import Tricorder.Daemon.Hpack.Effect (Hpack)
import Tricorder.Runtime (ProjectRoot (..))

import Tricorder.Daemon.Hpack.Effect qualified as Hpack


main
    :: ( Chan :> es
       , Clock :> es
       , Conc :> es
       , Debounce FilePath :> es
       , FileWatcher :> es
       , Hpack :> es
       , Log :> es
       , Reader ProjectRoot :> es
       )
    => Eff es ()
main = runPubSub @RePack $ Conc.scoped do
    hpackInPath <- Hpack.hpackIsInPath
    when hpackInPath do
        projectRoot <- Reader.ask
        Conc.fork_ $ Sub.listen_ \(RePack path) -> runHpack path
        vacuous $ watchPackageYaml projectRoot


runHpack :: (Hpack :> es, Log :> es) => FilePath -> Eff es ()
runHpack path = do
    res <- Hpack.hpack path
    case res of
        Left err -> Log.err $ "Hpack error: " <> err
        Right result ->
            Log.info
                $ "Hpack: " <> case result of
                    Hpack.Generated ->
                        "generated " <> toText path
                    Hpack.Unchanged ->
                        "already up-to-date: " <> toText path
                    Hpack.WasEditedManually ->
                        "cabal file was edited manually: " <> toText path
                    Hpack.WasGeneratedWithNewerHpack ->
                        "cabal file was generated with a newer version of Hpack: " <> toText path
                    Hpack.UnknownSuccess output -> "unknown successful output: " <> output


watchPackageYaml
    :: ( Debounce FilePath :> es
       , FileWatcher :> es
       , Pub RePack :> es
       )
    => ProjectRoot -> Eff es Void
watchPackageYaml root = do
    FileWatcher.watchFilePathsDebounced
        [FileWatcher.dirWhere root.getProjectRoot (packageYaml `List.isSuffixOf`)]
        \path _ -> Pub.publish $ RePack path


data RePack = RePack FilePath


packageYaml :: FilePath
packageYaml = "package.yaml"
