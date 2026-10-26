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
      identifier = { name = "prometheus-client"; version = "1.1.2"; };
      license = "Apache-2.0";
      copyright = "2015 Will Coster";
      maintainer = "willcoster@gmail.com";
      author = "Will Coster";
      homepage = "https://github.com/fimad/prometheus-haskell";
      url = "";
      synopsis = "Haskell client library for http://prometheus.io.";
      description = "Haskell client library for http://prometheus.io.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
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
        "spec" = {
          depends = [
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."atomic-primops" or (errorHandler.buildDepError "atomic-primops"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."clock" or (errorHandler.buildDepError "clock"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."random-shuffle" or (errorHandler.buildDepError "random-shuffle"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."data-sketches" or (errorHandler.buildDepError "data-sketches"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/prometheus-client-1.1.2.tar.gz";
      sha256 = "ddcc10399bca1dac73e4dd7d4a7643fb956590f97276391706275fb8ce912477";
    });
  }) // {
    package-description-override = "name:                prometheus-client\nversion:             1.1.2\nsynopsis:            Haskell client library for http://prometheus.io.\ndescription:         Haskell client library for http://prometheus.io.\nhomepage:            https://github.com/fimad/prometheus-haskell\nlicense:             Apache-2.0\nlicense-file:        LICENSE\nauthor:              Will Coster\nmaintainer:          willcoster@gmail.com\ncopyright:           2015 Will Coster\ncategory:            Network\nbuild-type:          Simple\ncabal-version:       >=1.10\n\nsource-repository head\n  type:     git\n  location: https://github.com/fimad/prometheus-haskell\n\nlibrary\n  hs-source-dirs:      src/\n  default-language:    Haskell2010\n  exposed-modules:\n      Prometheus\n  other-modules:\n      Prometheus.Info\n    , Prometheus.Label\n    , Prometheus.Export.Text\n    , Prometheus.Metric\n    , Prometheus.Metric.Counter\n    , Prometheus.Metric.Gauge\n    , Prometheus.Metric.Histogram\n    , Prometheus.Metric.Observer\n    , Prometheus.Metric.Summary\n    , Prometheus.Metric.Vector\n    , Prometheus.MonadMonitor\n    , Prometheus.Registry\n  build-depends:\n      atomic-primops     >=0.4\n    , base               >=4.7 && <5\n    , bytestring         >=0.9\n    , clock\n    , containers\n    , deepseq\n    , primitive\n    , mtl                >=2\n    , stm                >=2.3\n    , transformers\n    , transformers-compat\n    , utf8-string\n    , exceptions\n    , text\n    , data-sketches      >= 0.4 && <0.5\n  ghc-options: -Wall\n\ntest-suite doctest\n  type:                 exitcode-stdio-1.0\n  default-language:     Haskell2010\n  hs-source-dirs:       tests\n  ghc-options:          -Wall\n  main-is:              doctest.hs\n  build-depends:\n      base               >=4.7 && <5\n    , doctest\n    , prometheus-client\n\ntest-suite spec\n  type:              exitcode-stdio-1.0\n  default-language:  Haskell2010\n  hs-source-dirs:    src, tests\n  main-is:           Spec.hs\n  build-depends:\n      QuickCheck\n    , atomic-primops\n    , base               >=4.7 && <5\n    , bytestring\n    , containers\n    , clock\n    , hspec\n    , mtl\n    , random-shuffle\n    , stm\n    , transformers\n    , transformers-compat\n    , utf8-string\n    , deepseq\n    , exceptions\n    , text\n    , primitive\n    , data-sketches      >= 0.4 && <0.5\n  ghc-options: -Wall\n\nbenchmark bench\n  type:             exitcode-stdio-1.0\n  default-language: Haskell2010\n  hs-source-dirs:   benchmarks\n  main-is:          Main.hs\n  build-depends:\n      base               >=4.7 && <5\n    , bytestring\n    , criterion          >=1.2\n    , prometheus-client\n    , random\n    , utf8-string\n    , text\n  ghc-options: -Wall\n";
  }