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
      identifier = { name = "attoparsec-aeson"; version = "2.2.2.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2011-2016 Bryan O'Sullivan\n(c) 2011 MailRank, Inc.";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Bryan O'Sullivan <bos@serpentine.com>";
      homepage = "https://github.com/haskell/aeson";
      url = "";
      synopsis = "Parsing of aeson's Value with attoparsec";
      description = "Parsing of aeson's Value with attoparsec, originally from aeson.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."attoparsec" or (errorHandler.buildDepError "attoparsec"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."character-ps" or (errorHandler.buildDepError "character-ps"))
          (hsPkgs."integer-conversion" or (errorHandler.buildDepError "integer-conversion"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/attoparsec-aeson-2.2.2.0.tar.gz";
      sha256 = "fe9b2c23a16fe1ff8f41c329940cccc80aca7ac6a9ea314f7a77cf142d8f9edd";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\r\nname:          attoparsec-aeson\r\nversion:       2.2.2.0\r\nx-revision: 1\r\nsynopsis:      Parsing of aeson's Value with attoparsec\r\ndescription:\r\n  Parsing of aeson's Value with attoparsec, originally from aeson.\r\n\r\nlicense:       BSD-3-Clause\r\nlicense-file:  LICENSE\r\ncategory:      Parsing\r\ncopyright:\r\n  (c) 2011-2016 Bryan O'Sullivan\r\n  (c) 2011 MailRank, Inc.\r\n\r\nauthor:        Bryan O'Sullivan <bos@serpentine.com>\r\nmaintainer:    Oleg Grenrus <oleg.grenrus@iki.fi>\r\nstability:     experimental\r\nhomepage:      https://github.com/haskell/aeson\r\nbug-reports:   https://github.com/haskell/aeson/issues\r\nbuild-type:    Simple\r\ntested-with:\r\n  GHC ==8.6.5\r\n   || ==8.8.4\r\n   || ==8.10.7\r\n   || ==9.0.2\r\n   || ==9.2.8\r\n   || ==9.4.8\r\n   || ==9.6.5\r\n   || ==9.8.2\r\n   || ==9.10.1\r\n\r\nlibrary\r\n  hs-source-dirs:   src\r\n  default-language: Haskell2010\r\n  ghc-options:      -Wall\r\n  exposed-modules:\r\n    Data.Aeson.Parser\r\n    Data.Aeson.Parser.Internal\r\n\r\n  other-modules:\r\n    Data.Aeson.Internal.ByteString\r\n    Data.Aeson.Internal.Text\r\n\r\n  build-depends:\r\n    , aeson               >=2.2.2.0  && <2.4\r\n    , attoparsec          >=0.14.2   && <0.15\r\n    , base                >=4.12.0.0 && <5\r\n    , bytestring          >=0.10.8.2 && <0.13\r\n    , character-ps        ^>=0.1\r\n    , integer-conversion  >=0.1      && <0.2\r\n    , primitive           >=0.8.0.0  && <0.10\r\n    , scientific          >=0.3.7.0  && <0.4\r\n    , text                >=1.2.3.0  && <1.3  || >=2.0 && <2.2\r\n    , vector              >=0.12.0.1 && <0.14\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/haskell/aeson.git\r\n  subdir:   attoparsec-aeson\r\n";
  }