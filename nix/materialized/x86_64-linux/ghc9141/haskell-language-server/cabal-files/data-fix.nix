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
      identifier = { name = "data-fix"; version = "0.3.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "<anton.kholomiov@gmail.com>";
      author = "Anton Kholomiov, Edward Kmett, Oleg Grenrus";
      homepage = "https://github.com/spell-music/data-fix";
      url = "";
      synopsis = "Fixpoint data types";
      description = "Fixpoint types and recursion schemes. If you define your AST as\nfixpoint type, you get fold and unfold operations for free.\n\nThanks for contribution to: Matej Kollar, Herbert Valerio Riedel";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-fix-0.3.4.tar.gz";
      sha256 = "8df052d18c047ab9e9200536a8799b5af3997ebecbbb091a7384b6be8416ab37";
    });
  }) // {
    package-description-override = "cabal-version:   2.2\nName:            data-fix\nVersion:         0.3.4\nx-revision:      2\nLicense:         BSD-3-Clause\nLicense-file:    LICENSE\nAuthor:          Anton Kholomiov, Edward Kmett, Oleg Grenrus\nMaintainer:      <anton.kholomiov@gmail.com>\nCategory:        Data\nSynopsis:        Fixpoint data types\nBuild-Type:      Simple\nDescription:\n  Fixpoint types and recursion schemes. If you define your AST as\n  fixpoint type, you get fold and unfold operations for free.\n  .\n  Thanks for contribution to: Matej Kollar, Herbert Valerio Riedel\n\nStability:       Experimental\n\nHomepage:        https://github.com/spell-music/data-fix\nBug-Reports:     https://github.com/spell-music/data-fix/issues\n\nTested-With:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-source-files:\n  CHANGELOG.md\n\nSource-repository head\n    Type: git\n    Location: https://github.com/spell-music/data-fix\n\nlibrary\n  hs-source-dirs:   src\n  default-language: Haskell2010\n  ghc-options:      -Wall\n  exposed-modules:  Data.Fix\n\n  ghc-options: -Wno-trustworthy-safe\n  ghc-options:\n      -Wincomplete-uni-patterns -Wincomplete-record-updates\n      -Wredundant-constraints -Widentities -Wmissing-export-lists\n\n  build-depends:\n    , base      >=4.12.0.0 && <4.23\n    , deepseq   >=1.4.4.0  && <1.6\n    , hashable  >=1.4.4.0  && <1.6\n";
  }