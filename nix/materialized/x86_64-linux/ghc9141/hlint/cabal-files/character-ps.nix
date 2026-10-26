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
      identifier = { name = "character-ps"; version = "0.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/phadej/character-ps";
      url = "";
      synopsis = "Pattern synonyms for ASCII characters for Word8, Word16 etc";
      description = "Pattern synonyms for ASCII characters, e.g.\n\n@\npattern SPACE :: Word8\npattern SPACE = 0x20\n@";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "character-ps-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."character-ps" or (errorHandler.buildDepError "character-ps"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/character-ps-0.1.tar.gz";
      sha256 = "22de71fde38b236d3e9168a832b5e1e75d1fb4f4028667bdf747b3b4c8c1529c";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname:          character-ps\nversion:       0.1\nsynopsis:      Pattern synonyms for ASCII characters for Word8, Word16 etc\ndescription:\n  Pattern synonyms for ASCII characters, e.g.\n  .\n  @\n  pattern SPACE :: Word8\n  pattern SPACE = 0x20\n  @\n\nhomepage:      https://github.com/phadej/character-ps\nbug-reports:   https://github.com/phadej/character-ps/issues\nlicense:       BSD-3-Clause\nlicense-file:  LICENSE\nauthor:        Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:    Oleg Grenrus <oleg.grenrus@iki.fi>\ncategory:      Data\nbuild-type:    Simple\ntested-with:\n  GHC ==8.0.2\n   || ==8.2.2\n   || ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.7\n   || ==9.6.3\n   || ==9.8.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/character-ps.git\n\ncommon language\n  default-language:   Haskell2010\n  default-extensions: PatternSynonyms\n\nlibrary\n  import:          language\n  hs-source-dirs:  src\n  exposed-modules:\n    Data.Char.Patterns\n    Data.Word16.Patterns\n    Data.Word8.Patterns\n\n  build-depends:   base >=4.9 && <5\n\ntest-suite character-ps-tests\n  import:         language\n  hs-source-dirs: tests\n  main-is:        character-ps-tests.hs\n  type:           exitcode-stdio-1.0\n  build-depends:\n    , base\n    , character-ps\n";
  }