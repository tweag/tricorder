module Unit.Tricorder.Session.TargetSpec (test_Target) where

import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (assertBool, testCase, (@?=))

import Tricorder.Session.CabalFile (CabalFile (..))
import Tricorder.Session.Target
    ( ComponentKind (..)
    , Target (..)
    , allComponentTargets
    , compareTargets
    , definesCustomPrelude
    , parseTarget
    , resolveTargets
    )
import Unit.Tricorder.Session.Helpers
    ( gpd
    , libTestCabal
    , libWithPreludeCabal
    , multiCabalFiles
    , singleCabalFile
    )


test_Target :: TestTree
test_Target =
    testGroup
        "Target"
        [ testGroup "resolveTargets" testResolveTargets
        , testGroup "parseTarget" testParseTarget
        , testGroup "compareTargets" testCompareTargets
        , testGroup "allComponentTargets" testAllComponentTargets
        , testGroup "definesCustomPrelude" testDefinesCustomPrelude
        ]


testParseTarget :: [TestTree]
testParseTarget =
    [ testGroup
        "qualified targets"
        [ testCase "parses lib: as the main library (empty name)" do
            parseTarget "lib:" @?= Qualified Lib ""
        , testCase "parses a named lib: target" do
            parseTarget "lib:myapp-utils" @?= Qualified Lib "myapp-utils"
        , testCase "parses an flib: target" do
            parseTarget "flib:myapp-flib" @?= Qualified FLib "myapp-flib"
        , testCase "parses an exe: target" do
            parseTarget "exe:myapp-exe" @?= Qualified Exe "myapp-exe"
        , testCase "parses a test: target" do
            parseTarget "test:myapp-test" @?= Qualified Test "myapp-test"
        , testCase "parses a bench: target" do
            parseTarget "bench:myapp-bench" @?= Qualified Bench "myapp-bench"
        ]
    , testGroup
        "a name with no kind prefix"
        [ testCase "parses as bare" do
            parseTarget "myapp" @?= Bare "myapp"
        ]
    , testGroup
        "unrecognized targets"
        [ testCase "rejects an unknown kind" do
            parseTarget "bogus:myapp" @?= Unrecognized "bogus:myapp"
        , testCase "rejects a form with extra colons" do
            parseTarget "lib:a:b" @?= Unrecognized "lib:a:b"
        ]
    ]


testResolveTargets :: [TestTree]
testResolveTargets =
    [ testGroup
        "when targets are configured"
        [ testCase "parses and sorts configured targets" do
            let actual = resolveTargets [] ["lib:foo", "test:foo-test"]
            actual @?= [Qualified Lib "foo", Qualified Test "foo-test"]
        ]
    , testGroup
        "when no targets are configured"
        [ testCase "auto-detects all components from the cabal file" do
            -- cabalFixture exposes no Prelude module, so all components sort
            -- alphabetically by their rendered form.
            let actual = resolveTargets singleCabalFile []
            actual
                @?= [ PackageQualified "myapp" Bench "myapp-bench"
                    , PackageQualified "myapp" Exe "myapp-exe"
                    , PackageQualified "myapp" FLib "myapp-flib"
                    , PackageQualified "myapp" Lib "myapp"
                    , PackageQualified "myapp" Lib "myapp-utils"
                    , PackageQualified "myapp" Test "myapp-test"
                    ]
        , testCase "surfaces test-suite components so they can be run after a build" do
            let actual = resolveTargets singleCabalFile []
            assertBool "expected myapp-test among the targets"
                $ PackageQualified "myapp" Test "myapp-test" `elem` actual
        , testCase "returns no targets when there are no cabal files" do
            let actual = resolveTargets [] []
            actual @?= []
        , -- [tag: test_resolve_targest_aggregate]
          testCase "aggregates components across every package (regression: was 0)" do
            let actual = resolveTargets multiCabalFiles []
            actual
                @?= [ PackageQualified "pkg-a" Lib "pkg-a"
                    , PackageQualified "pkg-a" Test "pkg-a-test"
                    , PackageQualified "pkg-b" Lib "pkg-b"
                    , PackageQualified "pkg-b" Test "pkg-b-test"
                    ]
        , testCase "sorts a library exposing a custom Prelude last" do
            let cabalFile =
                    CabalFile "/myprelude.cabal"
                        $ fromMaybe (error "libWithPreludeCabal failed to parse")
                        $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "myprelude")
            let actual = resolveTargets [cabalFile] []
            actual
                @?= [ PackageQualified "myprelude" Exe "myprelude-exe"
                    , PackageQualified "myprelude" Lib "myprelude"
                    ]
        ]
    ]


