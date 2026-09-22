module Tricorder.CLI.App.Test (run) where

import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit, exitFailure)
import Atelier.Effects.File (File)
import Atelier.Effects.Posix.Daemons (Daemons, PidFile)
import Effectful (IOE)
import Effectful.Reader.Static (Reader)
import Tricorder.CLI.Command.IfDaemonIsStopped (IfDaemonIsStopped)
import Tricorder.CLI.Command.OutputFormat (OutputFormat (..))
import Tricorder.CLI.Command.Test (Command (..), SuitesOptions (..))
import Tricorder.CLI.Command.WaitMode (WaitMode (..))

import Atelier.Effects.Console qualified as Console
import Effectful.Reader.Static qualified as Reader
import Tricorder.CLI.Command.IfDaemonIsStopped qualified as IfDaemonIsStopped

import Tricorder.Build (BuildState (..))
import Tricorder.CLI.App.Test.SuiteView (defaultFields, schema)
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Socket.Client (queryStatus, queryStatusWait)
import Tricorder.Socket.UnixSocket (UnixSocket)

import Tricorder.CLI.App.Test.Json qualified as Json
import Tricorder.CLI.App.Test.Text qualified as Text
import Tricorder.CLI.Daemon qualified as Daemons
import Tricorder.CLI.FieldMask qualified as FieldMask
import Tricorder.Session.TestTarget qualified as TestTarget
import Tricorder.Socket.Client qualified as Client


run
    :: ( Console :> es
       , Daemons :> es
       , Delay :> es
       , Exit :> es
       , File :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Command -> Eff es ()
run command =
    printResult =<< case command of
        Suites opts -> showSuites opts


printResult :: (Console :> es, Exit :> es) => Either Text Text -> Eff es ()
printResult = \case
    Left err -> do
        Console.putTextLn err
        exitFailure
    Right res ->
        Console.putTextLn res


showSuites
    :: ( Daemons :> es
       , Delay :> es
       , File :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => SuitesOptions -> Eff es (Either Text Text)
showSuites opts =
    case validated of
        Left err -> pure $ case opts.format of
            TextOutput -> Left $ "Error: " <> err
            JsonOutput -> Json.argumentError err
        Right (targets, selection) ->
            ensureDaemonRunning opts.ifDaemonIsStopped do
                result <- awaitBuildStatus opts.wait
                case opts.format of
                    TextOutput ->
                        pure
                            $ Text.wrapTextShow result
                            $ Text.showBasePhase
                            $ Text.showSuites targets opts.testFilter selection
                    JsonOutput ->
                        pure
                            $ Json.wrapResponse
                            $ Json.showBasePhase result
                            $ Json.showSuites targets opts.testFilter selection
  where
    validated = do
        targets <- traverse parseTarget opts.suiteNames
        selection <- FieldMask.select schema $ fromMaybe defaultFields opts.fields
        pure (targets, selection)
    parseTarget suiteName =
        maybeToRight
            ( "invalid test suite name: "
                <> suiteName
                <> ". Test suite names are expected to be in the format of a Cabal target."
            )
            $ TestTarget.parse suiteName


awaitBuildStatus
    :: ( File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => WaitMode -> Eff es (Either Text BuildState)
awaitBuildStatus wait = do
    SocketPath sockPath <- Reader.ask
    case wait of
        WaitForBuild -> queryStatusWait sockPath
        ShowCurrent -> queryStatus sockPath


ensureDaemonRunning
    :: ( Daemons :> es
       , Delay :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => IfDaemonIsStopped -> Eff es (Either Text Text) -> Eff es (Either Text Text)
ensureDaemonRunning ifDaemonIsStopped continue = do
    isRunning <- Client.isDaemonRunning
    case (ifDaemonIsStopped, isRunning) of
        (IfDaemonIsStopped.Fail, False) -> pure $ Left "daemon is stopped"
        (IfDaemonIsStopped.StartDaemon, False) -> do
            ensureDaemonIsRunning
            continue
        (_, True) -> continue


ensureDaemonIsRunning
    :: ( Daemons :> es
       , Delay :> es
       , IOE :> es
       , Reader PidFile :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es ()
ensureDaemonIsRunning = do
    Daemons.startDaemon
    void Daemons.waitForDaemon
