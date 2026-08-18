module Tricorder.CLI.UI.View (mkAttrMap, view) where

import Atelier.Effects.Clock (TimeZone)
import Brick
    ( AttrMap
    , AttrName
    , VScrollBarOrientation (..)
    , ViewportType (..)
    , Widget
    , attrMap
    , attrName
    , vBox
    , viewport
    )
import Brick.Keybindings (KeyConfig, KeyHandler (..), keyDispatcherToList, ppBinding)
import Brick.Widgets.Core
    ( Padding (..)
    , emptyWidget
    , hBox
    , padLeft
    , txt
    , txtWrap
    , withClickableVScrollBars
    , withDefAttr
    , withVScrollBarHandles
    , withVScrollBars
    )
import Data.Time (UTCTime, defaultTimeLocale, formatTime, utcToLocalTime)
import System.FilePath (isAbsolute)

import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Graphics.Vty.Attributes qualified as Attr
import Graphics.Vty.Attributes.Color qualified as Color

import Tricorder.Build (BuildPhase, BuildResult, BuildState, Diagnostic, Severity (..))
import Tricorder.Build.Duration (Duration (..))
import Tricorder.CLI.UI.Keys (KeyEvent, keybindForRoute, viewKeybindings)
import Tricorder.CLI.UI.Misc (emphasis, err, hBoxSpaced, ok, subtle, vBoxSpaced, warn)
import Tricorder.CLI.UI.Route (Route)
import Tricorder.CLI.UI.State
    ( Processed (..)
    , State (..)
    , TestFilter (..)
    , Viewports (..)
    , currentRoute
    )
import Tricorder.Daemon.DaemonInfo (DaemonInfo (..))
import Tricorder.Session.Target (Target, renderTarget)
import Tricorder.Session.TestTarget (TestTarget, renderTestTarget)
import Tricorder.TestOutput (stripGhciNoise)

import Tricorder.Build qualified as Build
import Tricorder.Build.EvalComment qualified as Eval
import Tricorder.Build.Test qualified as Test
import Tricorder.CLI.UI.Keys qualified as Keys
import Tricorder.CLI.UI.Route qualified as Route
import Tricorder.Version qualified as Version


mkAttrMap :: State -> AttrMap
mkAttrMap =
    const
        ( attrMap
            Attr.defAttr
            [ (attrName "ok", Attr.withForeColor Attr.defAttr Color.green)
            , (attrName "warning", Attr.withForeColor Attr.defAttr Color.yellow)
            , (attrName "error", Attr.withForeColor Attr.defAttr Color.red)
            , (attrName "emphasis", Attr.withStyle Attr.defAttr Attr.bold)
            , (attrName "subtle", Attr.withForeColor Attr.defAttr $ Color.rgbColor @Int 148 148 148)
            ]
        )


view :: KeyConfig KeyEvent -> State -> [Widget Viewports]
view kc ws =
    [ vBoxSpaced
        1
        [ vBox
            [ viewAppHeader ws
            , viewTabs kc ws
            ]
        , case currentRoute ws of
            Route.Help ->
                viewHelp kc
            Route.DaemonInfo ->
                viewDaemonInfo ws
            Route.Tests ->
                viewTests ws
            Route.Main ->
                viewMain ws
            Route.Evals ->
                viewEvals ws
        ]
    ]


viewTabs :: KeyConfig KeyEvent -> State -> Widget n
viewTabs kc ws =
    hBoxSpaced 1
        $ intersperse (subtle $ txt "-")
        $ viewRouteTab kc ws <$> universe @Route


viewRouteTab :: KeyConfig KeyEvent -> State -> Route -> Widget n
viewRouteTab kc ws route =
    style $ txt $ Route.name route <> keyBind
  where
    style = if route == currentRoute ws then id else subtle
    showBinding = (" " <>) . ("[" <>) . (<> "]") . ppBinding
    keyBind = maybe "" showBinding $ keybindForRoute kc route


viewDaemonInfo :: State -> Widget Viewports
viewDaemonInfo ws =
    withBuildState ws (viewExpandedDaemonInfo . (.daemonInfo))


viewTests :: State -> Widget Viewports
viewTests ws =
    withBuildState ws (viewTestResultsPanel ws)


viewEvals :: State -> Widget Viewports
viewEvals ws =
    withBuildState ws $ viewEvalCommentsPanel ws


viewMain :: State -> Widget Viewports
viewMain ws = withBuildState ws (viewDefaultPanel ws.timeZone)


viewHelp :: KeyConfig KeyEvent -> Widget n
viewHelp kc = viewKeybindings kc handlers
  where
    -- The dispatcher is built only to enumerate handler descriptions for the help
    -- view, so the restart action is a no-op here.
    handlers = (.khHandler) . snd <$> keyDispatcherToList (Keys.dispatcher (pure ()) kc)