testCompareTargets :: [TestTree]
testCompareTargets =
    -- A predicate that stands in for 'definesCustomPrelude': marks lib: targets
    -- as "defines custom Prelude" so the comparison contract is exercised
    -- independently of cabal-file parsing.
    [ testGroup
        "Ord"
        [ testGroup
            "only first target matches the predicate"
            [ testGroup
                "first target's render normally sorts as LT"
                [ testCase "should return GT" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Exe "b") @?= GT
                ]
            , testGroup
                "both targets have the same render"
                [ testCase "should return GT" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Exe "a") @?= GT
                ]
            , testGroup
                "first target's render normally sorts as GT"
                [ testCase "should return GT" do
                    compareTargets defPred (Qualified Lib "b") (Qualified Exe "a") @?= GT
                ]
            ]
        , testGroup
            "only second target matches the predicate"
            [ testGroup
                "first target's render normally sorts as LT"
                [ testCase "should return LT" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Lib "b") @?= LT
                ]
            , testGroup
                "both targets have the same render"
                [ testCase "should return LT" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Lib "a") @?= LT
                ]
            , testGroup
                "first target's render normally sorts as GT"
                [ testCase "should return LT" do
                    compareTargets defPred (Qualified Exe "b") (Qualified Lib "a") @?= LT
                ]
            ]
        , testGroup
            "both targets match the predicate"
            [ testGroup
                "first target's render normally sorts as LT"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Lib "b") @?= LT
                ]
            , testGroup
                "both targets have the same render"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Lib "a") @?= EQ
                ]
            , testGroup
                "first target's render normally sorts as GT"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Lib "b") (Qualified Lib "a") @?= GT
                ]
            ]
        , testGroup
            "neither target matches the predicate"
            [ testGroup
                "first target's render normally sorts as LT"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Exe "b") @?= LT
                ]
            , testGroup
                "both targets have the same render"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Exe "a") @?= EQ
                ]
            , testGroup
                "first target's render normally sorts as GT"
                [ testCase "should sort normally" do
                    compareTargets defPred (Qualified Exe "b") (Qualified Exe "a") @?= GT
                ]
            ]
        ]
    ]
  where
    defPred (Qualified Lib _) = True
    defPred _ = False


testAllComponentTargets :: [TestTree]
testAllComponentTargets =
    [ testCase "returns every component for the fixture" do
        allComponentTargets gpd
            @?= [ PackageQualified "myapp" Lib "myapp"
                , PackageQualified "myapp" Lib "myapp-utils"
                , PackageQualified "myapp" FLib "myapp-flib"
                , PackageQualified "myapp" Exe "myapp-exe"
                , PackageQualified "myapp" Test "myapp-test"
                , PackageQualified "myapp" Bench "myapp-bench"
                ]
    , -- This test ensures `allComponentTargets`' part of the aggregate test.
      -- [ref:test_resolve_targest_aggregate]
      testCase "returns every component for test fixures" do
        let actual =
                allComponentTargets
                    $ fromMaybe (error "failed to parse cabal")
                    $ parseGenericPackageDescriptionMaybe
                    $ libTestCabal "pkg-a"
        actual
            @?= [ PackageQualified "pkg-a" Lib "pkg-a"
                , PackageQualified "pkg-a" Test "pkg-a-test"
                ]
    ]


testDefinesCustomPrelude :: [TestTree]
testDefinesCustomPrelude =
    [ testGroup
        "when the main library exposes Prelude"
        [ testCase "returns True for Qualified Lib \"\" (unnamed main lib)" do
            definesCustomPrelude [preludeCF] (Qualified Lib "") @?= True
        , testCase "returns True for Qualified Lib matching the package name" do
            definesCustomPrelude [preludeCF] (Qualified Lib "myprelude") @?= True
        , testCase "returns True for Bare matching the package name" do
            definesCustomPrelude [preludeCF] (Bare "myprelude") @?= True
        ]
    , testGroup
        "when no library exposes Prelude"
        [ testCase "returns False for a lib target in a normal package" do
            definesCustomPrelude singleCabalFile (Qualified Lib "myapp") @?= False
        , testCase "returns False for Bare matching the package name" do
            definesCustomPrelude singleCabalFile (Bare "myapp") @?= False
        ]
    , testGroup
        "for non-library targets"
        [ testCase "returns False for Qualified Exe" do
            definesCustomPrelude [preludeCF] (Qualified Exe "myprelude-exe") @?= False
        , testCase "returns False for Qualified Test" do
            definesCustomPrelude singleCabalFile (Qualified Test "myapp-test") @?= False
        , testCase "returns False for Unrecognized" do
            definesCustomPrelude [preludeCF] (Unrecognized "library:myprelude") @?= False
        ]
    , testCase "returns False when the cabal file list is empty" do
        definesCustomPrelude [] (Qualified Lib "anything") @?= False
    ]
  where
    preludeCF =
        CabalFile "/myprelude.cabal"
            $ fromMaybe (error "libWithPreludeCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "myprelude")
