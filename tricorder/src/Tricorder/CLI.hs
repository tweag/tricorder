module Tricorder.CLI
    ( showLog
    , showSource
    , showStatus
    , showTests
    ) where

import Atelier.Effects.Clock (Clock, currentTimeZone)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Delay (Delay)
import Atelier.Effects.Exit (Exit, exitFailure)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, followFile, readFileLbs)
import Data.Aeson (encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (utcToLocalTime)
import Effectful.Reader.Static (Reader, ask)

import Atelier.Effects.Console qualified as Console
import Data.ByteString.Lazy qualified as BSL
import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Arguments
    ( FollowMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    )
import Tricorder.BuildState
    ( BuildOutput (..)
    , BuildRecord (..)
    , BuildResult (..)
    , BuildState (..)
    , CyclePhase (..)
    , Diagnostic (..)
    , Severity (..)
    , TestOutput (..)
    , currentRecord
    )
import Tricorder.BuildState.BuildProgress (BuildProgress (..))
import Tricorder.CLI.Render
    ( diagnosticLineIndexed
    , formatDuration
    , renderSourceResults
    )
import Tricorder.Effects.UnixSocket (UnixSocket)
import Tricorder.GhcPkg.Types (SourceQuery)
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Session (renderTestTarget)
import Tricorder.Socket.Client (querySource, queryStatus, queryStatusWait)
import Tricorder.TestOutput (stripGhciNoise)

import Tricorder.BuildState.Test qualified as Test
import Tricorder.BuildState.Test qualified as Tests


-- | Print a build-command failure message and exit non-zero.
reportBuildFailed :: (Console :> es, Exit :> es) => Text -> Eff es a
reportBuildFailed msg = do
    Console.putTextLn "Build command failed:"
    Console.putTextLn msg
    exitFailure


showStatus
    :: ( Clock :> es
       , Console :> es
       , Exit :> es
       , File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => StatusOptions -> Eff es ()
showStatus opts = do
    SocketPath sockPath <- ask
    when (opts.wait == WaitForBuild && opts.format == TextOutput) $ do
        current <- queryStatus sockPath
        case current of
            Right st -> case st.cycle of
                Building _ -> Console.putStrLn "Building..."
                Restarting -> Console.putStrLn "Restarting..."
                Failed _ -> pure ()
                Settled
                    | testsRunning st -> Console.putStrLn "Testing..."
                    | otherwise -> pure ()
            Left _ -> pure ()
    result <-
        case opts.wait of
            WaitForBuild -> queryStatusWait sockPath
            ShowCurrent -> queryStatus sockPath
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right state ->
            case opts.format of
                JsonOutput -> do
                    Console.putStr $ BSL.toStrict $ encode state
                    Console.putStrLn ""
                TextOutput ->
                    renderText opts.verbosity opts.expand state
  where
    renderText verbosity expand state = case state.cycle of
        Building _ -> Console.putStrLn "Building..."
        Restarting -> Console.putStrLn "Restarting..."
        Failed msg -> reportBuildFailed msg
        Settled -> case (currentRecord state).build of
            NotBuilt -> Console.putStrLn "Building..."
            Built result
                | testsRunning state -> Console.putStrLn "Testing..."
                | otherwise -> do
                    tz <- currentTimeZone
                    let suites = stSuites state
                    case expand of
                        Just n ->
                            case result.diagnostics !!? (n - 1) of
                                Nothing ->
                                    Console.putTextLn
                                        $ "No diagnostic #"
                                            <> show n
                                            <> " (current build has "
                                            <> show (length result.diagnostics)
                                            <> ")"
                                Just d -> do
                                    Console.putTextLn $ diagnosticLineIndexed n d
                                    Console.putText d.text
                        Nothing -> do
                            let printDiag (i, d) = case verbosity of
                                    Verbose -> do
                                        Console.putTextLn $ diagnosticLineIndexed i d
                                        Console.putText d.text
                                    Concise ->
                                        Console.putTextLn $ diagnosticLineIndexed i d
                            mapM_ printDiag (zip [1 ..] result.diagnostics)
                            Console.putTextLn $ buildSummary tz result
                            mapM_ (uncurry (printTestRun verbosity)) $ Map.toList suites.getSuites
                            when (buildHasErrors result || Tests.hasFailedTests suites) exitFailure

    printTestRun verbosity tgt tr = do
        Console.putTextLn $ case tr of
            Test.SuiteRunning Nothing -> t <> "  running..."
            Test.SuiteRunning (Just p) -> t <> "  running... (" <> show p.compiled <> "/" <> show p.total <> ")"
            Test.SuiteErrored e -> t <> "  error: " <> e.message
            Test.SuiteCompleted c -> t <> "  " <> completionSummary c
        when (verbosity == Verbose) $ case tr of
            Test.SuiteCompleted c ->
                mapM_ (Console.putTextLn . ("  " <>)) (stripGhciNoise (T.lines c.output))
            _ -> pure ()
      where
        t = renderTestTarget tgt

    buildHasErrors r = any ((== SError) . (.severity)) r.diagnostics
    buildSummary tz r =
        let errs = length $ filter ((== SError) . (.severity)) r.diagnostics
            warns = length $ filter ((== SWarning) . (.severity)) r.diagnostics
            ts = toText $ "— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz r.completedAt)
            stats = toText $ "(" <> show r.moduleCount <> " modules, " <> formatDuration r.duration <> ")"
        in  if null r.diagnostics then
                "All good. " <> stats <> " " <> ts
            else
                show errs <> " error(s), " <> show warns <> " warning(s) " <> stats <> " " <> ts


-- | The suites held in the current build's test register.
stSuites :: BuildState -> Test.Suites
stSuites state = case (currentRecord state).tests of
    TestsRunning s -> s
    TestsDone s -> s
    TestsIdle -> Test.Suites mempty


-- | Whether the current build's tests are still running.
testsRunning :: BuildState -> Bool
testsRunning state = case (currentRecord state).tests of
    TestsRunning s -> Tests.anyRunningTests s
    _ -> False


completionSummary :: Test.SuiteCompletion -> Text
completionSummary c = statusText <> maybe "" (\d -> " (" <> formatDuration d <> ")") c.duration
  where
    statusText
        | null c.testCases = if c.passed then "passed" else "failed"
        | otherwise =
            let total = length c.testCases
                failedCount = length $ filter isFailedCase c.testCases
            in  if failedCount == 0 then
                    "passed (" <> show total <> ")"
                else
                    show failedCount <> "/" <> show total <> " failed"
    isFailedCase (Test.Case _ (Test.Failed _)) = True
    isFailedCase _ = False


showLog
    :: ( Console :> es
       , Delay :> es
       , FileSystem :> es
       )
    => FilePath -> FollowMode -> Eff es ()
showLog path followMode = do
    exists <- doesFileExist path
    if not exists then
        Console.putTextLn $ "Log file does not exist yet: " <> toText path
    else case followMode of
        Follow -> followFile path Console.putStr
        NoFollow -> readFileLbs path >>= Console.putStr . BSL.toStrict


showTests
    :: ( Console :> es
       , Exit :> es
       , File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => TestOptions -> Eff es ()
showTests opts = do
    SocketPath sockPath <- ask
    result <-
        case opts.wait of
            WaitForBuild -> queryStatusWait sockPath
            ShowCurrent -> queryStatus sockPath
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right state ->
            case state.cycle of
                Building _ -> Console.putStrLn "Build in progress, no test results yet."
                Restarting -> Console.putStrLn "Daemon restarting, no test results yet."
                Failed msg -> reportBuildFailed msg
                Settled -> renderTestRuns (stSuites state).getSuites
  where
    renderTestRuns suites
        | Map.null suites = Console.putStrLn "No test results."
        | Map.null filteredSuites = do
            Console.putStrLn "All passed."
            mapM_ (Console.putTextLn . ("  " <>) . renderTestTarget) $ Map.keys suites
        | otherwise = do
            mapM_ (uncurry printTestOutput) $ Map.toList filteredSuites
            when (any Tests.isFailedRun filteredSuites) exitFailure
      where
        filteredSuites =
            if opts.failedOnly then
                Map.filter Tests.isFailedRun suites
            else
                suites

    printTestOutput tgt tr = case tr of
        Test.SuiteRunning Nothing ->
            Console.putTextLn $ t <> "running..."
        Test.SuiteRunning (Just p) ->
            Console.putTextLn $ t <> "running... (" <> show p.compiled <> "/" <> show p.total <> ")"
        Test.SuiteErrored e ->
            Console.putTextLn $ t <> "error: " <> e.message
        Test.SuiteCompleted c -> do
            Console.putTextLn $ t <> completionSummary c
            if opts.failedOnly then
                if null c.testCases then do
                    Console.putTextLn "  (unrecognised test runner format — showing full output)"
                    mapM_ (Console.putTextLn . ("  " <>)) (stripGhciNoise (lines c.output))
                else
                    mapM_ printFailedCase (filter Test.caseFailed c.testCases)
            else
                mapM_ (Console.putTextLn . ("  " <>)) (stripGhciNoise (lines c.output))
      where
        t = renderTestTarget tgt <> "  "

    printFailedCase tc = do
        Console.putTextLn $ "  " <> tc.description
        case tc.outcome of
            Test.Failed details ->
                mapM_ (Console.putTextLn . ("    " <>)) (T.lines details)
            Test.Passed -> pure ()


showSource
    :: ( Console :> es
       , File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => [SourceQuery]
    -> Eff es ()
showSource queries = do
    SocketPath sockPath <- ask
    result <- querySource sockPath queries
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right results -> renderSourceResults results
