module Tricorder.CLI.Operations
    ( showLog
    , showSource
    , showStatus
    , showTests
    , showEvalComments
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

import Tricorder.Build (BuildState (..), Severity (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Build.Test (Suites (..))
import Tricorder.CLI.Arguments
    ( EvalCommentsOptions (..)
    , FollowMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    )
import Tricorder.CLI.Render
    ( diagnosticLineIndexed
    , formatDuration
    , renderSourceResults
    )
import Tricorder.Runtime (SocketPath (..))
import Tricorder.Session.TestTarget (renderTestTarget)
import Tricorder.Socket.Client (querySource, queryStatus, queryStatusWait)
import Tricorder.Socket.UnixSocket (UnixSocket)
import Tricorder.SourceLookup (SourceQuery)
import Tricorder.TestOutput (stripGhciNoise)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Build.Test qualified as Tests


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
    when (opts.wait == WaitForBuild && opts.format == TextOutput) do
        displayPendingBuildStatus
    result <- awaitBuildStatus opts.wait
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
    renderText verbosity expand state = case state.phase of
        Build.Starting -> Console.putStrLn "Building..."
        Build.Building _ _ -> Console.putStrLn "Building..."
        Build.Failed msg -> reportBuildFailed msg
        Build.PostBuilding _ postBuild ->
            let
                testsRunning = Test.anyRunningTests postBuild.testSuites
                commentsEvaluating = Eval.phasePending postBuild.evalComments
            in
                if
                    | testsRunning && commentsEvaluating ->
                        Console.putStrLn "Testing and evaluating comments..."
                    | testsRunning ->
                        Console.putStrLn "Testing..."
                    | commentsEvaluating ->
                        Console.putStrLn "Evaluating comments..."
                    | otherwise ->
                        Console.putStrLn "Post-procesing..."
        Build.Finished result postBuild -> do
            tz <- currentTimeZone
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
                    mapM_ (uncurry (printTestRun verbosity)) $ Map.toList postBuild.testSuites.getSuites
                    when (buildHasErrors result || Test.hasFailedTests postBuild.testSuites) exitFailure

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
            stats = toText $ "(" <> show r.moduleCount <> " modules, " <> formatDuration r.duration.getDuration <> ")"
        in  if null r.diagnostics then
                "All good. " <> stats <> " " <> ts
            else
                show errs <> " error(s), " <> show warns <> " warning(s) " <> stats <> " " <> ts


completionSummary :: Test.SuiteCompletion -> Text
completionSummary c = statusText <> maybe "" (\d -> " (" <> formatDuration d.getDuration <> ")") c.duration
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
    result <- awaitBuildStatus opts.wait
    case result of
        Left err -> Console.putTextLn $ "Error: " <> err
        Right state ->
            case state.phase of
                Build.Starting -> Console.putStrLn "Daemon starting, no test results yet."
                Build.Building _ _ -> Console.putStrLn "Build in progress, no test results yet."
                Build.PostBuilding _ postBuild -> renderTestRuns postBuild.testSuites.getSuites
                Build.Finished _ postBuild -> renderTestRuns postBuild.testSuites.getSuites
                Build.Failed msg -> reportBuildFailed msg
  where
    renderTestRuns suites
        | Map.null suites = Console.putStrLn "No test results."
        | Map.null filteredSuites = do
            Console.putStrLn "All passed."
            mapM_ (Console.putTextLn . ("  " <>) . renderTestTarget) $ Map.keys suites
        | otherwise = do
            mapM_ (uncurry printTestOutput) $ Map.toList filteredSuites
            when (any Test.isFailedRun filteredSuites) exitFailure
      where
        filteredSuites =
            if opts.failedOnly then
                Map.filter Test.isFailedRun suites
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


showEvalComments
    :: ( Console :> es
       , Exit :> es
       , File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => EvalCommentsOptions -> Eff es ()
showEvalComments opts = do
    when (opts.wait == WaitForBuild && opts.format == TextOutput) do
        displayPendingBuildStatus
    result <- awaitBuildStatus opts.wait
    case opts.format of
        TextOutput -> displayTextOutput result
        JsonOutput -> displayJsonOutput result


displayTextOutput
    :: ( Console :> es
       , Exit :> es
       )
    => Either Text BuildState -> Eff es ()
displayTextOutput = \case
    Left err -> do
        Console.putTextLn $ "Error: " <> err
        exitFailure
    Right (BuildState _ phase _) -> case phase of
        Build.Starting -> Console.putStrLn "Starting..."
        Build.Building _ _ -> Console.putStrLn "Building..."
        Build.PostBuilding _ postBuild -> txtEvalComments postBuild
        Build.Finished _ postBuild -> txtEvalComments postBuild
        Build.Failed err -> do
            Console.putTextLn $ "Error: " <> err
            exitFailure
  where
    txtEvalComments postBuild =
        let evalutatingComments = Eval.phasePending postBuild.evalComments
        in  if
                | Tests.anyRunningTests postBuild.testSuites && evalutatingComments ->
                    Console.putStrLn "Testing and evaluating comments..."
                | Tests.anyRunningTests postBuild.testSuites -> Console.putStrLn "Testing..."
                | evalutatingComments -> Console.putStrLn "Evaluating comments..."
                | otherwise -> case postBuild.evalComments of
                    Eval.Looking -> Console.putStrLn "Looking for eval comments..."
                    Eval.NoneFound -> Console.putStrLn "No eval comments found"
                    Eval.Found comments
                        | Eval.anyRunningComments comments -> Console.putStrLn "Evaluating comments..."
                        | otherwise ->
                            Console.putTextLn
                                . T.intercalate "\n\n"
                                . toList
                                $ showEvalRun <$> comments.getComments
    showEvalRun run =
        T.intercalate
            "\n"
            [ showEvalRunInfo run
            , showEvalState run
            ]
    showEvalRunInfo evaluation =
        T.intercalate
            "\n"
            [ toText evaluation.file <> ":" <> show evaluation.comment.lineNumber
            , "Expression:"
            , evaluation.comment.expression
            ]
    showEvalState evaluation =
        case evaluation.state of
            Eval.Pending -> "Pending..."
            Eval.Completed output ->
                T.intercalate
                    "\n"
                    [ "Output:"
                    , output
                    ]


displayJsonOutput :: (Console :> es, Exit :> es) => Either Text BuildState -> Eff es ()
displayJsonOutput = \case
    Left err -> do
        putJson $ Eval.Failed err
        exitFailure
    Right (BuildState _ phase _) -> case phase of
        Build.Starting -> putJson Eval.Starting
        Build.Building _ _ -> putJson Eval.Building
        Build.Failed msg -> do
            putJson $ Eval.Failed msg
            exitFailure
        Build.PostBuilding _ postBuild -> jsonEvalComments postBuild
        Build.Finished _ postBuild -> jsonEvalComments postBuild
  where
    jsonEvalComments postBuild = case postBuild.evalComments of
        Eval.Looking -> putJson Eval.Evaluating
        Eval.NoneFound -> putJson $ Eval.NoEvalCommentsFound
        Eval.Found comments
            | Eval.anyRunningComments comments -> putJson Eval.Evaluating
            | otherwise -> putJson $ Eval.Done comments
    putJson = Console.putStrLn . toStrict . encode


displayPendingBuildStatus
    :: ( Console :> es
       , File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => Eff es ()
displayPendingBuildStatus = do
    SocketPath sockPath <- ask
    current <- queryStatus sockPath
    case current of
        Right BuildState {phase = Build.Starting} -> Console.putStrLn "Starting..."
        Right BuildState {phase = Build.Building _ _} -> Console.putStrLn "Building..."
        Right BuildState {phase = Build.Finished _ postBuild} ->
            displayPostBuildStatus postBuild
        Right BuildState {phase = Build.PostBuilding _ postBuild} ->
            displayPostBuildStatus postBuild
        Right BuildState {phase = Build.Failed _} -> pure ()
        Left _ -> pure ()
  where
    displayPostBuildStatus postBuild
        | Tests.anyRunningTests postBuild.testSuites && evaluatingComments =
            Console.putStrLn "Testing and evaluating comments..."
        | Tests.anyRunningTests postBuild.testSuites =
            Console.putStrLn "Testing..."
        | evaluatingComments =
            Console.putStrLn "Evaluating comments..."
        | otherwise = pure ()
      where
        evaluatingComments = Eval.phasePending postBuild.evalComments


awaitBuildStatus
    :: ( File :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => WaitMode -> Eff es (Either Text BuildState)
awaitBuildStatus wait = do
    SocketPath sockPath <- ask
    case wait of
        WaitForBuild -> queryStatusWait sockPath
        ShowCurrent -> queryStatus sockPath
