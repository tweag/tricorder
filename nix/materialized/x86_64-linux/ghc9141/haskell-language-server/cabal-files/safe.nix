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
      specVersion = "1.18";
      identifier = { name = "safe"; version = "0.3.21"; };
      license = "BSD-3-Clause";
      copyright = "Neil Mitchell 2007-2024";
      maintainer = "Neil Mitchell <ndmitchell@gmail.com>";
      author = "Neil Mitchell <ndmitchell@gmail.com>";
      homepage = "https://github.com/ndmitchell/safe#readme";
      url = "";
      synopsis = "Library of safe (exception free) functions";
      description = "A library wrapping @Prelude@/@Data.List@ functions that can throw exceptions, such as @head@ and @!!@.\nEach unsafe function has up to four variants, e.g. with @tail@:\n\n* @tail :: [a] -> [a]@, raises an error on @tail []@.\n\n* @tailMay :: [a] -> /Maybe/ [a]@, turns errors into @Nothing@.\n\n* @tailDef :: /[a]/ -> [a] -> [a]@, takes a default to return on errors.\n\n* @tailNote :: /String/ -> [a] -> [a]@, takes an extra argument which supplements the error message.\n\n* @tailSafe :: [a] -> [a]@, returns some sensible default if possible, @[]@ in the case of @tail@.\n\nThis package is divided into three modules:\n\n* \"Safe\" contains safe variants of @Prelude@ and @Data.List@ functions.\n\n* \"Safe.Foldable\" contains safe variants of @Foldable@ functions.\n\n* \"Safe.Exact\" creates crashing versions of functions like @zip@ (errors if the lists are not equal) and @take@ (errors if there are not enough elements), then wraps them to provide safe variants.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "safe-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/safe-0.3.21.tar.gz";
      sha256 = "2c81fea42bbe79ec488774043c1ec54f30efba059df9a4f3681ce83d85007f01";
    });
  }) // {
    package-description-override = "cabal-version:  1.18\r\nbuild-type:     Simple\r\nname:           safe\r\nversion:        0.3.21\r\nx-revision: 1\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\ncategory:       Unclassified\r\nauthor:         Neil Mitchell <ndmitchell@gmail.com>\r\nmaintainer:     Neil Mitchell <ndmitchell@gmail.com>\r\ncopyright:      Neil Mitchell 2007-2024\r\nhomepage:       https://github.com/ndmitchell/safe#readme\r\nsynopsis:       Library of safe (exception free) functions\r\nbug-reports:    https://github.com/ndmitchell/safe/issues\r\ntested-with:    GHC==9.8, GHC==9.6, GHC==9.4, GHC==9.2, GHC==9.0, GHC==8.10, GHC==8.8\r\ndescription:\r\n    A library wrapping @Prelude@/@Data.List@ functions that can throw exceptions, such as @head@ and @!!@.\r\n    Each unsafe function has up to four variants, e.g. with @tail@:\r\n    .\r\n    * @tail :: [a] -> [a]@, raises an error on @tail []@.\r\n    .\r\n    * @tailMay :: [a] -> /Maybe/ [a]@, turns errors into @Nothing@.\r\n    .\r\n    * @tailDef :: /[a]/ -> [a] -> [a]@, takes a default to return on errors.\r\n    .\r\n    * @tailNote :: /String/ -> [a] -> [a]@, takes an extra argument which supplements the error message.\r\n    .\r\n    * @tailSafe :: [a] -> [a]@, returns some sensible default if possible, @[]@ in the case of @tail@.\r\n    .\r\n    This package is divided into three modules:\r\n    .\r\n    * \"Safe\" contains safe variants of @Prelude@ and @Data.List@ functions.\r\n    .\r\n    * \"Safe.Foldable\" contains safe variants of @Foldable@ functions.\r\n    .\r\n    * \"Safe.Exact\" creates crashing versions of functions like @zip@ (errors if the lists are not equal) and @take@ (errors if there are not enough elements), then wraps them to provide safe variants.\r\nextra-doc-files:\r\n    CHANGES.txt\r\n    README.md\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/ndmitchell/safe.git\r\n\r\nlibrary\r\n    default-language: Haskell2010\r\n    build-depends:\r\n        base >= 4.9 && < 5\r\n\r\n    exposed-modules:\r\n        Safe\r\n        Safe.Exact\r\n        Safe.Foldable\r\n        Safe.Partial\r\n\r\n    other-modules:\r\n        Safe.Util\r\n\r\ntest-suite safe-test\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Test.hs\r\n    default-language:   Haskell2010\r\n\r\n    other-modules:\r\n        Safe\r\n        Safe.Exact\r\n        Safe.Foldable\r\n        Safe.Partial\r\n        Safe.Util\r\n    build-depends:\r\n        base,\r\n        deepseq,\r\n        QuickCheck,\r\n        safe\r\n";
  }