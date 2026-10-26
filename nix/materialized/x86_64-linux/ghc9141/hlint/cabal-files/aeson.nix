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
    flags = { ordered-keymap = true; };
    package = {
      specVersion = "2.2";
      identifier = { name = "aeson"; version = "2.2.5.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2011-2016 Bryan O'Sullivan\n(c) 2011 MailRank, Inc.";
      maintainer = "Adam Bergmark <adam@bergmark.nl>";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "https://github.com/haskell/aeson";
      url = "";
      synopsis = "Fast JSON parsing and encoding";
      description = "A JSON parsing and encoding library optimized for ease of use\nand high performance.\n\nTo get started, see the documentation for the @Data.Aeson@ module\nbelow.\n\n(A note on naming: in Greek mythology, Aeson was the father of Jason.)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
          (hsPkgs."character-ps" or (errorHandler.buildDepError "character-ps"))
          (hsPkgs."data-fix" or (errorHandler.buildDepError "data-fix"))
          (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."indexed-traversable" or (errorHandler.buildDepError "indexed-traversable"))
          (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
          (hsPkgs."integer-logarithms" or (errorHandler.buildDepError "integer-logarithms"))
          (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
          (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."semialign" or (errorHandler.buildDepError "semialign"))
          (hsPkgs."strict" or (errorHandler.buildDepError "strict"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."text-iso8601" or (errorHandler.buildDepError "text-iso8601"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."these" or (errorHandler.buildDepError "these"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."witherable" or (errorHandler.buildDepError "witherable"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.4")) (hsPkgs."generically" or (errorHandler.buildDepError "generically"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.0")) (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"));
        buildable = true;
      };
      tests = {
        "aeson-tests" = {
          depends = ([
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base-compat" or (errorHandler.buildDepError "base-compat"))
            (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-fix" or (errorHandler.buildDepError "data-fix"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."generic-deriving" or (errorHandler.buildDepError "generic-deriving"))
            (hsPkgs."generically" or (errorHandler.buildDepError "generically"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."indexed-traversable" or (errorHandler.buildDepError "indexed-traversable"))
            (hsPkgs."integer-logarithms" or (errorHandler.buildDepError "integer-logarithms"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
            (hsPkgs."strict" or (errorHandler.buildDepError "strict"))
            (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-golden" or (errorHandler.buildDepError "tasty-golden"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
            (hsPkgs."these" or (errorHandler.buildDepError "these"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."time-compat" or (errorHandler.buildDepError "time-compat"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.0")) (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp"))) ++ pkgs.lib.optional (compiler.isGhc && (compiler.version.ge "9.2" && compiler.version.lt "9.7")) (hsPkgs."nothunks" or (errorHandler.buildDepError "nothunks"));
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/aeson-2.2.5.1.tar.gz";
      sha256 = "ea82d650c0bbd8877dbf13a03b9baae3be7ed4a65f4e8cfe5b4eacb4f5beae75";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               aeson\nversion:            2.2.5.1\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Text, Web, JSON\ncopyright:\n  (c) 2011-2016 Bryan O'Sullivan\n  (c) 2011 MailRank, Inc.\n\nauthor:             Bryan O'Sullivan <bos@serpentine.com>\nmaintainer:         Adam Bergmark <adam@bergmark.nl>\nstability:          experimental\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.3\n   || ==9.12.4\n   || ==9.14.1\n\nsynopsis:           Fast JSON parsing and encoding\nhomepage:           https://github.com/haskell/aeson\nbug-reports:        https://github.com/haskell/aeson/issues\nbuild-type:         Simple\ndescription:\n  A JSON parsing and encoding library optimized for ease of use\n  and high performance.\n  .\n  To get started, see the documentation for the @Data.Aeson@ module\n  below.\n  .\n  (A note on naming: in Greek mythology, Aeson was the father of Jason.)\n\nextra-source-files:\n  *.yaml\n  benchmarks/json-data/*.json\n  changelog.md\n  README.markdown\n  tests/golden/*.expected\n  tests/JSONTestSuite/results/*.tok\n  tests/JSONTestSuite/results/*.txt\n  tests/JSONTestSuite/test_parsing/*.json\n  tests/JSONTestSuite/test_transform/*.json\n\nflag ordered-keymap\n  description: Use ordered @Data.Map.Strict@ for KeyMap implementation.\n  default:     True\n  manual:      True\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  exposed-modules:\n    Data.Aeson\n    Data.Aeson.Decoding\n    Data.Aeson.Decoding.ByteString\n    Data.Aeson.Decoding.ByteString.Lazy\n    Data.Aeson.Decoding.Text\n    Data.Aeson.Decoding.Tokens\n    Data.Aeson.Encoding\n    Data.Aeson.Encoding.Internal\n    Data.Aeson.Key\n    Data.Aeson.KeyMap\n    Data.Aeson.QQ.Simple\n    Data.Aeson.RFC8785\n    Data.Aeson.Text\n    Data.Aeson.TH\n    Data.Aeson.Types\n\n  other-modules:\n    Data.Aeson.Decoding.Conversion\n    Data.Aeson.Decoding.Internal\n    Data.Aeson.Encoding.Builder\n    Data.Aeson.Internal.ByteString\n    Data.Aeson.Internal.Functions\n    Data.Aeson.Internal.Prelude\n    Data.Aeson.Internal.Scientific\n    Data.Aeson.Internal.Text\n    Data.Aeson.Internal.TH\n    Data.Aeson.Internal.Unescape\n    Data.Aeson.Internal.UnescapeFromText\n    Data.Aeson.Parser.Time\n    Data.Aeson.Types.Class\n    Data.Aeson.Types.FromJSON\n    Data.Aeson.Types.Generic\n    Data.Aeson.Types.Internal\n    Data.Aeson.Types.ToJSON\n\n  -- GHC bundled libs\n  build-depends:\n    , base              >=4.12.0.0 && <5\n    , bytestring        >=0.10.8.2 && <0.13\n    , containers        >=0.6.0.1  && <0.9\n    , deepseq           >=1.4.4.0  && <1.6\n    , exceptions        >=0.10.4   && <0.11\n    , template-haskell  >=2.14.0.0 && <2.25\n    , text              >=1.2.3.0  && <1.3  || >=2.0 && <2.2\n    , time              >=1.8.0.2  && <1.16\n\n  -- Compat\n  build-depends:\n    , time-compat  >=1.9.6 && <1.10\n\n  if !impl(ghc >=9.4)\n    build-depends: generically >=0.1 && <0.2\n\n  if !impl(ghc >=9.0)\n    build-depends: integer-gmp\n\n  -- Other dependencies\n  build-depends:\n    , character-ps          ^>=0.1\n    , data-fix              ^>=0.3.2\n    , dlist                 ^>=1.0\n    , hashable              ^>=1.4.6.0  || ^>=1.5.0.0\n    , indexed-traversable   ^>=0.1.2\n    , integer-conversion    ^>=0.1\n    , integer-logarithms    ^>=1.0.3.1\n    , network-uri           ^>=2.6.4.1\n    , OneTuple              ^>=0.4.1.1\n    , primitive             ^>=0.8.0.0  || ^>=0.9.0.0\n    , QuickCheck            ^>=2.14.3   || ^>=2.15    || ^>=2.16.0.0 || ^>=2.17.1.0 || ^>=2.18.0.0\n    , scientific            ^>=0.3.7.0\n    , semialign             ^>=1.3      || ^>=1.4\n    , strict                ^>=0.5\n    , tagged                ^>=0.8.7\n    , text-iso8601          ^>=0.1.1\n    , text-short            ^>=0.1.5\n    , th-abstraction        ^>=0.5.0.0  || ^>=0.6.0.0 || ^>=0.7.0.0\n    , these                 ^>=1.2\n    , unordered-containers  ^>=0.2.10.0\n    , uuid-types            ^>=1.0.5\n    , vector                ^>=0.13.0.0\n    , witherable            ^>=0.4.2    || ^>=0.5\n\n  ghc-options:      -Wall\n\n  -- String unescaping\n\n  if flag(ordered-keymap)\n    cpp-options: -DUSE_ORDEREDMAP=1\n\ntest-suite aeson-tests\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   tests\n  main-is:          Tests.hs\n  ghc-options:      -Wall -threaded -rtsopts\n  other-modules:\n    CastFloat\n    DataFamilies.Encoders\n    DataFamilies.Instances\n    DataFamilies.Properties\n    DataFamilies.Types\n    DoubleToScientific\n    Encoders\n    ErrorMessages\n    Functions\n    Instances\n    JSONTestSuite\n    Options\n    Properties\n    PropertyGeneric\n    PropertyKeys\n    PropertyQC\n    PropertyRoundTrip\n    PropertyRTFunctors\n    PropertyTH\n    PropUtils\n    Regression.Issue351\n    Regression.Issue571\n    Regression.Issue687\n    Regression.Issue967\n    Regression.Issue1138\n    RFC8785\n    SerializationFormatSpec\n    Types\n    UnitTests\n    UnitTests.FromJSONKey\n    UnitTests.Hashable\n    UnitTests.KeyMapInsertWith\n    UnitTests.MonadFix\n    UnitTests.NoThunks\n    UnitTests.NullaryConstructors\n    UnitTests.OmitNothingFieldsNote\n    UnitTests.OptionalFields\n    UnitTests.OptionalFields.Common\n    UnitTests.OptionalFields.Generics\n    UnitTests.OptionalFields.Manual\n    UnitTests.OptionalFields.TH\n    UnitTests.UTCTime\n\n  build-depends:\n    , aeson\n    , base\n    , base-compat\n    , base-orphans          >=0.5.3  && <0.10\n    , base16-bytestring\n    , bytestring\n    , containers\n    , data-fix\n    , Diff                  >=0.4    && <0.6  || ^>=1.0.2\n    , directory\n    , dlist\n    , filepath\n    , generic-deriving      >=1.10   && <1.15\n    , generically\n    , hashable\n    , indexed-traversable\n    , integer-logarithms    >=1      && <1.1\n    , network-uri\n    , OneTuple\n    , QuickCheck\n    , quickcheck-instances  >=0.3.29 && <0.5\n    , scientific\n    , strict\n    , tagged\n    , tasty\n    , tasty-golden\n    , tasty-hunit\n    , tasty-quickcheck\n    , text\n    , text-short\n    , these\n    , time\n    , time-compat\n    , unordered-containers\n    , uuid-types\n    , vector\n\n  if !impl(ghc >=9.0)\n    build-depends: integer-gmp\n\n  if impl(ghc >=9.2 && <9.7)\n    build-depends: nothunks >=0.1.4 && <0.3\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/aeson.git\n";
  }