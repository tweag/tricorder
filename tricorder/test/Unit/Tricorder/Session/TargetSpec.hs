module Unit.Tricorder.Session.TargetSpec (spec_Target) where

import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Test.Hspec
    ( Spec
    , describe
    , it
    , shouldBe
    , shouldContain
    , shouldMatchList
    )

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


spec_Target :: Spec
spec_Target = do
    describe "resolveTargets" testResolveTargets
    describe "parseTarget" testParseTarget
    describe "compareTargets" testCompareTargets
    describe "allComponentTargets" testAllComponentTargets
    describe "definesCustomPrelude" testDefinesCustomPrelude


testParseTarget :: Spec
testParseTarget = do
    describe "qualified targets" do
        it "parses lib: as the main library (empty name)" do
            parseTarget "lib:" `shouldBe` Qualified Lib ""

        it "parses a named lib: target" do
            parseTarget "lib:myapp-utils" `shouldBe` Qualified Lib "myapp-utils"

        it "parses an flib: target" do
            parseTarget "flib:myapp-flib" `shouldBe` Qualified FLib "myapp-flib"

        it "parses an exe: target" do
            parseTarget "exe:myapp-exe" `shouldBe` Qualified Exe "myapp-exe"

        it "parses a test: target" do
            parseTarget "test:myapp-test" `shouldBe` Qualified Test "myapp-test"

        it "parses a bench: target" do
            parseTarget "bench:myapp-bench" `shouldBe` Qualified Bench "myapp-bench"

    describe "a name with no kind prefix" do
        it "parses as bare" do
            parseTarget "myapp" `shouldBe` Bare "myapp"

    describe "unrecognized targets" do
        it "rejects an unknown kind" do
            parseTarget "bogus:myapp" `shouldBe` Unrecognized "bogus:myapp"

        it "rejects a form with extra colons" do
            parseTarget "lib:a:b" `shouldBe` Unrecognized "lib:a:b"


testResolveTargets :: Spec
testResolveTargets = do
    describe "when targets are configured" do
        it "parses and sorts configured targets" do
            let actual = resolveTargets [] ["lib:foo", "test:foo-test"]
            actual `shouldBe` [Qualified Lib "foo", Qualified Test "foo-test"]

    describe "when no targets are configured" do
        it "auto-detects all components from the cabal file" do
            -- cabalFixture exposes no Prelude module, so all components sort
            -- alphabetically by their rendered form.
            let actual = resolveTargets singleCabalFile []
            actual
                `shouldBe` [ Qualified Bench "myapp-bench"
                           , Qualified Exe "myapp-exe"
                           , Qualified FLib "myapp-flib"
                           , Qualified Lib "myapp"
                           , Qualified Lib "myapp-utils"
                           , Qualified Test "myapp-test"
                           ]

        it "surfaces test-suite components so they can be run after a build" do
            let actual = resolveTargets singleCabalFile []
            actual `shouldContain` [Qualified Test "myapp-test"]

        it "returns no targets when there are no cabal files" do
            let actual = resolveTargets [] []
            actual `shouldBe` []

        -- [tag: test_resolve_targest_aggregate]
        it "aggregates components across every package (regression: was 0)" do
            let actual = resolveTargets multiCabalFiles []
            actual
                `shouldMatchList` [ Qualified Test "pkg-a-test"
                                  , Qualified Test "pkg-b-test"
                                  , Qualified Lib "pkg-a"
                                  , Qualified Lib "pkg-b"
                                  ]

        it "sorts a library exposing a custom Prelude last" do
            let cabalFile =
                    CabalFile "/myprelude.cabal"
                        $ fromMaybe (error "libWithPreludeCabal failed to parse")
                        $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "myprelude")
            let actual = resolveTargets [cabalFile] []
            actual `shouldBe` [Qualified Exe "myprelude-exe", Qualified Lib "myprelude"]


