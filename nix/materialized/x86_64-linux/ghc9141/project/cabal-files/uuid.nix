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
      identifier = { name = "uuid"; version = "1.3.16.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2008-2014 Antoine Latter";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Antoine Latter";
      homepage = "https://github.com/haskell-hvr/uuid";
      url = "";
      synopsis = "For creating, comparing, parsing and printing Universally Unique Identifiers";
      description = "This library is useful for creating, comparing, parsing and\nprinting Universally Unique Identifiers.\n\nSee <http://en.wikipedia.org/wiki/UUID> for the general idea.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."cryptohash-md5" or (errorHandler.buildDepError "cryptohash-md5"))
          (hsPkgs."cryptohash-sha1" or (errorHandler.buildDepError "cryptohash-sha1"))
          (hsPkgs."entropy" or (errorHandler.buildDepError "entropy"))
          (hsPkgs."network-info" or (errorHandler.buildDepError "network-info"))
          (hsPkgs."random" or (errorHandler.buildDepError "random"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."uuid-types" or (errorHandler.buildDepError "uuid-types"))
        ];
        buildable = true;
      };
      tests = {
        "test-uuid" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/uuid-1.3.16.1.tar.gz";
      sha256 = "f3af761ea0d332cbfe8d163f1418429d2dca78bc6b4e5b81cf9643d5886cb113";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               uuid\nversion:            1.3.16.1\ncopyright:          (c) 2008-2014 Antoine Latter\nauthor:             Antoine Latter\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nlicense:            BSD3\nlicense-file:       LICENSE\ncategory:           Data\nbuild-type:         Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.4\n   || ==9.14.1\n\nsynopsis:\n  For creating, comparing, parsing and printing Universally Unique Identifiers\n\ndescription:\n  This library is useful for creating, comparing, parsing and\n  printing Universally Unique Identifiers.\n  .\n  See <http://en.wikipedia.org/wiki/UUID> for the general idea.\n\nhomepage:           https://github.com/haskell-hvr/uuid\nbug-reports:        https://github.com/haskell-hvr/uuid/issues\nextra-source-files: CHANGES.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-hvr/uuid.git\n  subdir:   uuid\n\nlibrary\n  build-depends:\n      base             >=4.12     && <5\n    , binary           >=0.8.6.0  && <0.9\n    , bytestring       >=0.10.8.2 && <0.13\n    , cryptohash-md5   >=0.11.100 && <0.12\n    , cryptohash-sha1  >=0.11.100 && <0.12\n    , entropy          >=0.3.7    && <0.5\n    , network-info     >=0.2      && <0.3\n    , random           >=1.2.1.2  && <1.4\n    , time             >=1.4      && <1.16\n\n  -- strict dependency on uuid-types,\n  -- as we re-rexport datatype, thus leak instances etc.\n  build-depends:      uuid-types >=1.0.6 && <1.0.7\n  exposed-modules:\n    Data.UUID\n    Data.UUID.Util\n    Data.UUID.V1\n    Data.UUID.V3\n    Data.UUID.V4\n    Data.UUID.V5\n\n  other-modules:\n    Data.UUID.Named\n    Data.Word.Util\n\n  default-language:   Haskell2010\n  default-extensions: DeriveDataTypeable\n  other-extensions:   TypeFamilies\n  ghc-options:        -Wall\n  hs-source-dirs:     src\n\ntest-suite test-uuid\n  type:               exitcode-stdio-1.0\n  main-is:            TestUUID.hs\n  hs-source-dirs:     tests\n  default-language:   Haskell2010\n  default-extensions: DeriveDataTypeable\n  other-extensions:   ViewPatterns\n  ghc-options:        -Wall -fno-warn-orphans\n\n  -- inherited constraints\n  build-depends:\n      base\n    , bytestring\n    , uuid\n\n  -- deps w/o inherited constraints\n  build-depends:\n      QuickCheck        >=2.14.2  && <2.16\n    , tasty             >=1.4.0.1 && <1.6\n    , tasty-hunit       >=0.10    && <0.11\n    , tasty-quickcheck  >=0.10    && <0.12\n";
  }