module Unit.Tricorder.SessionSpec (spec_Session) where

import Atelier.Config (LoadedConfig (..))
import Atelier.Effects.FileSystem (runFileSystemState)
import Atelier.Effects.Log (Message (..), Severity (..), runLogNoOp, runLogWriter)
import Data.Aeson (Value (Null), eitherDecode)
import Data.Default (Default (..))
import Distribution.PackageDescription.Parsec (parseGenericPackageDescriptionMaybe)
import Distribution.Types.GenericPackageDescription (GenericPackageDescription)
import Effectful (runPureEff)
import Effectful.Reader.Static (runReader)
import Effectful.State.Static.Shared (evalState)
import Effectful.Writer.Static.Shared (execWriter)
import Test.Hspec

import Data.Map.Strict qualified as Map
import Data.Text qualified as T

import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session
    ( CabalFile (..)
    , Command (..)
    , ComponentKind (..)
    , Config (..)
    , Target (..)
    , WatchDirs (..)
    , allComponentTargets
    , compareTargets
    , definesCustomPrelude
    , discoverCabalFiles
    , loadSession
    , parseTarget
    , parseTestTargets
    , resolveCommand
    , resolveTargets
    , resolveTestTargets
    , resolveWatchDirs
    , sourceDirsForTarget
    )


spec_Session :: Spec
spec_Session = do
    describe "resolveCommand" testResolveCommand
    describe "discoverCabalFiles" testDiscoverCabalFiles
    describe "resolveTargets" testResolveTargets
    describe "resolveWatchDirs" testResolveWatchDirs
    describe "resolveTestTargets" testResolveTestTargets
    describe "parseTarget" testParseTarget
    describe "sourceDirsForTarget" testSourceDirsForTarget
    describe "allComponentTargets" testAllComponentTargets
    describe "compareTargets" testCompareTargets
    describe "definesCustomPrelude" testDefinesCustomPrelude
    describe "loadSession" testLoadSession
    describe "Config FromJSON" testConfigFromJSON


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


-- | These exercise the 'Target' -> dirs resolution directly with constructed
-- 'Target' values; the string -> 'Target' parsing is covered by 'testParseTarget'.
testSourceDirsForTarget :: Spec
testSourceDirsForTarget = do
    describe "Qualified Lib" do
        context "when the name is empty" do
            it "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "") `shouldBe` ["src"]

        context "when the name matches the package name" do
            it "returns the main library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp") `shouldBe` ["src"]

        context "when the name matches a sub-library" do
            it "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Qualified Lib "myapp-utils") `shouldBe` ["utils"]

        context "when the sub-library is unknown" do
            it "returns an empty list" do
                sourceDirsForTarget gpd (Qualified Lib "nonexistent") `shouldBe` []

    describe "Qualified FLib" do
        it "returns the foreign-library source dirs" do
            sourceDirsForTarget gpd (Qualified FLib "myapp-flib") `shouldBe` ["flib"]

    describe "Qualified Exe" do
        it "returns the executable source dirs" do
            sourceDirsForTarget gpd (Qualified Exe "myapp-exe") `shouldBe` ["app"]

    describe "Qualified Test" do
        it "returns the test suite source dirs" do
            sourceDirsForTarget gpd (Qualified Test "myapp-test") `shouldBe` ["test"]

    describe "Qualified Bench" do
        it "returns the benchmark source dirs" do
            sourceDirsForTarget gpd (Qualified Bench "myapp-bench") `shouldBe` ["bench"]

    describe "Bare (package name)" do
        it "returns every component's source dirs" do
            sourceDirsForTarget gpd (Bare "myapp") `shouldBe` ["src", "utils", "flib", "app", "test", "bench"]

    describe "Bare (component name)" do
        context "when it names a sub-library" do
            it "returns the sub-library source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-utils") `shouldBe` ["utils"]

        context "when it names an executable" do
            it "returns the executable source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-exe") `shouldBe` ["app"]

        context "when it names a test suite" do
            it "returns the test suite source dirs" do
                sourceDirsForTarget gpd (Bare "myapp-test") `shouldBe` ["test"]

        context "when it matches no component" do
            it "returns an empty list" do
                sourceDirsForTarget gpd (Bare "unknown") `shouldBe` []

    describe "Unrecognized" do
        it "matches an aliased kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "executable:myapp-exe") `shouldBe` ["app"]

        it "matches a case-variant kind prefix by trailing name" do
            sourceDirsForTarget gpd (Unrecognized "Test-Suite:myapp-test") `shouldBe` ["test"]

        it "matches the main library when the trailing name is the package name" do
            sourceDirsForTarget gpd (Unrecognized "library:myapp") `shouldBe` ["src"]

        it "returns an empty list when the trailing name matches no component" do
            sourceDirsForTarget gpd (Unrecognized "bogus:x") `shouldBe` []


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


