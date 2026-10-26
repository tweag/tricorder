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
    flags = {};
    package = {
      specVersion = "1.10";
      identifier = { name = "hedgehog"; version = "1.7"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jacob Stanley <jacob@stanley.io>";
      author = "Jacob Stanley";
      homepage = "http://github.com/hedgehogqa/haskell-hedgehog";
      url = "";
      synopsis = "Release with confidence.";
      description = "<http://github.com/hedgehogqa/haskell-hedgehog/ Hedgehog> automatically generates a comprehensive array\nof test cases, exercising your software in ways human testers would never\nimagine.\n\nGenerate hundreds of test cases automatically, exposing even the\nmost insidious of corner cases. Failures are automatically simplified, giving\ndevelopers coherent, intelligible error messages.\n\nTo get started quickly, see the <https://github.com/hedgehogqa/haskell-hedgehog/tree/master/hedgehog-example examples>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."barbies" or (errorHandler.buildDepError "barbies"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."concurrent-output" or (errorHandler.buildDepError "concurrent-output"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."erf" or (errorHandler.buildDepError "erf"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."lifted-async" or (errorHandler.buildDepError "lifted-async"))
          (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."pretty-show" or (errorHandler.buildDepError "pretty-show"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."wl-pprint-annotated" or (errorHandler.buildDepError "wl-pprint-annotated"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."mmorph" or (errorHandler.buildDepError "mmorph"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."pretty-show" or (errorHandler.buildDepError "pretty-show"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hedgehog-1.7.tar.gz";
      sha256 = "09e2bca0f798dbf5848ff3eb78c1617fc13e51660ad5d4a457a54ce87b1b564e";
    });
  }) // {
    package-description-override = "version: 1.7\r\nx-revision: 1\r\n\r\nname:\r\n  hedgehog\r\nauthor:\r\n  Jacob Stanley\r\nmaintainer:\r\n  Jacob Stanley <jacob@stanley.io>\r\nhomepage:\r\n  http://github.com/hedgehogqa/haskell-hedgehog\r\nbug-reports:\r\n  https://github.com/hedgehogqa/haskell-hedgehog/issues\r\nsynopsis:\r\n  Release with confidence.\r\ndescription:\r\n  <http://github.com/hedgehogqa/haskell-hedgehog/ Hedgehog> automatically generates a comprehensive array\r\n  of test cases, exercising your software in ways human testers would never\r\n  imagine.\r\n  .\r\n  Generate hundreds of test cases automatically, exposing even the\r\n  most insidious of corner cases. Failures are automatically simplified, giving\r\n  developers coherent, intelligible error messages.\r\n  .\r\n  To get started quickly, see the <https://github.com/hedgehogqa/haskell-hedgehog/tree/master/hedgehog-example examples>.\r\ncategory:\r\n  Testing\r\nlicense:\r\n  BSD3\r\nlicense-file:\r\n  LICENSE\r\ncabal-version:\r\n  >= 1.10\r\nbuild-type:\r\n  Simple\r\ntested-with:\r\n    GHC == 8.2.2\r\n  , GHC == 8.4.4\r\n  , GHC == 8.6.5\r\n  , GHC == 8.8.3\r\n  , GHC == 8.10.1\r\n  , GHC == 9.0.2\r\n  , GHC == 9.2.7\r\n  , GHC == 9.4.8\r\n  , GHC == 9.6.6\r\n  , GHC == 9.8.4\r\n  , GHC == 9.10.1\r\n  , GHC == 9.12.1\r\n\r\nextra-source-files:\r\n  README.md\r\n  CHANGELOG.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/hedgehogqa/haskell-hedgehog\r\n\r\nlibrary\r\n  build-depends:\r\n   -- GHC 8.0.1 / base-4.9.0.0 (May 2016)\r\n      base                            >= 4.9        && < 5\r\n    , ansi-terminal                   >= 0.6        && < 1.2\r\n    , async                           >= 2.0        && < 2.3\r\n    , barbies                         >= 1.0        && < 2.2\r\n    , bytestring                      >= 0.10       && < 0.13\r\n    , concurrent-output               >= 1.7        && < 1.11\r\n    , containers                      >= 0.4        && < 0.9\r\n    , deepseq                         >= 1.1.0.0    && < 1.6\r\n    , directory                       >= 1.2        && < 1.4\r\n    , erf                             >= 2.0        && < 2.1\r\n    , exceptions                      >= 0.7        && < 0.11\r\n    , lifted-async                    >= 0.7        && < 0.12\r\n    , mmorph                          >= 1.0        && < 1.3\r\n    , monad-control                   >= 1.0        && < 1.1\r\n    , mtl                             >= 2.1        && < 2.4\r\n    , pretty-show                     >= 1.6        && < 1.11\r\n    , primitive                       >= 0.6        && < 0.10\r\n    , random                          >= 1.1        && < 1.4\r\n    , resourcet                       >= 1.1        && < 1.4\r\n    , safe-exceptions                 >= 0.1        && < 0.2\r\n    , stm                             >= 2.4        && < 2.6\r\n    , template-haskell                >= 2.10       && < 2.25\r\n    , text                            >= 1.1        && < 2.2\r\n    , time                            >= 1.4        && < 1.16\r\n    , transformers                    >= 0.5        && < 0.7\r\n    , transformers-base               >= 0.4.5.1    && < 0.5\r\n    , wl-pprint-annotated             >= 0.0        && < 0.2\r\n\r\n  ghc-options:\r\n    -Wall\r\n\r\n  hs-source-dirs:\r\n    src\r\n\r\n  exposed-modules:\r\n    Hedgehog\r\n    Hedgehog.Gen\r\n    Hedgehog.Main\r\n    Hedgehog.Range\r\n\r\n    Hedgehog.Internal.Barbie\r\n    Hedgehog.Internal.Config\r\n    Hedgehog.Internal.Discovery\r\n    Hedgehog.Internal.Distributive\r\n    Hedgehog.Internal.Exception\r\n    Hedgehog.Internal.Gen\r\n    Hedgehog.Internal.HTraversable\r\n    Hedgehog.Internal.Opaque\r\n    Hedgehog.Internal.Prelude\r\n    Hedgehog.Internal.Property\r\n    Hedgehog.Internal.Queue\r\n    Hedgehog.Internal.Range\r\n    Hedgehog.Internal.Region\r\n    Hedgehog.Internal.Report\r\n    Hedgehog.Internal.Runner\r\n    Hedgehog.Internal.Seed\r\n    Hedgehog.Internal.Show\r\n    Hedgehog.Internal.Shrink\r\n    Hedgehog.Internal.Source\r\n    Hedgehog.Internal.State\r\n    Hedgehog.Internal.TH\r\n    Hedgehog.Internal.Tree\r\n    Hedgehog.Internal.Tripping\r\n\r\n  default-language:\r\n    Haskell2010\r\n\r\ntest-suite test\r\n  type:\r\n    exitcode-stdio-1.0\r\n\r\n  main-is:\r\n    test.hs\r\n\r\n  ghc-options:\r\n    -Wall -threaded -O2\r\n\r\n  hs-source-dirs:\r\n    test\r\n\r\n  other-modules:\r\n    Test.Hedgehog.Applicative\r\n    Test.Hedgehog.Confidence\r\n    Test.Hedgehog.Filter\r\n    Test.Hedgehog.Maybe\r\n    Test.Hedgehog.Seed\r\n    Test.Hedgehog.Skip\r\n    Test.Hedgehog.Text\r\n    Test.Hedgehog.Zip\r\n\r\n  build-depends:\r\n      hedgehog\r\n    , base                            >= 3          && < 5\r\n    , containers                      >= 0.4        && < 0.9\r\n    , mmorph                          >= 1.0        && < 1.3\r\n    , mtl                             >= 2.1        && < 2.4\r\n    , pretty-show                     >= 1.6        && < 1.11\r\n    , text                            >= 1.1        && < 2.2\r\n    , transformers                    >= 0.3        && < 0.7\r\n\r\n  default-language:\r\n    Haskell2010\r\n";
  }