withBuildState :: State -> (BuildState -> Widget Viewports) -> Widget Viewports
withBuildState ws render =
    case ws.buildState of
        Waiting ->
            txt "Waiting for build..."
        Failure reason ->
            txt $ "Error when contacting daemon: " <> reason
        Success bs ->
            render bs


viewAppHeader :: State -> Widget n
viewAppHeader ws =
    ok
        $ emphasis
        $ txt
        $ "Tricorder"
            <> maybe
                ""
                (" - " <>)
                (viewHeading ws)


viewHeading :: State -> Maybe Text
viewHeading ws = case currentRoute ws of
    Route.Tests -> case ws.testFilter of
        TestFilterAll -> Just "Tests"
        TestFilterFailedOnly -> Just "Tests - Failed only"
    Route.Help -> Just "Help"
    Route.DaemonInfo -> Just "Daemon info"
    Route.Main -> Nothing
    Route.Evals -> Just "Eval comments"


viewDefaultPanel :: TimeZone -> BuildState -> Widget Viewports
viewDefaultPanel tz bs = viewBuildPhase tz bs.phase


viewTestResultsPanel :: State -> BuildState -> Widget Viewports
viewTestResultsPanel ws bs =
    vBoxSpaced
        1
        [ viewBuildPhaseLine ws.timeZone bs.phase
        , viewTestPanel ws.testFilter (phaseTestRuns bs.phase)
        ]


viewEvalCommentsPanel :: State -> BuildState -> Widget Viewports
viewEvalCommentsPanel ws bs =
    vBoxSpaced
        1
        [ viewBuildPhaseLine ws.timeZone bs.phase
        , case bs.phase of
            Build.Finished _ postBuild -> viewEvalComments postBuild.evalComments
            Build.PostBuilding _ postBuild -> viewEvalComments postBuild.evalComments
            _ -> txt "Waiting for build..."
        ]


viewEvalComments :: Eval.Phase -> Widget Viewports
viewEvalComments Eval.Looking = txt "Looking for eval comments..."
viewEvalComments Eval.NoneFound = txt "No eval comments detected"
viewEvalComments (Eval.Found (Eval.Comments results)) =
    vScrollViewport EvalResultsViewport
        $ vBoxSpaced 1
        $ toList
        $ viewEvaluation <$> results


viewEvaluation :: Eval.Evaluation -> Widget n
viewEvaluation evaluation =
    vBox
        $ [ hBoxSpaced
                1
                [ subtle $ txt "File:"
                , txt $ toText evaluation.file <> ":" <> show evaluation.comment.lineNumber
                ]
          , subtle $ txt "Expression:"
          , txt evaluation.comment.expression
          ]
            <> case evaluation.state of
                Eval.Completed output ->
                    [ subtle $ txt "Result:"
                    , vBox $ txt <$> T.lines output
                    ]
                Eval.Pending ->
                    [ subtle $ txt "Running..."
                    ]


viewExpandedDaemonInfo :: DaemonInfo -> Widget n
viewExpandedDaemonInfo di =
    vBox
        [ viewVersion
        , viewTargets di.targets
        , viewWatchDirs di.watchDirs
        , viewSockPath di.sockPath
        , viewLogFile di.logFile
        ]


viewVersion :: Widget n
viewVersion =
    hBoxSpaced
        1
        [ emphasis $ txt "Client version:"
        , txt Version.gitHash
        ]


viewTargets :: [Target] -> Widget n
viewTargets targets =
    hBoxSpaced
        1
        [ emphasis $ txt "Targets:"
        , if null targets then
            txt "(all)"
          else
            vBox $ (map (txt . renderTarget) targets)
        ]


viewLogFile :: FilePath -> Widget n
viewLogFile p = hBoxSpaced 1 [emphasis $ txt "Log:", txt $ toText p]


viewSockPath :: FilePath -> Widget n
viewSockPath sockPath =
    hBoxSpaced 1 [emphasis $ txt "Socket:", txt $ toText sockPath]


viewWatchDirs :: [FilePath] -> Widget n
viewWatchDirs watchDirs =
    vBox
        [ emphasis $ txt "Watching:"
        , padLeft (Pad 2)
            $ vBox
            $ viewWatchDir <$> watchDirs
        ]


viewWatchDir :: FilePath -> Widget n
viewWatchDir dir = hBox [txt "- ", txt $ toText displayDir]
  where
    displayDir
        | isAbsolute dir = dir
        | dir == "." = "./"
        | otherwise = "./" <> dir


