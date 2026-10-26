{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  ({
    flags = { benchmark-foreign-libraries = false; };
    package = {
      specVersion = "3.8";
      identifier = { name = "effectful"; version = "2.7.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "An easy to use, performant extensible effects library.";
      description = "An easy to use, performant extensible effects library with seamless\nintegration with the existing Haskell ecosystem.\n\nThis is the \"batteries-included\" variant. See the\n@<https://hackage.haskell.org/package/effectful-core effectful-core>@ package\nif you need a more limited dependency footprint or want to browse\ndocumentation of core modules.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."file-io" or (errorHandler.buildDepError "file-io"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."strict-mutable-base" or (errorHandler.buildDepError "strict-mutable-base"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."lifted-base" or (errorHandler.buildDepError "lifted-base"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."strict-mutable-base" or (errorHandler.buildDepError "strict-mutable-base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ] ++ pkgs.lib.optionals (flags.benchmark-foreign-libraries) (((([
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.9") (hsPkgs."cleff" or (errorHandler.buildDepError "cleff"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.9") (hsPkgs."freer-simple" or (errorHandler.buildDepError "freer-simple"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.15") (hsPkgs."fused-effects" or (errorHandler.buildDepError "fused-effects"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.15") (hsPkgs."polysemy" or (errorHandler.buildDepError "polysemy")));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-2.7.1.0.tar.gz";
      sha256 = "02f0dcbf270ffe05a1cfbe7b552ba278b6e73e01fc752fc1045436ebc53e8f8f";
    });
  }) // {
    package-description-override = "cabal-version:      3.8\nbuild-type:         Simple\nname:               effectful\nversion:            2.7.1.0\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Control\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\nsynopsis:           An easy to use, performant extensible effects library.\n\ndescription:\n  An easy to use, performant extensible effects library with seamless\n  integration with the existing Haskell ecosystem.\n\n  This is the \"batteries-included\" variant. See the\n  @<https://hackage.haskell.org/package/effectful-core effectful-core>@ package\n  if you need a more limited dependency footprint or want to browse\n  documentation of core modules.\n\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 9.6.7, 9.8.4, 9.10.3, 9.12.4, 9.14.1 }\n\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-effectful/effectful.git\n\nflag benchmark-foreign-libraries\n    description: Include other effect libraries in the benchmarks.\n    default: False\n\ncommon language\n    ghc-options:        -Wall\n                        -Wcompat\n                        -Wmissing-deriving-strategies\n                        -Werror=prepositive-qualified-module\n\n    default-language:   GHC2021\n\n    default-extensions: DataKinds\n                        DeepSubsumption\n                        DerivingStrategies\n                        DuplicateRecordFields\n                        LambdaCase\n                        NoFieldSelectors\n                        NoStarIsType\n                        OverloadedRecordDot\n                        RoleAnnotations\n                        TypeFamilies\n                        UndecidableInstances\n\nlibrary\n    import:         language\n\n    build-depends:    base                >= 4.18      && < 5\n                    , async               >= 2.2.5\n                    , bytestring          >= 0.10\n                    , directory           >= 1.3.8\n                    , effectful-core      >= 2.7.1.0   && < 2.7.2.0\n                    , file-io             >= 0.1.4\n                    , filepath            >= 1.4.100\n                    , process             >= 1.6.9\n                    , strict-mutable-base >= 2.0.0.0   && < 3\n                    , time                >= 1.9.2\n                    , stm                 >= 2.5.1.0\n                    , unliftio            >= 0.2.20\n\n    hs-source-dirs:  src\n\n    exposed-modules: Effectful.Concurrent\n                     Effectful.Concurrent.Async\n                     Effectful.Concurrent.Chan\n                     Effectful.Concurrent.Chan.Strict\n                     Effectful.Concurrent.MVar\n                     Effectful.Concurrent.MVar.Strict\n                     Effectful.Concurrent.MVar.Strict.Compat\n                     Effectful.Concurrent.STM\n                     Effectful.Concurrent.QSem\n                     Effectful.Concurrent.QSemN\n                     Effectful.Console.ByteString\n                     Effectful.Console.ByteString.Lazy\n                     Effectful.Environment\n                     Effectful.FileSystem\n                     Effectful.FileSystem.File.OsPath\n                     Effectful.FileSystem.IO\n                     Effectful.FileSystem.IO.ByteString\n                     Effectful.FileSystem.IO.ByteString.Builder\n                     Effectful.FileSystem.IO.ByteString.Lazy\n                     Effectful.FileSystem.IO.File\n                     Effectful.FileSystem.OsPath\n                     Effectful.Prim.IORef\n                     Effectful.Prim.IORef.Strict\n                     Effectful.Process\n                     Effectful.Temporary\n                     Effectful.Timeout\n\n    other-modules:   Effectful.Concurrent.Effect\n                     Effectful.Console.Effect\n                     Effectful.FileSystem.Effect\n\n    reexported-modules:    Effectful\n                         , Effectful.Dispatch.Dynamic\n                         , Effectful.Dispatch.Static\n                         , Effectful.Error.Dynamic\n                         , Effectful.Error.Static\n                         , Effectful.Exception\n                         , Effectful.Fail\n                         , Effectful.Input.Dynamic\n                         , Effectful.Input.Static\n                         , Effectful.Input.Static.Action\n                         , Effectful.Labeled\n                         , Effectful.Labeled.Error\n                         , Effectful.Labeled.Input\n                         , Effectful.Labeled.Output\n                         , Effectful.Labeled.Provider\n                         , Effectful.Labeled.Provider.List\n                         , Effectful.Labeled.Reader\n                         , Effectful.Labeled.ReturnWith\n                         , Effectful.Labeled.State\n                         , Effectful.Labeled.Writer\n                         , Effectful.NonDet\n                         , Effectful.Output.Dynamic\n                         , Effectful.Output.Static.Action\n                         , Effectful.Output.Static.Local.Array\n                         , Effectful.Output.Static.Local.List\n                         , Effectful.Output.Static.Shared.Array\n                         , Effectful.Output.Static.Shared.List\n                         , Effectful.Prim\n                         , Effectful.Provider\n                         , Effectful.Provider.List\n                         , Effectful.Reader.Dynamic\n                         , Effectful.Reader.Static\n                         , Effectful.ReturnWith.Dynamic\n                         , Effectful.ReturnWith.Static\n                         , Effectful.State.Dynamic\n                         , Effectful.State.Static.Local\n                         , Effectful.State.Static.Shared\n                         , Effectful.Writer.Dynamic\n                         , Effectful.Writer.Static.Local\n                         , Effectful.Writer.Static.Shared\n\ntest-suite test\n    import:         language\n\n    if impl(ghc >= 9.8)\n      ghc-options:  -Wno-x-partial\n\n    ghc-options:    -threaded -rtsopts -with-rtsopts=-N4\n\n    build-depends:    base\n                    , bytestring\n                    , containers\n                    , effectful\n                    , effectful-core\n                    , exceptions\n                    , filepath\n                    , lifted-base\n                    , primitive\n                    , random\n                    , safe-exceptions\n                    , strict-mutable-base\n                    , tasty\n                    , tasty-hunit\n                    , unliftio\n\n    hs-source-dirs: tests\n\n    type:           exitcode-stdio-1.0\n    main-is:        Main.hs\n\n    other-modules:  AsyncTests\n                    ConcurrencyTests\n                    EnvTests\n                    EnvironmentTests\n                    ErrorTests\n                    ExceptionTests\n                    FileSystemTests\n                    InputTests\n                    LabeledTests\n                    NonDetTests\n                    OutputTests\n                    PrimTests\n                    ReaderTests\n                    ReturnWithTests\n                    StateTests\n                    TimeoutTests\n                    UnliftTests\n                    Utils\n                    Word64MapTests\n\nbenchmark bench\n    import:         language\n\n    ghc-options:    -threaded -rtsopts -with-rtsopts=-T\n\n    if flag(benchmark-foreign-libraries)\n       build-depends: mtl\n\n       if impl(ghc < 9.9)\n          build-depends: cleff >= 0.3.3.0\n\n       if impl(ghc < 9.9)\n          build-depends: freer-simple >= 1.2.1.2\n\n       if impl(ghc < 9.15)\n          build-depends: fused-effects >= 1.1.2.3\n\n       if impl(ghc < 9.15)\n          build-depends: polysemy >= 1.9.2.0\n\n    build-depends:    base\n                    , async\n                    , effectful\n                    , tasty-bench\n                    , unix\n                    , unliftio\n                    , text\n\n    hs-source-dirs: bench\n\n    type:           exitcode-stdio-1.0\n    main-is:        Main.hs\n\n    other-modules:  Concurrency\n                    Countdown\n                    FileSizes\n                    Unlift\n                    Utils\n";
  }