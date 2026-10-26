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
    flags = { build-example = false; };
    package = {
      specVersion = "2.0";
      identifier = { name = "tasty-golden"; version = "2.3.6"; };
      license = "MIT";
      copyright = "";
      maintainer = "Roman Cheplyaka <roma@ro-che.info>";
      author = "Roman Cheplyaka";
      homepage = "https://github.com/UnkindPartition/tasty-golden";
      url = "";
      synopsis = "Golden tests support for tasty";
      description = "This package provides support for «golden testing».\nA golden test is an IO action that writes its result to a file.\nTo pass the test, this output file should be identical to the corresponding\n«golden» file, which contains the correct result for the test.\nTo get started with golden testing and this library, see\n<https://ro-che.info/articles/2017-12-04-golden-tests Introduction to golden testing>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      exes = {
        "example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
          ];
          buildable = if !flags.build-example then false else true;
        };
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          ];
          build-tools = pkgs.lib.optional (flags.build-example) (hsPkgs.pkgsBuildBuild.tasty-golden.components.exes.example or (pkgs.pkgsBuildBuild.example or (errorHandler.buildToolDepError "tasty-golden:example")));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tasty-golden-2.3.6.tar.gz";
      sha256 = "8f377fa3a21700c10f8895e01ab9fe3db6aa162429f8ae58fc00f2d391d70abc";
    });
  }) // {
    package-description-override = "cabal-version:       2.0\nname:                tasty-golden\nversion:             2.3.6\nsynopsis:            Golden tests support for tasty\ndescription:\n  This package provides support for «golden testing».\n\n  A golden test is an IO action that writes its result to a file.\n  To pass the test, this output file should be identical to the corresponding\n  «golden» file, which contains the correct result for the test.\n\n  To get started with golden testing and this library, see\n  <https://ro-che.info/articles/2017-12-04-golden-tests Introduction to golden testing>.\n\nlicense:             MIT\nlicense-file:        LICENSE\nHomepage:            https://github.com/UnkindPartition/tasty-golden\nBug-reports:         https://github.com/UnkindPartition/tasty-golden/issues\nauthor:              Roman Cheplyaka\nmaintainer:          Roman Cheplyaka <roma@ro-che.info>\n-- copyright:\ncategory:            Testing\nbuild-type:          Simple\n\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nextra-source-files:\n  example/golden/fail/*.golden\n  example/golden/success/*.golden\n  tests/golden/*.golden\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nSource-repository head\n  type:     git\n  location: https://github.com/UnkindPartition/tasty-golden.git\n\nlibrary\n  Default-language:\n    Haskell2010\n  default-extensions:\n    ScopedTypeVariables\n  exposed-modules:     Test.Tasty.Golden\n                       Test.Tasty.Golden.Advanced\n                       Test.Tasty.Golden.Manage\n  other-modules:\n                       Test.Tasty.Golden.Internal\n\n  ghc-options: -Wall\n\n  build-depends:\n    base >= 4.9 && < 5,\n    tasty >= 1.3,\n    bytestring >= 0.9.2.1,\n    typed-process,\n    optparse-applicative >= 0.3.1,\n    filepath,\n    temporary,\n    deepseq,\n    containers,\n    directory,\n    text\n\nTest-suite test\n  Default-language:\n    Haskell2010\n  Type:\n    exitcode-stdio-1.0\n  Hs-source-dirs:\n    tests\n  Main-is:\n    test.hs\n  Build-depends:\n      base >= 4.9 && < 5\n    , tasty >= 1.2\n    , tasty-hunit\n    , tasty-golden\n    , filepath\n    , directory\n    , typed-process\n    , temporary\n  if (flag(build-example))\n    cpp-options: -DBUILD_EXAMPLE\n    build-tool-depends: tasty-golden:example\n  Ghc-options: -threaded\n\nflag build-example\n  default: False\n  manual: True\n\n-- An example test suite used for testing.\n-- Tries to exercise all ways to create golden tests.\n-- Not built by default. To build it, turn on the build-example flag:\n--\n--  stack build :example --flag tasty-golden:build-example\nexecutable example\n  Default-language:\n    Haskell2010\n  Hs-source-dirs:\n    example\n  Main-is:\n    example.hs\n  if (! flag(build-example))\n    buildable: False\n  Build-depends:\n      base >= 4 && < 5\n    , filepath\n    , bytestring\n    , tasty\n    , tasty-golden\n  Ghc-options: -threaded\n";
  }