viewBuildPhase :: TimeZone -> BuildPhase -> Widget Viewports
viewBuildPhase tz = \case
    Build.Starting ->
        warn $ txt "Starting..."
    Build.Building testTargets phase ->
        vBoxSpaced
            1
            [ warn $ txt $ "Building (" <> show phase.compiled <> "/" <> show phase.total <> ")..."
            , viewPendingTestTargets testTargets
            ]
    Build.PostBuilding result postBuild ->
        vBoxSpaced
            1
            [ viewBuildResult tz result
            , viewTestRuns postBuild.testSuites
            ]
    Build.Finished result postBuild ->
        vBoxSpaced
            1
            [ viewBuildResult tz result
            , viewTestRuns postBuild.testSuites
            ]
    Build.Failed msg ->
        viewBuildFailed msg


viewPendingTestTargets :: [TestTarget] -> Widget n
viewPendingTestTargets =
    vBox
        . ([txt "Pending test suites:"] <>)
        . fmap (subtle . txt . renderTestTarget)


viewBuildFailed :: Text -> Widget Viewports
viewBuildFailed msg =
    vBox
        [ err $ txt "Build command failed"
        , vScrollViewport DiagnosticViewport (vBox $ txtWrap <$> T.lines msg)
        ]


-- | A vertically-scrollable viewport with clickable scrollbars on the right.
vScrollViewport :: (Ord vp, Show vp) => vp -> Widget vp -> Widget vp
vScrollViewport vp =
    withClickableVScrollBars (\_ _ -> vp)
        . withVScrollBarHandles
        . withVScrollBars OnRight
        . viewport vp Vertical


viewBuildResult :: TimeZone -> BuildResult -> Widget Viewports
viewBuildResult tz result
    | null result.diagnostics =
        hBoxSpaced
            1
            [ ok $ txt "All good."
            , viewBuildSummary result.moduleCount result.duration
            , viewTimestamp tz result.completedAt
            ]
    | otherwise =
        let msgs = result.diagnostics
            errCount = length $ filter (\m -> m.severity == SError) msgs
            warnCount = length $ filter (\m -> m.severity == SWarning) msgs
            header =
                if errCount > 0 then
                    err $ txt $ show errCount <> " error(s), " <> show warnCount <> " warning(s)"
                else
                    warn $ txt $ show warnCount <> " warning(s)"
        in  vBoxSpaced
                1
                [ hBoxSpaced
                    1
                    [ header
                    , viewDuration result.duration
                    , viewTimestamp tz result.completedAt
                    ]
                , vScrollViewport DiagnosticViewport $ vBox $ viewDiagnostic <$> msgs
                ]


viewDiagnostic :: Diagnostic -> Widget n
viewDiagnostic m =
    vBox
        [ hBoxSpaced
            1
            [ severityLabel
            , txt $ toText loc
            ]
        , txtWrap m.text
        ]
  where
    loc = m.file <> ":" <> show m.line <> ":" <> show m.col
    severityLabel = withDefAttr (severityToAttrName m.severity) $ txt $ case m.severity of
        SError -> "error:"
        SWarning -> "warning:"


severityToAttrName :: Severity -> AttrName
severityToAttrName SError = attrName "error"
severityToAttrName SWarning = attrName "warning"


viewDuration :: Duration -> Widget n
viewDuration d = txt $ "(" <> formatDuration d <> ")"


viewTestRuns :: Test.Suites -> Widget n
viewTestRuns suites = vBox $ uncurry viewTestRun <$> Map.toList suites.getSuites


viewTestRun :: TestTarget -> Test.Suite -> Widget n
viewTestRun tgt run =
    hBox $ [txt $ renderTestTarget tgt, txt "  "] <> status
  where
    status = case run of
        Test.SuiteRunning Nothing ->
            [ warn $ txt "running..."
            ]
        Test.SuiteRunning (Just p) ->
            [ warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"
            ]
        Test.SuiteErrored e ->
            [ err $ txt "error: "
            , txt e.message
            ]
        Test.SuiteCompleted c ->
            [ viewCompletionStatus c
            ]


viewCompletionStatus :: Test.SuiteCompletion -> Widget n
viewCompletionStatus c = case c.duration of
    Nothing -> statusWidget
    Just d -> hBoxSpaced 1 [statusWidget, subtle $ viewDuration d]
  where
    statusWidget
        | null c.testCases = if c.passed then ok (txt "passed") else err (txt "failed")
        | otherwise =
            let total = length c.testCases
                failed = length $ filter Test.caseFailed c.testCases
            in  if failed == 0 then
                    ok $ txt $ "passed (" <> show total <> ")"
                else
                    err $ txt $ show failed <> "/" <> show total <> " failed"


