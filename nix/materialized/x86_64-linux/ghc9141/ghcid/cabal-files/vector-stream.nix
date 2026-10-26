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
      identifier = { name = "vector-stream"; version = "0.1.0.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) Roman Leshchinskiy 2008-2012\nAlexey Kuleshevich 2020-2022,\nAleksey Khudyakov 2020-2022,\nAndrew Lelechenko 2020-2022";
      maintainer = "Haskell Libraries Team <libraries@haskell.org>\nAlexey Kuleshevich <alexey@kuleshevi.ch>,\nAleksey Khudyakov <alexey.skladnoy@gmail.com>,\nAndrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Roman Leshchinskiy <rl@cse.unsw.edu.au>";
      homepage = "https://github.com/haskell/vector";
      url = "";
      synopsis = "Efficient Streams";
      description = "Simple yet powerful monadic streams that are used\nas a backbone for vector package fusion functionality.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vector-stream-0.1.0.1.tar.gz";
      sha256 = "d0f507334bdea5431a2f07f525a97f29e76522c32210f5de6d5a2b4f1d42bf7c";
    });
  }) // {
    package-description-override = "Name:           vector-stream\r\nVersion:        0.1.0.1\r\nx-revision: 4\r\n-- don't forget to update the changelog file!\r\nLicense:        BSD3\r\nLicense-File:   LICENSE\r\nAuthor:         Roman Leshchinskiy <rl@cse.unsw.edu.au>\r\nMaintainer:     Haskell Libraries Team <libraries@haskell.org>\r\n                Alexey Kuleshevich <alexey@kuleshevi.ch>,\r\n                Aleksey Khudyakov <alexey.skladnoy@gmail.com>,\r\n                Andrew Lelechenko <andrew.lelechenko@gmail.com>\r\nCopyright:      (c) Roman Leshchinskiy 2008-2012\r\n                    Alexey Kuleshevich 2020-2022,\r\n                    Aleksey Khudyakov 2020-2022,\r\n                    Andrew Lelechenko 2020-2022\r\nHomepage:       https://github.com/haskell/vector\r\nBug-Reports:    https://github.com/haskell/vector/issues\r\nCategory:       Data, Data Structures\r\nSynopsis:       Efficient Streams\r\nDescription:\r\n        Simple yet powerful monadic streams that are used\r\n        as a backbone for vector package fusion functionality.\r\n\r\nTested-With:\r\n  GHC == 8.0.2,\r\n  GHC == 8.2.2,\r\n  GHC == 8.4.4,\r\n  GHC == 8.6.5,\r\n  GHC == 8.8.4,\r\n  GHC == 8.10.4,\r\n  GHC == 9.0.2,\r\n  GHC == 9.2.8,\r\n  GHC == 9.4.6,\r\n  GHC == 9.6.2\r\n  GHC == 9.8.1\r\n\r\nCabal-Version:  >=1.10\r\nBuild-Type:     Simple\r\n\r\nExtra-Source-Files:\r\n      changelog.md\r\n      README.md\r\n\r\nLibrary\r\n  Default-Language: Haskell2010\r\n\r\n  Exposed-Modules:\r\n        Data.Stream.Monadic\r\n\r\n  Hs-Source-Dirs:\r\n        src\r\n\r\n  Build-Depends: base >= 4.9 && < 4.23\r\n               , ghc-prim >= 0.2 && < 0.14\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/haskell/vector.git\r\n  subdir:   vector-stream\r\n";
  }