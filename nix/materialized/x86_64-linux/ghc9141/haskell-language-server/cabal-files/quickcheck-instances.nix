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
      specVersion = "2.2";
      identifier = { name = "quickcheck-instances"; version = "0.4"; };
      license = "BSD-3-Clause";
      copyright = "Copyright 2012-2016 Antoine Latter, 2017-2019 Oleg Grenrus";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Antoine Latter <aslatter@gmail.com>, Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/haskellari/qc-instances";
      url = "";
      synopsis = "Common quickcheck instances";
      description = "QuickCheck instances.\n\nThe goal is to supply QuickCheck instances for\ntypes provided by the Haskell Platform.\n\nSince all of these instances are provided as\norphans, I recommend that you do not use this library\nwithin another library module, so that you don't\nimpose these instances on down-stream consumers of\nyour code.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."splitmix" or (errorHandler.buildDepError "splitmix"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."data-fix" or (errorHandler.buildDepError "data-fix"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."integer-logarithms" or (errorHandler.buildDepError "integer-logarithms"))
          (hsPkgs."old-time" or (errorHandler.buildDepError "old-time"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."strict" or (errorHandler.buildDepError "strict"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          (hsPkgs."these" or (errorHandler.buildDepError "these"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.4") (hsPkgs."data-array-byte" or (errorHandler.buildDepError "data-array-byte"));
        buildable = true;
      };
      tests = {
        "self-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
          ] ++ pkgs.lib.optional (compiler.isGhc && (compiler.version.ge "8.0" && compiler.version.lt "9.4")) (hsPkgs."data-array-byte" or (errorHandler.buildDepError "data-array-byte"));
          buildable = true;
        };
      };
      benchmarks = {
        "bytestring-gen" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/quickcheck-instances-0.4.tar.gz";
      sha256 = "fb28fe2fce4e99c0a1d20ed15f6d6ecd56241c16e1a8e99ea166ea90e96727f3";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\r\nname:               quickcheck-instances\r\nversion:            0.4\r\nx-revision:         2\r\nsynopsis:           Common quickcheck instances\r\ndescription:\r\n  QuickCheck instances.\r\n  .\r\n  The goal is to supply QuickCheck instances for\r\n  types provided by the Haskell Platform.\r\n  .\r\n  Since all of these instances are provided as\r\n  orphans, I recommend that you do not use this library\r\n  within another library module, so that you don't\r\n  impose these instances on down-stream consumers of\r\n  your code.\r\n\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\nauthor:\r\n  Antoine Latter <aslatter@gmail.com>, Oleg Grenrus <oleg.grenrus@iki.fi>\r\n\r\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\r\nhomepage:           https://github.com/haskellari/qc-instances\r\nbug-reports:        https://github.com/haskellari/qc-instances/issues\r\ncopyright:          Copyright 2012-2016 Antoine Latter, 2017-2019 Oleg Grenrus\r\ncategory:           Testing\r\nbuild-type:         Simple\r\nextra-source-files: CHANGES\r\ntested-with:\r\n  GHC ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.7\r\n   || ==9.8.4\r\n   || ==9.10.2\r\n   || ==9.12.4\r\n   || ==9.14.1\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskellari/qc-instances.git\r\n\r\nlibrary\r\n  default-language:   Haskell2010\r\n  default-extensions:\r\n    BangPatterns\r\n    FlexibleContexts\r\n    FlexibleInstances\r\n    TypeOperators\r\n\r\n  exposed-modules:\r\n    Test.QuickCheck.Instances\r\n    Test.QuickCheck.Instances.Array\r\n    Test.QuickCheck.Instances.Array.Byte\r\n    Test.QuickCheck.Instances.ByteString\r\n    Test.QuickCheck.Instances.CaseInsensitive\r\n    Test.QuickCheck.Instances.Containers\r\n    Test.QuickCheck.Instances.DataFix\r\n    Test.QuickCheck.Instances.Hashable\r\n    Test.QuickCheck.Instances.Natural\r\n    Test.QuickCheck.Instances.OldTime\r\n    Test.QuickCheck.Instances.Primitive\r\n    Test.QuickCheck.Instances.Scientific\r\n    Test.QuickCheck.Instances.Semigroup\r\n    Test.QuickCheck.Instances.Solo\r\n    Test.QuickCheck.Instances.Strict\r\n    Test.QuickCheck.Instances.Tagged\r\n    Test.QuickCheck.Instances.Text\r\n    Test.QuickCheck.Instances.Text.Short\r\n    Test.QuickCheck.Instances.These\r\n    Test.QuickCheck.Instances.Time\r\n    Test.QuickCheck.Instances.Transformer\r\n    Test.QuickCheck.Instances.UnorderedContainers\r\n    Test.QuickCheck.Instances.UUID\r\n    Test.QuickCheck.Instances.Vector\r\n    Test.QuickCheck.Instances.Void\r\n\r\n  other-modules:      Test.QuickCheck.Instances.CustomPrelude\r\n  hs-source-dirs:     src\r\n  build-depends:\r\n    , base        >=4.12.0.0 && <4.23\r\n    , QuickCheck  >=2.17.1.0 && <2.18.1\r\n    , splitmix    >=0.1.3.2  && <0.2\r\n\r\n  build-depends:\r\n    , array                 >=0.5.4.0   && <0.6\r\n    , bytestring            >=0.10.12.0 && <0.13\r\n    , case-insensitive      >=1.2.0.11  && <1.3\r\n    , data-fix              >=0.3       && <0.4\r\n    , hashable              >=1.4.4.0   && <1.6\r\n    , integer-logarithms    >=1.0.3.1   && <1.1\r\n    , old-time              >=1.1.0.0   && <1.2\r\n    , scientific            >=0.3.8.0   && <0.4\r\n    , strict                >=0.5       && <0.6\r\n    , tagged                >=0.8.8     && <0.9\r\n    , text                  >=1.2.4.1   && <1.3  || >=2.0 && <2.2\r\n    , text-short            >=0.1.4     && <0.2\r\n    , these                 >=1.2.1     && <1.3\r\n    , time-compat           >=1.9.4     && <1.10\r\n    , transformers          >=0.5.6.2   && <0.7\r\n    , unordered-containers  >=0.2.20    && <0.3\r\n    , uuid-types            >=1.0.6     && <1.1\r\n    , vector                >=0.13.2.0  && <0.14\r\n\r\n  if impl(ghc <9.4)\r\n    build-depends: data-array-byte >=0.1.0.1 && <0.2\r\n\r\n  ghc-options:        -Wall\r\n\r\ntest-suite self-test\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          Tests.hs\r\n  hs-source-dirs:   test\r\n  build-depends:\r\n    , base\r\n    , containers\r\n    , primitive\r\n    , QuickCheck\r\n    , quickcheck-instances\r\n    , uuid-types\r\n\r\n  if impl(ghc >=8.0 && <9.4)\r\n    build-depends: data-array-byte\r\n\r\nbenchmark bytestring-gen\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  main-is:          ByteString.hs\r\n  hs-source-dirs:   bench\r\n  build-depends:\r\n    , base\r\n    , bytestring\r\n    , QuickCheck\r\n    , quickcheck-instances";
  }