-- | Pins the discovery contract: a @cabal.project@ selects per-package
-- @.cabal@ files from its @packages:@ stanza; otherwise the @.cabal@ files in
-- the project root are used.
testDiscoverCabalFiles :: Spec
testDiscoverCabalFiles = do
    describe "when there is no cabal.project" do
        it "finds the .cabal files in the project root" do
            let actual =
                    runDiscovery (Map.singleton "/myapp.cabal" cabalFixture)
                        $ discoverCabalFiles pr
            actual `shouldBe` ["/myapp.cabal"]

        it "returns no files when the root has no cabal file" do
            let actual = runDiscovery mempty $ discoverCabalFiles pr
            actual `shouldBe` []

    describe "when there is a multi-package cabal.project" do
        it "resolves each listed package to its .cabal (regression: was root-only)" do
            let actual = runDiscovery multiPackageFs $ discoverCabalFiles pr
            actual `shouldBe` ["/pkg-a/pkg-a.cabal", "/pkg-b/pkg-b.cabal"]
  where
    pr = ProjectRoot "/"
    runDiscovery fs = runPureEff . evalState fs . runFileSystemState . runLogNoOp


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


testResolveWatchDirs :: Spec
testResolveWatchDirs = do
    describe "when watch_dirs is set in config" do
        it "uses config dirs relative to project root" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def {watchDirs = ["src", "test"]} []
            actual `shouldBe` ["/src", "/test"]

    describe "when watch_dirs is not set" do
        it "falls back to [\".\"] when targets list is empty" do
            let WatchDirs actual = resolveWatchDirs pr [] def []
            actual `shouldBe` ["."]

        it "infers source dirs from resolved targets" do
            let WatchDirs actual =
                    resolveWatchDirs pr singleCabalFile def (mkTargets ["lib:myapp", "test:myapp-test"])
            actual `shouldBe` ["/src", "/test"]

        it "falls back to [\".\"] when there are no cabal files" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual `shouldBe` ["."]

        -- Sharp edge: an unparseable .cabal yields no source dirs, so resolution
        -- falls back to watching the whole project root. This pins the current
        -- behavior; if it ever changes to something narrower, update this test.
        it "falls back to [\".\"] when no cabal files are found or parsed" do
            let WatchDirs actual =
                    resolveWatchDirs pr [] def (mkTargets ["lib:myapp"])
            actual `shouldBe` ["."]

    describe "when the project is a multi-package cabal.project" do
        it "infers per-package source dirs, scoped to each package's directory" do
            let WatchDirs actual =
                    resolveWatchDirs
                        pr
                        multiCabalFiles
                        def
                        (mkTargets ["lib:pkg-a", "test:pkg-a-test", "lib:pkg-b", "test:pkg-b-test"])
            actual
                `shouldBe` ["/pkg-a/src", "/pkg-a/test", "/pkg-b/src", "/pkg-b/test"]

        it "scopes a bare package-name target to that package, ignoring siblings" do
            let WatchDirs actual =
                    resolveWatchDirs pr multiCabalFiles def (mkTargets ["pkg-a"])
            actual `shouldBe` ["/pkg-a/src", "/pkg-a/test"]
  where
    pr = ProjectRoot "/"


testResolveTestTargets :: Spec
testResolveTestTargets = do
    it "infers test: components from targets when testTargets is absent" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "test:mylib-test"]) `shouldBe` parseTestTargets ["test:mylib-test"]

    it "returns empty list when no test: components in targets" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:mylib", "exe:myapp"]) `shouldBe` parseTestTargets []

    it "uses explicit testTargets list when set" do
        let cfg = def {testTargets = Just ["test:b-test"]} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"]) `shouldBe` parseTestTargets ["test:b-test"]

    it "returns empty list when testTargets is explicitly empty" do
        let cfg = def {testTargets = Just []} :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test"]) `shouldBe` parseTestTargets []

    it "infers multiple test: components" do
        let cfg = def :: Config
        resolveTestTargets cfg (mkTargets ["lib:a", "test:a-test", "test:b-test"]) `shouldBe` parseTestTargets ["test:a-test", "test:b-test"]


