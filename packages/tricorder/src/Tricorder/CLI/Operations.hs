module Tricorder.CLI.Operations
    ( showLog
    , showSource
    , showStatus
    , showEvalComments
    , showDaemonInfo
    )
where

import Atelier.Effects.Clock (Clock, currentTimeZone)
import Atelier.Effects.Console (Console)
import Atelier.Effects.Exit (Exit)
import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem, doesFileExist, readFileLbs)
import Atelier.Effects.Input (Input, input)
import Atelier.Effects.Log (Log)
import Data.Aeson (ToJSON, encode)
import Data.Time.Format (defaultTimeLocale, formatTime)
import Data.Time.LocalTime (utcToLocalTime)
import Effectful.Provider (Provider_, provideWith_)
import Effectful.Reader.Static (Reader, ask)
import Tricorder.API.Command
    ( EvalCommentsOptions (..)
    , SourceOptions (..)
    , StatusOptions (..)
    , Verbosity (..)
    )
import Tricorder.API.IfBuildIsPending (IfBuildIsPending (..))
import Tricorder.API.OutputFormat (OutputFormat (..))
import Tricorder.SourceLookup.ReexportLimits (ReexportLimits (..), defaultReexportLimits)

import Atelier.Effects.Console qualified as Console
import Atelier.Effects.Exit qualified as Exit
import Data.ByteString.Lazy qualified as BSL
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Tricorder.API.IfBuildIsPending qualified as IfBuildIsPending

