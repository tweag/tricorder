module Unit.Tricorder.Effects.PostBuildStoreSpec (spec_PostBuildStore) where

import Data.Time (UTCTime (..), fromGregorian)
import Effectful (runPureEff)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.State.Static.Shared (State, execState, modify)
import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.BuildState
    ( BuildId (..)
    , BuildPhase (..)
    , BuildResult (..)
    , BuildState (..)
    , DaemonInfo (..)
    , PostBuild (..)
    )
import Tricorder.Effects.BuildStore (BuildStore (..))
import Tricorder.Effects.PostBuildStore (runPostBuildStore)

import Tricorder.BuildState.EvalComments qualified as Eval
import Tricorder.Effects.PostBuildStore qualified as PostBuild


spec_PostBuildStore :: Spec
spec_PostBuildStore = do
    describe "runPostBuildStore" testRunPostBuildStore


testRunPostBuildStore :: Spec
testRunPostBuildStore = do
    describe "with BuildComplete build phase" do
        let runTest = runTest' buildingBuildState
        describe "modifyPostBuild" do
            it "updates the build result" do
                let actualState = runTest $ PostBuild.modifyPostBuild \postBuild ->
                        postBuild
                            { evalComments =
                                Eval.Comments
                                    $ [ Eval.Evaluation
                                            { file = "foo"
                                            , comment = Eval.Comment 0 "expr"
                                            , state = Eval.Pending
                                            }
                                      ]
                            }
                actualState
                    `shouldBe` ( doneBuildState
                                    { phase =
                                        BuildComplete
                                            emptyBuildResult
                                            PostBuild
                                                { testSuites = mempty
                                                , evalComments =
                                                    Eval.Comments
                                                        $ [ Eval.Evaluation
                                                                { file = "foo"
                                                                , comment = Eval.Comment 0 "expr"
                                                                , state = Eval.Pending
                                                                }
                                                          ]
                                                }
                                    }
                               )

    describe "with non-Done build phase" do
        let runTest = runTest' buildingBuildState
        describe "updateBuildResult" do
            it "sets the build phase to Done and updates the build result from the initial build result" do
                let actualState = runTest $ PostBuild.modifyPostBuild \postBuild ->
                        postBuild
                            { evalComments =
                                Eval.Comments
                                    $ [ Eval.Evaluation
                                            { file = "foo"
                                            , comment = Eval.Comment 0 "expr"
                                            , state = Eval.Pending
                                            }
                                      ]
                            }
                actualState
                    `shouldBe` ( doneBuildState
                                    { phase =
                                        BuildComplete
                                            emptyBuildResult
                                            PostBuild
                                                { testSuites = mempty
                                                , evalComments =
                                                    Eval.Comments
                                                        $ [ Eval.Evaluation
                                                                { file = "foo"
                                                                , comment = Eval.Comment 0 "expr"
                                                                , state = Eval.Pending
                                                                }
                                                          ]
                                                }
                                    }
                               )
  where
    runTest' initialBuildState =
        runPureEff
            . execState initialBuildState
            . runBuildStoreSimple
            . runPostBuildStore emptyBuildResult
    runBuildStoreSimple :: (State BuildState :> es) => Eff (BuildStore : es) a -> Eff es a
    runBuildStoreSimple = interpret_ \case
        ModifyPhase f -> modify \s -> s {phase = f s}
        _ -> error "runBuildStoreSimple: Unsupported operation"


buildingBuildState :: BuildState
buildingBuildState =
    BuildState
        { buildId = BuildId 1
        , phase = Building Nothing
        , daemonInfo = emptyDaemonInfo
        }


doneBuildState :: BuildState
doneBuildState =
    BuildState
        { buildId = BuildId 1
        , phase = donePhase
        , daemonInfo = emptyDaemonInfo
        }


donePhase :: BuildPhase
donePhase =
    BuildComplete
        ( BuildResult
            { completedAt = epoch
            , duration = 0
            , moduleCount = 0
            , diagnostics = []
            }
        )
        $ PostBuild mempty mempty


emptyBuildResult :: BuildResult
emptyBuildResult =
    BuildResult
        { completedAt = epoch
        , duration = 0
        , moduleCount = 0
        , diagnostics = []
        }


emptyDaemonInfo :: DaemonInfo
emptyDaemonInfo =
    DaemonInfo
        { targets = []
        , watchDirs = []
        , sockPath = ""
        , logFile = ""
        , metricsPort = Nothing
        }


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0
