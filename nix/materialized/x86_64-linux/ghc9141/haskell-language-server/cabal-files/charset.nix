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
      identifier = { name = "charset"; version = "0.3.12"; };
      license = "BSD-3-Clause";
      copyright = "(c) Edward Kmett 2010-2012";
      maintainer = "ekmett@gmail.com";
      author = "Edward Kmett";
      homepage = "http://github.com/ekmett/charset";
      url = "";
      synopsis = "Fast unicode character sets based on complemented PATRICIA tries";
      description = "Fast unicode character sets based on complemented PATRICIA tries.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/charset-0.3.12.tar.gz";
      sha256 = "1ce8c6d444ae9d5685099fe118fda2744c4a6037559507d8213ff686dfca722d";
    });
  }) // {
    package-description-override = "name:          charset\nversion:       0.3.12\nlicense:       BSD3\nlicense-File:  LICENSE\ncopyright:     (c) Edward Kmett 2010-2012\nauthor:        Edward Kmett\nmaintainer:    ekmett@gmail.com\ncabal-version: >= 1.10\nstability:     Experimental\ncategory:      Data\nhomepage:      http://github.com/ekmett/charset\nbug-reports:   http://github.com/ekmett/charset/issues\nsynopsis:      Fast unicode character sets based on complemented PATRICIA tries\ndescription:   Fast unicode character sets based on complemented PATRICIA tries.\nbuild-type:    Simple\nextra-source-files: CHANGELOG.markdown, README.markdown\n\ntested-with:\n  GHC ==8.0.2\n   || ==8.2.2\n   || ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.1\n   || ==9.12.1\n\nsource-repository head\n  type: git\n  location: git://github.com/ekmett/charset.git\n\nlibrary\n  default-extensions: CPP\n  other-extensions: MagicHash, BangPatterns\n\n  build-depends:\n    base                 >= 4.9     && < 5,\n    array                >= 0.2     && < 0.6,\n    bytestring           >= 0.9     && < 0.13,\n    containers           >= 0.4.2.0 && < 0.9,\n    unordered-containers >= 0.1.4.6 && < 0.3\n\n  exposed-modules:\n    Data.CharSet\n    Data.CharSet.Common\n    Data.CharSet.Posix\n    Data.CharSet.Posix.Ascii\n    Data.CharSet.Posix.Unicode\n    Data.CharSet.Unicode\n    Data.CharSet.Unicode.Block\n    Data.CharSet.Unicode.Category\n    Data.CharSet.ByteSet\n\n  hs-source-dirs: src\n  ghc-options: -Wall -fspec-constr -fdicts-cheap -O2\n  default-language: Haskell2010\n";
  }