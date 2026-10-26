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
      specVersion = "1.12";
      identifier = { name = "text-iso8601"; version = "0.2.0.0"; };
      license = "BSD-3-Clause";
      copyright = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/haskell/aeson";
      url = "";
      synopsis = "Converting time to and from ISO 8601 text.";
      description = "Converting time to and from ISO 8601 text.\nSpecifically the [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339) profile.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
        ];
        buildable = true;
      };
      tests = {
        "text-iso8601-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-iso8601" or (errorHandler.buildDepError "text-iso8601"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "text-iso8601-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-iso8601" or (errorHandler.buildDepError "text-iso8601"))
            (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
            (hsPkgs."attoparsec-iso8601" or (errorHandler.buildDepError "attoparsec-iso8601"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-iso8601-0.2.0.0.tar.gz";
      sha256 = "d5271d05477bd946d62b31adf4bb6eb3d963c13581c67e7e57d2e2bdffcbe4ee";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\r\nname:               text-iso8601\r\nversion:            0.2.0.0\r\nx-revision: 1\r\nsynopsis:           Converting time to and from ISO 8601 text.\r\ndescription:\r\n  Converting time to and from ISO 8601 text.\r\n  Specifically the [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339) profile.\r\n\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncategory:           Parsing\r\ncopyright:          Oleg Grenrus <oleg.grenrus@iki.fi>\r\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\r\nmaintainer:\r\n  Oleg Grenrus <oleg.grenrus@iki.fi>\r\n\r\nhomepage:           https://github.com/haskell/aeson\r\nbug-reports:        https://github.com/haskell/aeson/issues\r\nbuild-type:         Simple\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.6\r\n   || ==9.8.4\r\n   || ==9.10.3\r\n   || ==9.12.4\r\n   || ==9.14.1\r\n\r\nextra-source-files: changelog.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/aeson.git\r\n  subdir:   text-iso8601\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   src\r\n  ghc-options:      -Wall\r\n  exposed-modules:\r\n    Data.Time.FromText\r\n    Data.Time.ToText\r\n\r\n  build-depends:\r\n      base                >=4.12.0.0 && <5\r\n    , integer-conversion  >=0.1      && <0.2\r\n    , text                >=1.2.3.0  && <1.3.0.0 || >=2.0 && <2.2\r\n    , time                >=1.8.0.2  && <1.16\r\n    , time-compat         >=1.9.4    && <1.10\r\n\r\ntest-suite text-iso8601-tests\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   tests\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          text-iso8601-tests.hs\r\n  ghc-options:      -Wall\r\n  build-depends:\r\n      base\r\n    , text\r\n    , text-iso8601\r\n    , time-compat\r\n\r\n  -- test dependencies\r\n  build-depends:\r\n      QuickCheck            >=2.14.3   && <2.20\r\n    , quickcheck-instances  >=0.3.29.1 && <0.5\r\n    , tasty                 >=1.4.3    && <1.6\r\n    , tasty-hunit           >=0.10.0.3 && <0.11\r\n    , tasty-quickcheck      >=0.10.2   && <0.12\r\n\r\nbenchmark text-iso8601-bench\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   bench\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          text-iso8601-bench.hs\r\n  ghc-options:      -Wall\r\n  build-depends:\r\n      base\r\n    , text\r\n    , text-iso8601\r\n\r\n  -- bench dependencies\r\n  build-depends:\r\n      attoparsec          >=0.14.4  && <0.15\r\n    , attoparsec-iso8601  >=1.1.0.1 && <1.2\r\n    , tasty-bench         >=0.3.4   && <0.5\r\n";
  }