module Unit.Tricorder.SourceLookup.GhcPkgSpec (test_GhcPkg) where

import Effectful (runPureEff)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Tricorder.Session.Repl (Repl (..))
import Tricorder.SourceLookup.GhcPkg (GhcPkg, GhcPkgScript (..), findModule, runGhcPkgScripted)


test_GhcPkg :: TestTree
test_GhcPkg =
    testGroup
        "GhcPkg"
        [ testGroup "findModule" testFindModule
        ]


testFindModule :: [TestTree]
testFindModule =
    [ testCase "returns Just pkgId when module is known" do
        let result = runScripted [NextFindModule (Just "base-4.18")] $ findModule Cabal "Prelude"
        result @?= Just "base-4.18"
    , testCase "returns Nothing for an unknown module" do
        let result = runScripted [NextFindModule Nothing] $ findModule Cabal "No.Such.Module"
        result @?= Nothing
    , testCase "returns the first scripted result" do
        let result =
                runScripted [NextFindModule (Just "pkg-1.0"), NextFindModule (Just "pkg-2.0")]
                    $ findModule Cabal "Foo"
        result @?= Just "pkg-1.0"
    ]


runScripted :: [GhcPkgScript] -> Eff '[GhcPkg] a -> a
runScripted script = runPureEff . runGhcPkgScripted script
