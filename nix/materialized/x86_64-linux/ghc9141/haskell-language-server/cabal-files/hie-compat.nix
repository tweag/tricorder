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
      specVersion = "1.22";
      identifier = { name = "hie-compat"; version = "0.3.1.2"; };
      license = "Apache-2.0";
      copyright = "";
      maintainer = "zubin.duggal@gmail.com";
      author = "Zubin Duggal";
      homepage = "https://github.com/haskell/haskell-language-server/tree/master/hie-compat#readme";
      url = "";
      synopsis = "HIE files for GHC 8.8 and other HIE file backports";
      description = "Backports for HIE files to GHC 8.8, along with a few other backports\nof HIE file related fixes for ghcide.\nTHIS DOES NOT LET YOU READ HIE FILES WITH MISMATCHED VERSIONS OF GHC";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hie-compat-0.3.1.2.tar.gz";
      sha256 = "15686610410e41e3ded92a452022b4dc2f0948583f1e0260dfa361203e100554";
    });
  }) // {
    package-description-override = "cabal-version:       1.22\r\nname:                hie-compat\r\nversion:             0.3.1.2\r\nx-revision: 2\r\nsynopsis:            HIE files for GHC 8.8 and other HIE file backports\r\nlicense:             Apache-2.0\r\ndescription:\r\n  Backports for HIE files to GHC 8.8, along with a few other backports\r\n  of HIE file related fixes for ghcide.\r\n\r\n  THIS DOES NOT LET YOU READ HIE FILES WITH MISMATCHED VERSIONS OF GHC\r\nlicense-file:        LICENSE\r\nauthor:              Zubin Duggal\r\nmaintainer:          zubin.duggal@gmail.com\r\nbuild-type:          Simple\r\nextra-source-files:  CHANGELOG.md README.md\r\ncategory:            Development\r\nhomepage:            https://github.com/haskell/haskell-language-server/tree/master/hie-compat#readme\r\nbug-reports:         https://github.com/haskell/haskell-language-server/issues\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell/haskell-language-server.git\r\n\r\nlibrary\r\n  default-language:    Haskell2010\r\n  build-depends:\r\n     base < 4.22, array, bytestring, containers, directory, filepath, transformers\r\n  build-depends: ghc >= 8.10, ghc-boot\r\n  ghc-options: -Wall -Wno-name-shadowing\r\n\r\n  exposed-modules:\r\n    Compat.HieAst\r\n    Compat.HieBin\r\n    Compat.HieTypes\r\n    Compat.HieDebug\r\n    Compat.HieUtils\r\n\r\n  if (impl(ghc >= 9.0) && impl(ghc < 9.1))\r\n    hs-source-dirs: src-ghc90 src-reexport-ghc9\r\n  if (impl(ghc >= 9.2) && impl(ghc < 9.3))\r\n    hs-source-dirs: src-ghc92 src-reexport-ghc9\r\n  if (impl(ghc >= 9.4))\r\n    hs-source-dirs: src-reexport-ghc92\r\n";
  }