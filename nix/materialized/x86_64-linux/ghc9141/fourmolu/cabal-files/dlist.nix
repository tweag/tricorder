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
    flags = { werror = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "dlist"; version = "1.0"; };
      license = "BSD-3-Clause";
      copyright = "2006-2009 Don Stewart, 2013-2020 Sean Leather, 2017-2020 Oleg Grenrus, contributors";
      maintainer = "Sean Leather <sean.leather@gmail.com>";
      author = "Don Stewart";
      homepage = "https://github.com/spl/dlist";
      url = "";
      synopsis = "Difference lists";
      description = "List-like types supporting O(1) append and snoc operations.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/dlist-1.0.tar.gz";
      sha256 = "173d637328bb173fcc365f30d29ff4a94292a1e0e5558aeb3dfc11de81510115";
    });
  }) // {
    package-description-override = "cabal-version:          >= 1.10\r\n\r\nname:                   dlist\r\nversion:                1.0\r\nx-revision:             2\r\n\r\nsynopsis:               Difference lists\r\ndescription:\r\n  List-like types supporting O(1) append and snoc operations.\r\ncategory:               Data\r\nlicense:                BSD3\r\nlicense-file:           license.md\r\nauthor:                 Don Stewart\r\nmaintainer:             Sean Leather <sean.leather@gmail.com>\r\ncopyright:              2006-2009 Don Stewart, 2013-2020 Sean Leather, 2017-2020 Oleg Grenrus, contributors\r\nhomepage:               https://github.com/spl/dlist\r\nbug-reports:            https://github.com/spl/dlist/issues\r\nextra-source-files:     readme.md,\r\n                        changelog.md\r\n                        tests/ImportUnsafe.hs\r\nbuild-type:             Simple\r\n\r\ntested-with:            GHC == 9.10.1\r\n                        GHC == 9.8.1\r\n                        GHC == 9.6.6\r\n                        GHC == 9.4.8\r\n                        GHC == 9.2.8\r\n                        GHC == 9.0.2\r\n                        GHC == 8.10.7\r\n                        GHC == 8.8.4\r\n                        GHC == 8.6.5\r\n                        GHC == 8.4.4\r\n                        GHC == 8.2.2\r\n                        GHC == 8.0.2\r\n                        GHC == 7.10.3\r\n                        GHC == 7.8.4\r\n                        GHC == 7.6.3\r\n                        GHC == 7.4.2\r\n                        GHC == 7.2.2\r\n                        GHC == 7.0.4\r\n\r\nsource-repository head\r\n  type:                 git\r\n  location:             https://github.com/spl/dlist.git\r\n\r\nflag Werror\r\n  description:          Enable -Werror\r\n  default:              False\r\n  manual:               True\r\n\r\nlibrary\r\n  build-depends:\r\n                        base >= 4 && < 5,\r\n                        deepseq >= 1.1 && < 1.6\r\n  exposed-modules:      Data.DList\r\n                        Data.DList.Unsafe\r\n  other-modules:        Data.DList.Internal\r\n  if impl(ghc >= 8.0)\r\n    exposed-modules:    Data.DList.DNonEmpty\r\n    other-modules:      Data.DList.DNonEmpty.Internal\r\n  default-language:     Haskell2010\r\n  ghc-options:          -Wall\r\n  if impl(ghc >= 8.0)\r\n    ghc-options:        -Wcompat\r\n                        -Wincomplete-record-updates\r\n                        -Wincomplete-uni-patterns\r\n                        -Wnoncanonical-monad-instances\r\n  if impl(ghc >= 8.2)\r\n    ghc-options:        -Wmissing-home-modules\r\n  if impl(ghc >= 8.4)\r\n    ghc-options:        -Wpartial-fields\r\n  if impl(ghc >= 8.10)\r\n    ghc-options:        -Wmissing-safe-haskell-mode\r\n                        -Wtrustworthy-safe\r\n  if flag(Werror)\r\n    ghc-options:        -Werror\r\n\r\ntest-suite test\r\n  type:                 exitcode-stdio-1.0\r\n  main-is:              Main.hs\r\n  other-modules:        DListProperties\r\n                        OverloadedStrings\r\n                        QuickCheckUtil\r\n  if impl(ghc >= 8.0)\r\n    other-modules:      DNonEmptyProperties\r\n  hs-source-dirs:       tests\r\n  build-depends:        dlist,\r\n                        base,\r\n                        -- QuickCheck-2.10 is the first version supporting\r\n                        -- base-4.9 (ghc-8) without the Arbitrary NonEmpty\r\n                        -- instance, which we include ourselves.\r\n                        QuickCheck >= 2.10 && < 3\r\n  default-language:     Haskell2010\r\n  ghc-options:          -Wall\r\n  if impl(ghc >= 8.0)\r\n    ghc-options:        -Wcompat\r\n                        -Wincomplete-record-updates\r\n                        -Wincomplete-uni-patterns\r\n                        -Wnoncanonical-monad-instances\r\n  if impl(ghc >= 8.2)\r\n    ghc-options:        -Wmissing-home-modules\r\n  if impl(ghc >= 8.4)\r\n    ghc-options:        -Wpartial-fields\r\n  if impl(ghc >= 8.10)\r\n    ghc-options:        -Wmissing-safe-haskell-mode\r\n                        -Wtrustworthy-safe\r\n  if flag(Werror)\r\n    ghc-options:        -Werror\r\n";
  }