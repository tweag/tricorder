module Tricorder.UI.View (mkAttrMap, view) where

import Atelier.Effects.Clock (TimeZone)
import Atelier.Time (Millisecond, toMicroseconds)
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

import Data.Text qualified as T
import Graphics.Vty.Attributes qualified as Attr
import Graphics.Vty.Attributes.Color qualified as Color

import Tricorder.BuildState
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , Diagnostic (..)
    , EvalRun (..)
    , EvalState (..)
    , PostBuild (..)
    , Severity (..)
    , TestCase (..)
    , TestCaseOutcome (..)
    , TestRun (..)
    , TestRunCompletion (..)
    , TestRunError (..)
    )
import Tricorder.Session (Target, renderTarget)
import Tricorder.TestOutput (stripGhciNoise)
import Tricorder.UI.Keys (KeyEvent, keybindForRoute, viewKeybindings)
import Tricorder.UI.Misc (emphasis, err, hBoxSpaced, ok, subtle, vBoxSpaced, warn)
import Tricorder.UI.Route (Route)
import Tricorder.UI.State (Processed (..), State (..), TestFilter (..), Viewports (..), currentRoute)

import Tricorder.UI.Keys qualified as Keys
import Tricorder.UI.Route qualified as Route
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
            BuildComplete build -> viewEvalRuns build.result.evalRuns
            _ -> txt "Waiting for build..."
        ]


viewEvalRuns :: [EvalRun] -> Widget Viewports
viewEvalRuns [] = txt "No eval comments detected"
viewEvalRuns results = vScrollViewport EvalResultsViewport $ vBoxSpaced 1 $ viewEvalRun <$> results


viewEvalRun :: EvalRun -> Widget n
viewEvalRun run =
    vBox
        $ [ hBoxSpaced
                1
                [ subtle $ txt "File:"
                , txt $ toText run.file
                , txt $ "(line " <> show run.line <> ")"
                ]
          , subtle $ txt "Expression:"
          , txt run.expression
          ]
            <> case run.state of
                EvalCompleted output ->
                    [ subtle $ txt "Result:"
                    , vBox $ txt <$> T.lines output
                    ]
                EvalPending ->
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
        , viewMetrics di.metricsPort
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
            txtWrap (T.intercalate " " (map renderTarget targets))
        ]


viewMetrics :: Maybe Int -> Widget n
viewMetrics Nothing =
    hBoxSpaced
        1
        [ emphasis $ txt "Metrics:"
        , warn $ txt "disabled"
        ]
