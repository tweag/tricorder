module Unit.Tricorder.Daemon.Ghci.LoadResultSpec (test_LoadResult) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Daemon.Ghci.LoadResult (LoadResult (..))
import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))

import Tricorder.Daemon.Ghci.LoadResult qualified as LoadResult


test_LoadResult :: TestTree
test_LoadResult =
    testGroup
        "LoadResult"
        [ testGroup "resolveKnownTargets" testResolveKnownTargets
        ]


testResolveKnownTargets :: [TestTree]
testResolveKnownTargets =
    [ testCase "uses :show modules as the primary source for path↔name mapping" do
        let result =
                emptyLr
                    { loadedModules =
                        Map.fromList
                            [
                                ( "/abs/src/Foo.hs"
                                , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                                )
                            ]
                    , targetNames = ["Foo"]
                    }
        LoadResult.resolveKnownTargets Map.empty result
            @?= Map.fromList
                [
                    ( "/abs/src/Foo.hs"
                    , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                    )
                ]
    , -- Regression test for the stale-results bug. After a failed compile, the
      -- module disappears from :show modules but stays in :show targets. The
      -- prior state's entry must be carried over so the dispatcher continues to
      -- see the file as "known" and issues :reload (not :add) when the user
      -- fixes the error.
      testCase "carries over prior state for targets that are no longer in :show modules" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result =
                emptyLr
                    { loadedModules = Map.empty -- Foo failed to compile
                    , targetNames = ["Foo"] -- but is still a target
                    }
        LoadResult.resolveKnownTargets prev result @?= prev
    , testCase "drops targets that are no longer in :show targets" do
        let prev =
                Map.fromList
                    [
                        ( "/abs/src/Foo.hs"
                        , LoadedModule {relPath = "./src/Foo.hs", moduleName = "Foo"}
                        )
                    ]
            result = emptyLr {loadedModules = Map.empty, targetNames = []}
        LoadResult.resolveKnownTargets prev result @?= Map.empty
    , -- Dropped from the path-keyed map because we have no path↔name entry;
      -- the dispatcher still handles them via 'KnownTargetNames'.
      testCase "drops targets that have neither a current :show modules entry nor prior state" do
        let result = emptyLr {loadedModules = Map.empty, targetNames = ["BrandNew"]}
        LoadResult.resolveKnownTargets Map.empty result @?= Map.empty
    ]
  where
    emptyLr =
        LoadResult
            { moduleCount = 0
            , compiledFiles = Set.empty
            , loadedModules = Map.empty
            , targetNames = []
            , diagnostics = []
            }