testCompareTargets :: Spec
testCompareTargets = do
    -- A predicate that stands in for 'definesCustomPrelude': marks lib: targets
    -- as "defines custom Prelude" so the comparison contract is exercised
    -- independently of cabal-file parsing.
    let defPred (Qualified Lib _) = True
        defPred _ = False

    describe "Ord" do
        describe "only first target matches the predicate" do
            describe "first target's render normally sorts as LT" do
                it "should return GT" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Exe "b") `shouldBe` GT
            describe "both targets have the same render" do
                it "should return GT" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Exe "a") `shouldBe` GT
            describe "first target's render normally sorts as GT" do
                it "should return GT" do
                    compareTargets defPred (Qualified Lib "b") (Qualified Exe "a") `shouldBe` GT

        describe "only second target matches the predicate" do
            describe "first target's render normally sorts as LT" do
                it "should return LT" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Lib "b") `shouldBe` LT
            describe "both targets have the same render" do
                it "should return LT" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Lib "a") `shouldBe` LT
            describe "first target's render normally sorts as GT" do
                it "should return LT" do
                    compareTargets defPred (Qualified Exe "b") (Qualified Lib "a") `shouldBe` LT

        describe "both targets match the predicate" do
            describe "first target's render normally sorts as LT" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Lib "b") `shouldBe` LT
            describe "both targets have the same render" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Lib "a") (Qualified Lib "a") `shouldBe` EQ
            describe "first target's render normally sorts as GT" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Lib "b") (Qualified Lib "a") `shouldBe` GT

        describe "neither target matches the predicate" do
            describe "first target's render normally sorts as LT" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Exe "b") `shouldBe` LT
            describe "both targets have the same render" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Exe "a") (Qualified Exe "a") `shouldBe` EQ
            describe "first target's render normally sorts as GT" do
                it "should sort normally" do
                    compareTargets defPred (Qualified Exe "b") (Qualified Exe "a") `shouldBe` GT


testAllComponentTargets :: Spec
testAllComponentTargets = do
    it "returns every component for the fixture" do
        allComponentTargets gpd
            `shouldMatchList` [ Qualified Lib "myapp"
                              , Qualified Lib "myapp-utils"
                              , Qualified FLib "myapp-flib"
                              , Qualified Exe "myapp-exe"
                              , Qualified Test "myapp-test"
                              , Qualified Bench "myapp-bench"
                              ]
    -- This test ensures `allComponentTargets`' part of the aggregate test.
    -- [ref:test_resolve_targest_aggregate]
    it "returns every component for test fixures" do
        let actual =
                allComponentTargets
                    $ fromMaybe (error "failed to parse cabal")
                    $ parseGenericPackageDescriptionMaybe
                    $ libTestCabal "pkg-a"
        actual `shouldMatchList` [Qualified Lib "pkg-a", Qualified Test "pkg-a-test"]


testDefinesCustomPrelude :: Spec
testDefinesCustomPrelude = do
    let preludeCF =
            CabalFile "/myprelude.cabal"
                $ fromMaybe (error "libWithPreludeCabal failed to parse")
                $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "myprelude")

    describe "when the main library exposes Prelude" do
        it "returns True for Qualified Lib \"\" (unnamed main lib)" do
            definesCustomPrelude [preludeCF] (Qualified Lib "") `shouldBe` True

        it "returns True for Qualified Lib matching the package name" do
            definesCustomPrelude [preludeCF] (Qualified Lib "myprelude") `shouldBe` True

        it "returns True for Bare matching the package name" do
            definesCustomPrelude [preludeCF] (Bare "myprelude") `shouldBe` True

    describe "when no library exposes Prelude" do
        it "returns False for a lib target in a normal package" do
            definesCustomPrelude singleCabalFile (Qualified Lib "myapp") `shouldBe` False

        it "returns False for Bare matching the package name" do
            definesCustomPrelude singleCabalFile (Bare "myapp") `shouldBe` False

    describe "for non-library targets" do
        it "returns False for Qualified Exe" do
            definesCustomPrelude [preludeCF] (Qualified Exe "myprelude-exe") `shouldBe` False

        it "returns False for Qualified Test" do
            definesCustomPrelude singleCabalFile (Qualified Test "myapp-test") `shouldBe` False

        it "returns False for Unrecognized" do
            definesCustomPrelude [preludeCF] (Unrecognized "library:myprelude") `shouldBe` False

    it "returns False when the cabal file list is empty" do
        definesCustomPrelude [] (Qualified Lib "anything") `shouldBe` False