viewMetrics (Just port) =
    hBoxSpaced
        1
        [ emphasis $ txt "Metrics:"
        , ok $ txt $ "http://localhost:" <> show port <> "/metrics"
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
    Building Nothing -> warn $ txt "Building..."
    Building (Just p) -> warn $ txt $ "Building (" <> show p.compiled <> "/" <> show p.total <> ")..."
    Restarting -> warn $ txt "Restarting..."
    BuildComplete build -> vBoxSpaced 1 [viewBuildResult tz build.result, viewTestRuns build.result.testRuns]
    BuildFailed msg -> viewBuildFailed msg


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


viewDuration :: Millisecond -> Widget n
viewDuration d = txt $ "(" <> formatDuration d <> ")"


viewTestRuns :: [TestRun] -> Widget n
viewTestRuns [] = emptyWidget
viewTestRuns runs = vBox $ viewTestRun <$> runs


viewTestRun :: TestRun -> Widget n
viewTestRun (TestRunning t Nothing) = hBox [txt t, txt "  ", warn $ txt "running..."]
viewTestRun (TestRunning t (Just p)) =
    hBox [txt t, txt "  ", warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"]
viewTestRun (TestRunErrored e) = hBox [txt e.target, txt "  ", err $ txt "error: ", txt e.message]
viewTestRun (TestRunCompleted c) = hBox [txt c.target, txt "  ", viewCompletionStatus c]


viewCompletionStatus :: TestRunCompletion -> Widget n
viewCompletionStatus c = case c.duration of
    Nothing -> statusWidget
    Just d -> hBoxSpaced 1 [statusWidget, subtle $ viewDuration d]
  where
    statusWidget
        | null c.testCases = if c.passed then ok (txt "passed") else err (txt "failed")
        | otherwise =
            let total = length c.testCases
                failed = length $ filter isCaseFailed c.testCases
            in  if failed == 0 then
                    ok $ txt $ "passed (" <> show total <> ")"
                else
                    err $ txt $ show failed <> "/" <> show total <> " failed"


viewTimestamp :: TimeZone -> UTCTime -> Widget n
viewTimestamp tz t = txt $ "— " <> toText (formatTime defaultTimeLocale "%H:%M:%S" $ utcToLocalTime tz t)


viewBuildSummary :: Int -> Millisecond -> Widget n
viewBuildSummary moduleCount duration =
    txt $ "(" <> show moduleCount <> " modules, " <> formatDuration duration <> ")"


formatDuration :: Millisecond -> Text
formatDuration d =
    let ms = toMicroseconds d `div` 1000
    in  if ms < 1000 then
            show ms <> "ms"
        else
            show (ms `div` 1000) <> "." <> show ((ms `mod` 1000) `div` 100) <> "s"


-- | Single-line build status with no scrollable diagnostics list, used as a
-- compact header when a secondary panel (test results, daemon info) is open.
viewBuildPhaseLine :: TimeZone -> BuildPhase -> Widget n
viewBuildPhaseLine tz = \case
    Building Nothing -> warn $ txt "Building..."
    Building (Just p) -> warn $ txt $ "Building (" <> show p.compiled <> "/" <> show p.total <> ")..."
    Restarting -> warn $ txt "Restarting..."
    BuildComplete build -> viewBuildResultLine tz build.result
    BuildFailed _ -> err $ txt "Build command failed"


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


phaseTestRuns :: BuildPhase -> [TestRun]
phaseTestRuns (BuildComplete r) = r.result.testRuns
phaseTestRuns _ = []


viewTestPanel :: TestFilter -> [TestRun] -> Widget Viewports
viewTestPanel _ [] = subtle $ txt "No test results."
viewTestPanel tvf runs = scrollableRuns tvf runs


scrollableRuns :: TestFilter -> [TestRun] -> Widget Viewports
scrollableRuns tvf runs =
    vScrollViewport TestViewport $ vBox $ viewTestRunDetail tvf <$> runs


viewTestRunDetail :: TestFilter -> TestRun -> Widget n
viewTestRunDetail _ (TestRunning t Nothing) = hBox [txt t, txt "  ", warn $ txt "running..."]
viewTestRunDetail _ (TestRunning t (Just p)) =
    hBox [txt t, txt "  ", warn $ txt $ "running... (" <> show p.compiled <> "/" <> show p.total <> ")"]
viewTestRunDetail _ (TestRunErrored e) = hBoxSpaced 1 [txt e.target, err $ txt "error:", txt e.message]
viewTestRunDetail tvf (TestRunCompleted c) =
    vBox
        [ hBox [txt c.target, txt "  ", viewCompletionStatus c]
        , viewTestOutput tvf c
        ]


viewTestOutput :: TestFilter -> TestRunCompletion -> Widget n
viewTestOutput TestFilterAll c =
    padLeft (Pad 2) $ vBox $ txt <$> stripGhciNoise (T.lines c.output)
viewTestOutput TestFilterFailedOnly c
    | not (any isCaseFailed c.testCases) && c.passed = emptyWidget
    | null c.testCases =
        padLeft (Pad 2)
            $ vBox
                [ subtle $ txt "(unrecognised test runner — showing full output)"
                , vBox $ txt <$> stripGhciNoise (T.lines c.output)
                ]
    | otherwise =
        padLeft (Pad 2) $ vBox $ viewFailedCase <$> filter isCaseFailed c.testCases


isCaseFailed :: TestCase -> Bool
isCaseFailed (TestCase _ (TestCaseFailed _)) = True
isCaseFailed _ = False


viewFailedCase :: TestCase -> Widget n
viewFailedCase tc =
    vBox
        [ err $ txt tc.description
        , case tc.outcome of
            TestCaseFailed details -> padLeft (Pad 2) $ txtWrap details
            TestCasePassed -> emptyWidget
        ]
