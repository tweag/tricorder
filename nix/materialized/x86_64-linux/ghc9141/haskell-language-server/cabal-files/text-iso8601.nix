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
      identifier = { name = "text-iso8601"; version = "0.1.1.2"; };
      license = "BSD-3-Clause";
      copyright = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/haskell/aeson";
      url = "";
      synopsis = "Converting time to and from ISO 8601 text.";
      description = "Converting time to and from IS0 8601 text.\nSpecifically the [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339) profile.";
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
      url = "http://hackage.haskell.org/package/text-iso8601-0.1.1.2.tar.gz";
      sha256 = "ddbb13aec70a2fd54c7a25bf85e38a467d0d5599980d21f4925b3c706f8f7398";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               text-iso8601\nversion:            0.1.1.2\nsynopsis:           Converting time to and from ISO 8601 text.\ndescription:\n  Converting time to and from IS0 8601 text.\n  Specifically the [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339) profile.\n\nlicense:            BSD3\nlicense-file:       LICENSE\ncategory:           Parsing\ncopyright:          Oleg Grenrus <oleg.grenrus@iki.fi>\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:\n  Oleg Grenrus <oleg.grenrus@iki.fi>\n\nhomepage:           https://github.com/haskell/aeson\nbug-reports:        https://github.com/haskell/aeson/issues\nbuild-type:         Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.3\n   || ==9.12.4\n   || ==9.14.1\n\nextra-source-files: changelog.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/aeson.git\n  subdir:   text-iso8601\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  ghc-options:      -Wall\n  exposed-modules:\n    Data.Time.FromText\n    Data.Time.ToText\n\n  build-depends:\n      base                >=4.12.0.0 && <5\n    , integer-conversion  >=0.1      && <0.2\n    , text                >=1.2.3.0  && <1.3.0.0 || >=2.0 && <2.2\n    , time                >=1.8.0.2  && <1.16\n    , time-compat         >=1.9.4    && <1.10\n\ntest-suite text-iso8601-tests\n  default-language: Haskell2010\n  hs-source-dirs:   tests\n  type:             exitcode-stdio-1.0\n  main-is:          text-iso8601-tests.hs\n  ghc-options:      -Wall\n  build-depends:\n      base\n    , text\n    , text-iso8601\n    , time-compat\n\n  -- test dependencies\n  build-depends:\n      QuickCheck            >=2.14.3   && <2.19\n    , quickcheck-instances  >=0.3.29.1 && <0.5\n    , tasty                 >=1.4.3    && <1.6\n    , tasty-hunit           >=0.10.0.3 && <0.11\n    , tasty-quickcheck      >=0.10.2   && <0.12\n\nbenchmark text-iso8601-bench\n  default-language: Haskell2010\n  hs-source-dirs:   bench\n  type:             exitcode-stdio-1.0\n  main-is:          text-iso8601-bench.hs\n  ghc-options:      -Wall\n  build-depends:\n      base\n    , text\n    , text-iso8601\n\n  -- bench dependencies\n  build-depends:\n      attoparsec          >=0.14.4  && <0.15\n    , attoparsec-iso8601  >=1.1.0.1 && <1.2\n    , tasty-bench         >=0.3.4   && <0.5\n";
  }