testResolveCommand :: Spec
testResolveCommand = do
    describe "when config has a command" do
        it "should use specified command" do
            let Command actual =
                    runPureEff
                        . evalState mempty
                        . runFileSystemState
                        $ resolveCommand pr def {command = Just "foo"} [] testTargets
            actual `shouldBe` "foo"

    describe "when config has explicit targets" do
        it "should spell them out verbatim, ignoring discovered test targets" do
            let Command actual =
                    runPureEff
                        . evalState (Map.singleton "/cabal.project" "")
                        . runFileSystemState
                        $ resolveCommand pr cfg (mkTargets ["lib:foo"]) testTargets
            actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild lib:foo"

    describe "when config does not have a command or targets" do
        describe "and there is a cabal.project file" do
            it "should use cabal 'all' plus the discovered test targets" do
                let Command actual =
                        runPureEff
                            . evalState (Map.singleton "/cabal.project" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual
                    `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"

        describe "and there is at least one *.cabal file" do
            it "should use cabal 'all' plus the discovered test targets" do
                let Command actual =
                        runPureEff
                            . evalState (Map.singleton "/foo.cabal" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual
                    `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all test:foo"

        describe "and there is a stack.yaml file" do
            it "should use stack ghci with 'all' plus test targets" do
                let Command actual =
                        runPureEff
                            . evalState (Map.singleton "/stack.yaml" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "stack ghci all test:foo"

        describe "but there are no project files" do
            it "should use default cabal repl with 'all' plus test targets" do
                let Command actual =
                        runPureEff
                            . evalState mempty
                            . runFileSystemState
                            $ resolveCommand pr cfg [] testTargets
                actual `shouldBe` "cabal repl --builddir /replbuild all test:foo"

        describe "and no test targets are discovered" do
            it "should fall back to plain 'all'" do
                let Command actual =
                        runPureEff
                            . evalState (Map.singleton "/cabal.project" "")
                            . runFileSystemState
                            $ resolveCommand pr cfg [] (parseTestTargets [])
                actual `shouldBe` "cabal repl --enable-multi-repl --builddir /replbuild all"
  where
    pr = ProjectRoot "/"
    cfg = def {replBuildDir = "/replbuild"}
    testTargets = parseTestTargets ["test:foo"]


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


testLoadSession :: Spec
testLoadSession = do
    describe "when every resolved target exposes a custom Prelude module" do
        it "emits a WARN" do
            let msgs = captureSessionLogs [preludeOnlyCF]
            any (\m -> m.severity == WARN) msgs `shouldBe` True

    describe "when not every resolved target exposes a custom Prelude module" do
        it "does not emit a WARN" do
            -- libWithPreludeCabal has both a lib (custom Prelude) and an exe (no Prelude)
            let msgs = captureSessionLogs [mixedCF]
            any (\m -> m.severity == WARN) msgs `shouldBe` False

    it "does not emit a WARN when there are no resolved targets" do
        any (\m -> m.severity == WARN) (captureSessionLogs []) `shouldBe` False
  where
    preludeOnlyCF =
        CabalFile "/p.cabal"
            $ fromMaybe (error "preludeOnlyLibCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (preludeOnlyLibCabal "p")
    mixedCF =
        CabalFile "/mixed.cabal"
            $ fromMaybe (error "libWithPreludeCabal failed to parse")
            $ parseGenericPackageDescriptionMaybe (libWithPreludeCabal "mixed")
    captureSessionLogs cabalFiles =
        runPureEff
            . execWriter @[Message]
            . runLogWriter
            . evalState @(Map FilePath ByteString) mempty
            . runFileSystemState
            . runReader cabalFiles
            . runReader (ProjectRoot "/")
            . runReader (LoadedConfig Null)
            $ loadSession


testConfigFromJSON :: Spec
testConfigFromJSON = do
    describe "turbo_tests" do
        it "defaults to False when omitted" do
            decodedTurbo "{}" `shouldBe` Right False

        it "parses an explicit true" do
            decodedTurbo "{\"turbo_tests\": true}" `shouldBe` Right True

        it "parses an explicit false" do
            decodedTurbo "{\"turbo_tests\": false}" `shouldBe` Right False
  where
    -- Pin the decode target to 'Config' so the field access resolves.
    decodedTurbo :: LByteString -> Either String Bool
    decodedTurbo bs = (.turboTests) <$> (eitherDecode bs :: Either String Config)


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


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

gpd :: GenericPackageDescription
gpd =
    fromMaybe (error "cabalFixture failed to parse")
        $ parseGenericPackageDescriptionMaybe cabalFixture


-- | Build a target list from textual forms, exactly as config and cabal
-- discovery do via 'parseTarget'.
mkTargets :: [Text] -> [Target]
mkTargets = map parseTarget


multiCabalFiles :: [CabalFile]
multiCabalFiles =
    uncurry CabalFile
        . second
            ( fromMaybe (error "multiCabalFiles failed to parse")
                . parseGenericPackageDescriptionMaybe
            )
        <$> Map.toList multiPackageCabalFs


-- | An in-memory project root with a @cabal.project@ listing two packages,
-- each in its own subdirectory with a library and a test suite.
multiPackageFs :: Map FilePath ByteString
multiPackageFs =
    Map.fromList
        [ ("/cabal.project", "packages:\n  pkg-a\n  pkg-b\n\ntests: True\n")
        ]
        `Map.union` multiPackageCabalFs


multiPackageCabalFs :: Map FilePath ByteString
multiPackageCabalFs =
    Map.fromList
        [ ("/pkg-a/pkg-a.cabal", libTestCabal "pkg-a")
        , ("/pkg-b/pkg-b.cabal", libTestCabal "pkg-b")
        ]


-- | A minimal cabal file for @name@ with a single library that exposes
-- @Prelude@ and nothing else. All auto-detected targets define a custom
-- Prelude, which triggers the 'loadSession' warning.
preludeOnlyLibCabal :: Text -> ByteString
preludeOnlyLibCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  exposed-modules: Prelude"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


-- | A minimal cabal file for @name@ with one library that exposes @Prelude@
-- and one executable. Used to verify that libraries defining a custom Prelude
-- are sorted last by 'resolveTargets'.
libWithPreludeCabal :: Text -> ByteString
libWithPreludeCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  exposed-modules: Prelude"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            , ""
            , "executable " <> name <> "-exe"
            , "  main-is: Main.hs"
            , "  hs-source-dirs: app"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


-- | A minimal cabal file for @name@ with one library and one test suite
-- (@<name>-test@).
libTestCabal :: Text -> ByteString
libTestCabal name =
    encodeUtf8
        $ T.unlines
            [ "cabal-version: 2.0"
            , "name:          " <> name
            , "version:       0.1.0.0"
            , "build-type:    Simple"
            , ""
            , "library"
            , "  hs-source-dirs: src"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            , ""
            , "test-suite " <> name <> "-test"
            , "  type: exitcode-stdio-1.0"
            , "  main-is: Test.hs"
            , "  hs-source-dirs: test"
            , "  build-depends: base"
            , "  default-language: Haskell2010"
            ]


singleCabalFile :: [CabalFile]
singleCabalFile = [CabalFile "/myapp.cabal" gpdFixture]


gpdFixture :: GenericPackageDescription
gpdFixture = fromMaybe (error "gpdFixture failed to parse") $ parseGenericPackageDescriptionMaybe cabalFixture


cabalFixture :: ByteString
cabalFixture =
    "cabal-version: 2.0\n\
    \name:          myapp\n\
    \version:       0.1.0.0\n\
    \build-type:    Simple\n\
    \\n\
    \library\n\
    \  hs-source-dirs: src\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \library myapp-utils\n\
    \  hs-source-dirs: utils\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \foreign-library myapp-flib\n\
    \  type: native-shared\n\
    \  hs-source-dirs: flib\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \executable myapp-exe\n\
    \  main-is: Main.hs\n\
    \  hs-source-dirs: app\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \test-suite myapp-test\n\
    \  type: exitcode-stdio-1.0\n\
    \  main-is: Test.hs\n\
    \  hs-source-dirs: test\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n\
    \\n\
    \benchmark myapp-bench\n\
    \  type: exitcode-stdio-1.0\n\
    \  main-is: Bench.hs\n\
    \  hs-source-dirs: bench\n\
    \  build-depends: base\n\
    \  default-language: Haskell2010\n"