viewTimestamp :: TimeZone -> UTCTime -> Widget n
viewTimestamp tz t = txt $ "— " <> toText (formatTime defaultTimeLocale "%H:%M:%S" $ utcToLocalTime tz t)


viewBuildSummary :: Int -> Duration -> Widget n
viewBuildSummary moduleCount duration =
    txt $ "(" <> show moduleCount <> " modules, " <> formatDuration duration <> ")"


formatDuration :: Duration -> Text
formatDuration (Duration d) =
    let ms = toInteger d
    in  if ms < 1000 then
            show ms <> "ms"
        else
            show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


-- | Single-line build status with no scrollable diagnostics list, used as a
-- compact header when a secondary panel (test results, daemon info) is open.
viewBuildPhaseLine :: TimeZone -> BuildPhase -> Widget n
viewBuildPhaseLine tz = \case
    Build.Starting ->
        warn $ txt "Starting..."
    Build.Building _ phase ->
        warn $ txt $ "Building (" <> show phase.compiled <> "/" <> show phase.total <> ")..."
    Build.PostBuilding result _ ->
        viewBuildResultLine tz result
    Build.Finished result _ ->
        viewBuildResultLine tz result
    Build.Failed _ ->
        err $ txt "Build command failed"


viewBuildResultLine :: TimeZone -> BuildResult -> Widget n
viewBuildResultLine tz result
    | null result.diagnostics =
        hBoxSpaced
            1
            [ ok $ txt "All good."
            , viewBuildSummary result.moduleCount result.duration
            , viewTimestamp tz result.completedAt
            ]
    | otherwise =
        let errCount = length $ filter (\m -> m.severity == SError) result.diagnostics
            warnCount = length $ filter (\m -> m.severity == SWarning) result.diagnostics
            header =
                if errCount > 0 then
                    err $ txt $ show errCount <> " error(s), " <> show warnCount <> " warning(s)"
                else
                    warn $ txt $ show warnCount <> " warning(s)"
        in  hBoxSpaced 1 [header, viewDuration result.duration, viewTimestamp tz result.completedAt]


phaseTestRuns :: BuildPhase -> Test.Suites
phaseTestRuns (Build.PostBuilding _ postBuild) = postBuild.testSuites
phaseTestRuns (Build.Finished _ postBuild) = postBuild.testSuites
phaseTestRuns _ = Test.Suites mempty


viewTestPanel :: TestFilter -> Test.Suites -> Widget Viewports
viewTestPanel tvf suites
    | Test.nullSuites suites = subtle $ txt "No test results."
    | otherwise = scrollableRuns tvf suites


scrollableRuns :: TestFilter -> Test.Suites -> Widget Viewports
scrollableRuns tvf suites =
    vScrollViewport TestViewport
        $ vBox
        $ uncurry (viewTestRunDetail tvf) <$> Map.toList suites.getSuites


viewTestRunDetail :: TestFilter -> TestTarget -> Test.Suite -> Widget n
viewTestRunDetail tvf tgt = \case
    Test.SuiteRunning Nothing ->
        hBox
            [ txt t
            , txt "  "
            , warn $ txt "running..."
            ]
    Test.SuiteRunning (Just p) ->
        hBox
            [ txt t
            , txt "  "
            , warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"
            ]
    Test.SuiteErrored e ->
        hBoxSpaced
            1
            [ txt t
            , err $ txt "error:"
            , txt e.message
            ]
    Test.SuiteCompleted c ->
        vBox
            [ hBox [txt $ t <> "  ", viewCompletionStatus c]
            , viewTestOutput tvf c
            ]
  where
    t = renderTestTarget tgt


viewTestOutput :: TestFilter -> Test.SuiteCompletion -> Widget n
viewTestOutput TestFilterAll c =
    padLeft (Pad 2) $ vBox $ txt <$> stripGhciNoise (T.lines c.output)
viewTestOutput TestFilterFailedOnly c
    | not (any Test.caseFailed c.testCases) && c.passed = emptyWidget
    | null c.testCases =
        padLeft (Pad 2)
            $ vBox
                [ subtle $ txt "(unrecognised test runner — showing full output)"
                , vBox $ txt <$> stripGhciNoise (T.lines c.output)
                ]
    | otherwise =
        padLeft (Pad 2) $ vBox $ viewFailedCase <$> filter Test.caseFailed c.testCases


viewFailedCase :: Test.Case -> Widget n
viewFailedCase tc =
    vBox
        [ err $ txt tc.description
        , case tc.outcome of
            Test.Failed details -> padLeft (Pad 2) $ txtWrap details
            Test.Passed -> emptyWidget
        ]
