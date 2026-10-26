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
      identifier = { name = "fmlist"; version = "0.9.5"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "sjoerd@w3future.com";
      author = "Sjoerd Visscher";
      homepage = "https://github.com/sjoerdvisscher/fmlist";
      url = "";
      synopsis = "FoldMap lists";
      description = "FoldMap lists are lists represented by their foldMap function.\nFoldMap lists have O(1) cons, snoc and append, just like DLists,\nbut other operations might have favorable performance\ncharacteristics as well. These wild claims are still completely\nunverified though.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/fmlist-0.9.5.tar.gz";
      sha256 = "c7a19a27340b6e0fd77934482985244e9850873b55acc51d5ec72dfb7569c00c";
    });
  }) // {
    package-description-override = "name:                fmlist\nversion:             0.9.5\nsynopsis:            FoldMap lists\ndescription:\n  FoldMap lists are lists represented by their foldMap function.\n  FoldMap lists have O(1) cons, snoc and append, just like DLists,\n  but other operations might have favorable performance\n  characteristics as well. These wild claims are still completely\n  unverified though.\ncategory:            Data\nlicense:             BSD3\nlicense-file:        LICENSE\nauthor:              Sjoerd Visscher\nmaintainer:          sjoerd@w3future.com\nhomepage:            https://github.com/sjoerdvisscher/fmlist\nbug-reports:         https://github.com/sjoerdvisscher/fmlist/issues\n\nbuild-type:          Simple\ncabal-version:       >= 1.10\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.4\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n\nLibrary\n  exposed-modules:     Data.FMList\n  build-depends:       base >= 3 && < 5\n  default-language:    Haskell98\n\n  ghc-options:         -Wall -Wcompat\n\n\nsource-repository head\n  type:     git\n  location: https://github.com/sjoerdvisscher/fmlist.git\n";
  }