import Tricorder.Build (BuildState (..), Severity (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.Build.Test (Suites (..))
import Tricorder.CLI.Render (diagnosticLineIndexed, formatDuration, renderSourceResults)
import Tricorder.Daemon.DaemonInfo (DaemonInfo (..))
import Tricorder.Runtime.SocketPath (SocketPath (..))
import Tricorder.Session.CabalFile (CabalFile)
import Tricorder.Socket.Client (queryStatus, queryStatusWait)
import Tricorder.Socket.UnixSocket (UnixSocket)
import Tricorder.SourceLookup (lookupModuleSource, projectSourceDirs)
import Tricorder.SourceLookup.GhcPkg (GhcPkg)
import Tricorder.SourceLookup.Hackage (Hackage)
import Tricorder.SourceLookup.PackageStore (PackageStore)
import Tricorder.TestOutput (stripGhciNoise)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.Build.Test qualified as Tests
import Tricorder.Session.Stage.Build.Session qualified as Build (Session)
import Tricorder.Session.Target qualified as Target
import Tricorder.Session.TestTarget qualified as TestTarget


-- | Print a build-command failure message and exit non-zero.
reportBuildFailed :: (Console :> es, Exit :> es) => Text -> Eff es a
reportBuildFailed msg = do
    Console.putTextLn "Build command failed:"
    Console.putTextLn msg
    Exit.failure


showStatus
    :: ( Clock :> es
       , Console :> es
       , Exit :> es
       , File :> es
       , Provider_ Console Console.Output :> es
       , Reader SocketPath :> es
       , UnixSocket :> es
       )
    => StatusOptions -> Eff es ()
showStatus opts = do
    when (opts.wait == WaitForBuild && opts.format == TextOutput) do
        provideWith_ @Console Console.Stderr displayPendingBuildStatus
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
                    when (buildHasErrors result || Test.hasFailedTests postBuild.testSuites) Exit.failure

    printTestRun verbosity tgt tr = do
        Console.putTextLn $ case tr of
            Test.SuiteRunning Nothing -> t <> "  running..."
            Test.SuiteRunning (Just p) -> t <> "  running... (" <> show p.compiled <> "/" <> show p.total <> ")"
            Test.SuiteErrored e -> t <> "  error: " <> errorText e.message
            Test.SuiteCompleted c -> t <> "  " <> completionSummary c
        when (verbosity == Verbose) $ case tr of
            Test.SuiteCompleted c ->
                mapM_ (Console.putTextLn . ("  " <>)) (stripGhciNoise (T.lines c.output))
            _ -> pure ()
      where
        t = TestTarget.render tgt
        errorText message = case (verbosity, lines message) of
            (Concise, firstLine : _ : _) -> firstLine <> " (use --verbose to see the full message)"
            _ -> message

    buildHasErrors r = any ((== SError) . (.severity)) r.diagnostics
    buildSummary tz r =
        let errs = length $ filter ((== SError) . (.severity)) r.diagnostics
            warns = length $ filter ((== SWarning) . (.severity)) r.diagnostics
            ts = toText $ "— " <> formatTime defaultTimeLocale "%H:%M:%S" (utcToLocalTime tz r.completedAt)
            stats =
                toText $ "(" <> show r.moduleCount <> " modules, " <> formatDuration r.duration.getDuration <> ")"
        in  if null r.diagnostics
                then
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
            in  if failedCount == 0
                    then
                        "passed (" <> show total <> ")"
                    else
                        show failedCount <> "/" <> show total <> " failed"
    isFailedCase (Test.Case _ (Test.Failed _)) = True
    isFailedCase _ = False


showLog
    :: ( Console :> es
       , FileSystem :> es
       )
    => FilePath -> Eff es ()
showLog path = do
    exists <- doesFileExist path
    if not exists
        then Console.putTextLn $ "Log file does not exist yet: " <> toText path
        else readFileLbs path >>= Console.putStr . BSL.toStrict


showSource
    :: ( Console :> es
       , FileSystem :> es
       , GhcPkg :> es
       , Hackage :> es
       , Input Build.Session :> es
       , Input [CabalFile] :> es
       , Log :> es
       , PackageStore :> es
       )
    => SourceOptions
    -> Eff es ()
showSource opts = do
    dirs <- projectSourceDirs <$> input
    results <- mapM (lookupModuleSource dirs limits) opts.queries
    renderSourceResults results
  where
    limits =
        ReexportLimits
            { maxDepth = fromMaybe defaultReexportLimits.maxDepth opts.maxDepth
            , maxModules = fromMaybe defaultReexportLimits.maxModules opts.maxModules
            }


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


showDaemonInfo :: (Console :> es) => OutputFormat -> DaemonInfo -> Eff es ()
showDaemonInfo format daemonInfo = case format of
    TextOutput -> text
    JsonOutput -> json
  where
    text = do
        Console.putTextLn "Targets:"
        for_ daemonInfo.targets \target ->
            Console.putTextLn $ "- " <> Target.render target
        Console.putTextLn "Watch directories:"
        for_ daemonInfo.watchDirs \dir ->
            Console.putTextLn $ "- " <> toText dir
        Console.putTextLn $ "Socket file path: " <> toText daemonInfo.sockPath
        Console.putTextLn $ "Log file path: " <> toText daemonInfo.logFile
    json = putJson daemonInfo


displayTextOutput
    :: ( Console :> es
       , Exit :> es
       )
    => Either Text BuildState -> Eff es ()
displayTextOutput = \case
    Left err -> do
        Console.putTextLn $ "Error: " <> err
        Exit.failure
    Right (BuildState phase _) -> case phase of
        Build.Starting -> Console.putStrLn "Starting..."
        Build.Building _ _ -> Console.putStrLn "Building..."
        Build.PostBuilding _ postBuild -> txtEvalComments postBuild
        Build.Finished _ postBuild -> txtEvalComments postBuild
        Build.Failed err -> do
            Console.putTextLn $ "Error: " <> err
            Exit.failure
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
        Exit.failure
    Right (BuildState phase _) -> case phase of
        Build.Starting -> putJson Eval.Starting
        Build.Building _ _ -> putJson Eval.Building
        Build.Failed msg -> do
            putJson $ Eval.Failed msg
            Exit.failure
        Build.PostBuilding _ postBuild -> jsonEvalComments postBuild
        Build.Finished _ postBuild -> jsonEvalComments postBuild
  where
    jsonEvalComments postBuild = case postBuild.evalComments of
        Eval.Looking -> putJson Eval.Evaluating
        Eval.NoneFound -> putJson $ Eval.NoEvalCommentsFound
        Eval.Found comments
            | Eval.anyRunningComments comments -> putJson Eval.Evaluating
            | otherwise -> putJson $ Eval.Done comments


putJson :: (Console :> es, ToJSON a) => a -> Eff es ()
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
        Right BuildState {phase = Build.Finished _ postBuild} -> displayPostBuildStatus postBuild
        Right BuildState {phase = Build.PostBuilding _ postBuild} -> displayPostBuildStatus postBuild
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
    => IfBuildIsPending -> Eff es (Either Text BuildState)
awaitBuildStatus wait = do
    SocketPath sockPath <- ask
    case wait of
        IfBuildIsPending.WaitForBuild -> queryStatusWait sockPath
        IfBuildIsPending.UseCurrent -> queryStatus sockPath
