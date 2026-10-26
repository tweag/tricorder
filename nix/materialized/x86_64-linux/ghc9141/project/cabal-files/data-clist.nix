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
      identifier = { name = "data-clist"; version = "0.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Jeremy Huffman <jeremy@jeremyhuffman.com>, John Van Enk <vanenkj@gmail.com>";
      author = "John Van Enk <vanenkj@gmail.com>";
      homepage = "https://github.com/sw17ch/data-clist";
      url = "";
      synopsis = "Simple functional ring type.";
      description = "Simple functional bidirectional ring type.\nGiven that the ring terminiology clashes with certain\nmathematical branches, we're using the term CList or\nCircularList instead.";
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
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-clist" or (errorHandler.buildDepError "data-clist"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-clist-0.2.tar.gz";
      sha256 = "1c3a1ebd71e8f6fe30afdb3797c4852db7fb0b4e3c145fc53e8282eb4303b212";
    });
  }) // {
    package-description-override = "Cabal-Version: 2.2\r\nName: data-clist\r\nSynopsis: Simple functional ring type.\r\nDescription: Simple functional bidirectional ring type.\r\n\r\n             Given that the ring terminiology clashes with certain\r\n             mathematical branches, we're using the term CList or\r\n             CircularList instead.\r\nVersion: 0.2\r\nx-revision: 1\r\nLicense: BSD-3-Clause\r\nLicense-File: LICENSE\r\nAuthor: John Van Enk <vanenkj@gmail.com>\r\nMaintainer: Jeremy Huffman <jeremy@jeremyhuffman.com>, John Van Enk <vanenkj@gmail.com>\r\nStability: experimental\r\nCategory: Data Structures\r\nBuild-Type: Simple\r\nHomepage: https://github.com/sw17ch/data-clist\r\n\r\nsource-repository head\r\n    type: git\r\n    location: git://github.com/sw17ch/data-clist.git\r\n\r\nLibrary\r\n    Default-Language: Haskell2010\r\n    Build-Depends: base >= 4 && < 5,\r\n                   deepseq >= 1.1 && < 1.6\r\n    Exposed-Modules:\r\n        Data.CircularList\r\n        Data.CircularList.Internal\r\n\r\n    ghc-options:        -Wall\r\n    hs-source-dirs:     src\r\n\r\nTest-Suite tests\r\n  Default-Language: Haskell2010\r\n  Type:             exitcode-stdio-1.0\r\n  Build-Depends:    base >=4.11 && < 5\r\n                  , data-clist\r\n                  , QuickCheck >= 2.4 && < 2.15\r\n  hs-source-dirs:   tests/\r\n  main-is:          quickcheck.hs\r\n\r\n";
  }