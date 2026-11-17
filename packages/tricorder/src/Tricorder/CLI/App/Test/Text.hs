module Tricorder.CLI.App.Test.Text
    ( showSuites
    , wrapTextShow
    , showBasePhase
    )
where

import Data.Aeson (toJSON)
import Tricorder.API.TestFilter (TestFilter)

import Data.Text qualified as T
import Tricorder.API.FieldMask.Projection qualified as FieldMask.Projection
import Tricorder.API.FieldMask.Schema qualified as FieldMask
import Tricorder.API.TestFilter qualified as TestFilter

import Tricorder.Build.Diagnostic (Diagnostic (..))
import Tricorder.CLI.App.Test.SuiteView (selectSuites)
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Phase qualified as Build (Phase)
import Tricorder.Build.Phase qualified as Build.Phase
import Tricorder.Build.PostBuild qualified as Build.PostBuild
import Tricorder.Build.Progress qualified as Build.Progress
import Tricorder.Build.Result qualified as Build.Result
import Tricorder.Build.Severity qualified as Build.Severity
import Tricorder.Build.State qualified as Build (State)
import Tricorder.Build.State qualified as Build.State
import Tricorder.Build.Test qualified as Test
import Tricorder.Session.TestTarget qualified as TestTarget


showSuites :: [TestTarget] -> TestFilter -> FieldMask.Schema -> Test.Suites -> Either Text Text
showSuites targets testFilter selection testSuites =
    case selectSuites targets testFilter testSuites of
        Left notFound ->
            Left $ "test suites not found: " <> T.intercalate ", " (TestTarget.render <$> toList notFound)
        Right []
            | Test.nullSuites testSuites -> Right "no test suites to run"
            | TestFilter.FailedOnly <- testFilter -> Right "no failed test suites"
        Right suites ->
            Right
                $ T.stripEnd
                $ FieldMask.Projection.renderYaml
                $ FieldMask.Projection.PArray
                $ FieldMask.Projection.project selection . toJSON <$> suites


wrapTextShow :: Either Text Build.State -> (Build.Phase -> Either Text Text) -> Either Text Text
wrapTextShow = \case
    Left err -> const $ Left $ "Error: " <> err
    Right build -> ($ build.phase)


showBasePhase :: (Test.Suites -> Either Text Text) -> Build.Phase -> Either Text Text
showBasePhase showTests = \case
    Build.Phase.Starting -> Right "Starting..."
    Build.Phase.Building _ progress ->
        Right
            $ mconcat
                [ "Building ("
                , show progress.compiled
                , "/"
                , show progress.total
                , ")..."
                ]
    Build.Phase.PostBuilding result postBuild
        | buildFailed result postBuild ->
            Left $ "build failed before tests ran"
        | Test.anyRunningTests postBuild.testSuites ->
            Right $ showTestProgress postBuild.testSuites
        | otherwise ->
            showTests postBuild.testSuites
    Build.Phase.Finished result postBuild
        | buildFailed result postBuild ->
            Left "build failed before tests ran"
        | otherwise ->
            showTests postBuild.testSuites
    Build.Phase.Failed err -> Left $ "Build failed: " <> err
  where
    buildFailed result postBuild =
        postBuild.testSuites == mempty
            && any (\d -> d.severity >= Build.Severity.Error) result.diagnostics


showTestProgress :: Test.Suites -> Text
showTestProgress suites =
    mconcat
        [ "Testing (test suites finished: "
        , show
            $ length
            $ filter
                ( \case
                    Test.SuiteCompleted _ -> True
                    Test.SuiteErrored _ -> True
                    _ -> False
                )
            $ toList suites.getSuites
        , "/"
        , show $ length $ suites.getSuites
        , ")"
        ]
