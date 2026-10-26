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
      identifier = { name = "aeson"; version = "2.3.2.0"; };
      license = "BSD-3-Clause";
      copyright = "2014-2026 Aeson project contributors,\n2011-2016 Bryan O'Sullivan,\n2011 MailRank, Inc.";
      maintainer = "Li-yao Xia <lysxia@gmail.com>,\nCore Libraries Committee";
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
      url = "http://hackage.haskell.org/package/aeson-2.3.2.0.tar.gz";
      sha256 = "c30d187d60fb81b0f93f72442ee6b1abd2709fc3b5e3befcf4173f6b30983458";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\r\nname:               aeson\r\nversion:            2.3.2.0\r\nx-revision: 1\r\nlicense:            BSD-3-Clause\r\nlicense-file:       LICENSE\r\ncategory:           Text, Web, JSON\r\ncopyright:\r\n  2014-2026 Aeson project contributors,\r\n  2011-2016 Bryan O'Sullivan,\r\n  2011 MailRank, Inc.\r\nauthor:             Bryan O'Sullivan <bos@serpentine.com>\r\nmaintainer:\r\n  Li-yao Xia <lysxia@gmail.com>,\r\n  Core Libraries Committee\r\nstability:          stable\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.6\r\n   || ==9.8.4\r\n   || ==9.10.3\r\n   || ==9.12.4\r\n   || ==9.14.1\r\n\r\nsynopsis:           Fast JSON parsing and encoding\r\nhomepage:           https://github.com/haskell/aeson\r\nbug-reports:        https://github.com/haskell/aeson/issues\r\nbuild-type:         Simple\r\ndescription:\r\n  A JSON parsing and encoding library optimized for ease of use\r\n  and high performance.\r\n  .\r\n  To get started, see the documentation for the @Data.Aeson@ module\r\n  below.\r\n  .\r\n  (A note on naming: in Greek mythology, Aeson was the father of Jason.)\r\nextra-doc-files:\r\n  README.markdown\r\n  changelog.md\r\nextra-source-files:\r\n  *.yaml\r\n  benchmarks/json-data/*.json\r\n  tests/golden/*.expected\r\n  tests/JSONTestSuite/results/*.tok\r\n  tests/JSONTestSuite/results/*.txt\r\n  tests/JSONTestSuite/test_parsing/*.json\r\n  tests/JSONTestSuite/test_transform/*.json\r\n\r\nflag ordered-keymap\r\n  description: Use ordered @Data.Map.Strict@ for KeyMap implementation.\r\n  default:     True\r\n  manual:      True\r\n\r\nlibrary\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   src\r\n  exposed-modules:\r\n    Data.Aeson\r\n    Data.Aeson.Decoding\r\n    Data.Aeson.Decoding.ByteString\r\n    Data.Aeson.Decoding.ByteString.Lazy\r\n    Data.Aeson.Decoding.Text\r\n    Data.Aeson.Decoding.Tokens\r\n    Data.Aeson.Encoding\r\n    Data.Aeson.Encoding.Internal\r\n    Data.Aeson.Key\r\n    Data.Aeson.KeyMap\r\n    Data.Aeson.QQ.Simple\r\n    Data.Aeson.RFC8785\r\n    Data.Aeson.Text\r\n    Data.Aeson.TH\r\n    Data.Aeson.Types\r\n\r\n  other-modules:\r\n    Data.Aeson.Decoding.Conversion\r\n    Data.Aeson.Decoding.Internal\r\n    Data.Aeson.Encoding.Builder\r\n    Data.Aeson.Internal.ByteString\r\n    Data.Aeson.Internal.Functions\r\n    Data.Aeson.Internal.Prelude\r\n    Data.Aeson.Internal.Scientific\r\n    Data.Aeson.Internal.Text\r\n    Data.Aeson.Internal.TH\r\n    Data.Aeson.Internal.Unescape\r\n    Data.Aeson.Internal.UnescapeFromText\r\n    Data.Aeson.Parser.Time\r\n    Data.Aeson.Types.Class\r\n    Data.Aeson.Types.FromJSON\r\n    Data.Aeson.Types.Generic\r\n    Data.Aeson.Types.Internal\r\n    Data.Aeson.Types.ToJSON\r\n\r\n  -- GHC bundled libs\r\n  build-depends:\r\n    , base              >=4.12.0.0 && <5\r\n    , bytestring        >=0.10.8.2 && <0.13\r\n    , containers        >=0.6.0.1  && <0.9\r\n    , deepseq           >=1.4.4.0  && <1.6\r\n    , exceptions        >=0.10.4   && <0.11\r\n    , template-haskell  >=2.14.0.0 && <2.25\r\n    , text              >=1.2.3.0  && <1.3  || >=2.0 && <2.2\r\n    , time              >=1.8.0.2  && <1.16\r\n\r\n  -- Compat\r\n  build-depends:\r\n    , time-compat  >=1.9.6 && <1.10\r\n\r\n  if !impl(ghc >=9.4)\r\n    build-depends: generically >=0.1 && <0.2\r\n\r\n  if !impl(ghc >=9.0)\r\n    build-depends: integer-gmp\r\n\r\n  -- Other dependencies\r\n  build-depends:\r\n    , character-ps          ^>=0.1\r\n    , data-fix              ^>=0.3.2\r\n    , dlist                 ^>=1.0\r\n    , hashable              ^>=1.4.6.0  || ^>=1.5.0.0\r\n    , indexed-traversable   ^>=0.1.2\r\n    , integer-conversion    ^>=0.1\r\n    , integer-logarithms    ^>=1.0.3.1\r\n    , network-uri           ^>=2.6.4.1\r\n    , OneTuple              ^>=0.4.1.1\r\n    , primitive             ^>=0.8.0.0  || ^>=0.9.0.0\r\n    , QuickCheck            ^>=2.14.3   || ^>=2.15    || ^>=2.16.0.0 || ^>=2.17.1.0 || ^>=2.18.0.0 || ^>= 2.19.0.0\r\n    , scientific            ^>=0.3.7.0\r\n    , semialign             ^>=1.3      || ^>=1.4\r\n    , strict                ^>=0.5\r\n    , tagged                ^>=0.8.7\r\n    , text-iso8601          >=0.1.1 && < 0.3\r\n    , text-short            ^>=0.1.5\r\n    , th-abstraction        ^>=0.5.0.0  || ^>=0.6.0.0 || ^>=0.7.0.0\r\n    , these                 ^>=1.2\r\n    , unordered-containers  ^>=0.2.10.0\r\n    , uuid-types            ^>=1.0.5\r\n    , vector                ^>=0.13.0.0\r\n    , witherable            ^>=0.4.2    || ^>=0.5\r\n\r\n  ghc-options:      -Wall\r\n\r\n  -- String unescaping\r\n\r\n  if flag(ordered-keymap)\r\n    cpp-options: -DUSE_ORDEREDMAP=1\r\n\r\ntest-suite aeson-tests\r\n  default-language: Haskell2010\r\n  type:             exitcode-stdio-1.0\r\n  hs-source-dirs:   tests\r\n  main-is:          Tests.hs\r\n  ghc-options:      -Wall -threaded -rtsopts\r\n  other-modules:\r\n    CastFloat\r\n    DataFamilies.Encoders\r\n    DataFamilies.Instances\r\n    DataFamilies.Properties\r\n    DataFamilies.Types\r\n    DoubleToScientific\r\n    Encoders\r\n    ErrorMessages\r\n    Functions\r\n    Instances\r\n    JSONTestSuite\r\n    Options\r\n    Properties\r\n    PropertyGeneric\r\n    PropertyKeys\r\n    PropertyQC\r\n    PropertyRoundTrip\r\n    PropertyRTFunctors\r\n    PropertyTH\r\n    PropUtils\r\n    Regression.Issue351\r\n    Regression.Issue571\r\n    Regression.Issue687\r\n    Regression.Issue967\r\n    Regression.Issue1138\r\n    RFC8785\r\n    SerializationFormatSpec\r\n    Types\r\n    UnitTests\r\n    UnitTests.FromJSONKey\r\n    UnitTests.Hashable\r\n    UnitTests.KeyMapInsertWith\r\n    UnitTests.MonadFix\r\n    UnitTests.NoThunks\r\n    UnitTests.NullaryConstructors\r\n    UnitTests.OmitNothingFieldsNote\r\n    UnitTests.OptionalFields\r\n    UnitTests.OptionalFields.Common\r\n    UnitTests.OptionalFields.Generics\r\n    UnitTests.OptionalFields.Manual\r\n    UnitTests.OptionalFields.TH\r\n    UnitTests.UTCTime\r\n\r\n  build-depends:\r\n    , aeson\r\n    , base\r\n    , base-compat\r\n    , base-orphans          >=0.5.3  && <0.10\r\n    , base16-bytestring\r\n    , bytestring\r\n    , containers\r\n    , data-fix\r\n    , Diff                  >=0.4    && <0.6  || ^>=1.0.2\r\n    , directory\r\n    , dlist\r\n    , filepath\r\n    , generic-deriving      >=1.10   && <1.15\r\n    , generically\r\n    , hashable\r\n    , indexed-traversable\r\n    , integer-logarithms    >=1      && <1.1\r\n    , network-uri\r\n    , OneTuple\r\n    , QuickCheck\r\n    , quickcheck-instances  >=0.3.29 && <0.5\r\n    , scientific\r\n    , strict\r\n    , tagged\r\n    , tasty\r\n    , tasty-golden\r\n    , tasty-hunit\r\n    , tasty-quickcheck\r\n    , text\r\n    , text-short\r\n    , these\r\n    , time\r\n    , time-compat\r\n    , unordered-containers\r\n    , uuid-types\r\n    , vector\r\n\r\n  if !impl(ghc >=9.0)\r\n    build-depends: integer-gmp\r\n\r\n  if impl(ghc >=9.2 && <9.7)\r\n    build-depends: nothunks >=0.1.4 && <0.4\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/aeson.git\r\n";
  }