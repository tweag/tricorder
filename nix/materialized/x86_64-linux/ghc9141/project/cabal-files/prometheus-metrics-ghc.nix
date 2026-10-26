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
      identifier = { name = "prometheus-metrics-ghc"; version = "1.0.1.2"; };
      license = "Apache-2.0";
      copyright = "2015 Will Coster";
      maintainer = "willcoster@gmail.com";
      author = "Will Coster";
      homepage = "https://github.com/fimad/prometheus-haskell";
      url = "";
      synopsis = "Metrics exposing GHC runtime information for use with prometheus-client.";
      description = "Metrics exposing GHC runtime information for use with prometheus-client.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/prometheus-metrics-ghc-1.0.1.2.tar.gz";
      sha256 = "f3dfa40b881647bc4c0b3a2f2be633a457c76f59d4bc77a12e46fa643981ea1a";
    });
  }) // {
    package-description-override = "name:                prometheus-metrics-ghc\nversion:             1.0.1.2\nsynopsis:\n    Metrics exposing GHC runtime information for use with prometheus-client.\ndescription:\n    Metrics exposing GHC runtime information for use with prometheus-client.\nhomepage:            https://github.com/fimad/prometheus-haskell\nlicense:             Apache-2.0\nlicense-file:        LICENSE\nauthor:              Will Coster\nmaintainer:          willcoster@gmail.com\ncopyright:           2015 Will Coster\ncategory:            Network\nbuild-type:          Simple\ncabal-version:       >=1.10\n\nsource-repository head\n  type:     git\n  location: https://github.com/fimad/prometheus-haskell\n\nlibrary\n  hs-source-dirs:      src/\n  default-language:    Haskell2010\n  exposed-modules:\n      Prometheus.Metric.GHC\n  build-depends:\n      base               >=4.7 && <5\n    , prometheus-client  >=1.0.0 && <1.2\n    , utf8-string        >=0.3\n    , text\n  ghc-options: -Wall\n\ntest-suite doctest\n  type:                 exitcode-stdio-1.0\n  default-language:     Haskell2010\n  hs-source-dirs:       tests\n  ghc-options:          -Wall\n  main-is:              doctest.hs\n  build-depends:\n      base               >=4.7 && <5\n    , doctest\n    , prometheus-client\n";
  }