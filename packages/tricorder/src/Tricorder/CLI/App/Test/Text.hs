module Tricorder.CLI.App.Test.Text
    ( showSuites
    , wrapTextShow
    , showBasePhase
    )
where

import Data.Aeson (toJSON)
import Tricorder.CLI.Command.TestFilter (TestFilter)

import Data.Text qualified as T
import Tricorder.CLI.Command.TestFilter qualified as TestFilter

import Tricorder.Build
    ( BuildPhase (..)
    , BuildProgress (..)
    , BuildResult (..)
    , BuildState (..)
    , Diagnostic (..)
    , PostBuild (..)
    , Severity (..)
    )
import Tricorder.CLI.App.Test.SuiteView (selectSuites)
import Tricorder.CLI.FieldMask (Projected (..), Schema, project, renderYaml)
import Tricorder.Session.TestTarget (TestTarget)

import Tricorder.Build.Test qualified as Test
import Tricorder.Session.TestTarget qualified as TestTarget


showSuites :: [TestTarget] -> TestFilter -> Schema -> Test.Suites -> Either Text Text
showSuites targets testFilter selection testSuites =
    case selectSuites targets testFilter testSuites of
        Left notFound ->
            Left $ "test suites not found: " <> T.intercalate ", " (TestTarget.render <$> toList notFound)
        Right []
            | Test.nullSuites testSuites -> Right "no test suites to run"
            | TestFilter.FailedOnly <- testFilter -> Right "no failed test suites"
        Right suites ->
            Right $ T.stripEnd $ renderYaml $ PArray $ project selection . toJSON <$> suites


wrapTextShow :: Either Text BuildState -> (BuildPhase -> Either Text Text) -> Either Text Text
wrapTextShow = \case
    Left err -> const $ Left $ "Error: " <> err
    Right build -> ($ build.phase)


showBasePhase :: (Test.Suites -> Either Text Text) -> BuildPhase -> Either Text Text
showBasePhase showTests = \case
    Starting -> Right "Starting..."
    Building _ progress ->
        Right
            $ mconcat
                [ "Building ("
                , show progress.compiled
                , "/"
                , show progress.total
                , ")..."
                ]
    PostBuilding result postBuild
        | buildFailed result postBuild ->
            Left $ "build failed before tests ran"
        | Test.anyRunningTests postBuild.testSuites ->
            Right $ showTestProgress postBuild.testSuites
        | otherwise ->
            showTests postBuild.testSuites
    Finished result postBuild
        | buildFailed result postBuild ->
            Left $ "build failed before tests ran"
        | otherwise ->
            showTests postBuild.testSuites
    Failed err -> Left $ "Build failed: " <> err
  where
    buildFailed result postBuild = postBuild.testSuites == mempty && any (\d -> d.severity >= SError) result.diagnostics


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
