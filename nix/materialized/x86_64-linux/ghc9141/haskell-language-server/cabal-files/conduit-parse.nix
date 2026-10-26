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
    flags = { enable-hlint-test = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "conduit-parse"; version = "0.2.1.1"; };
      license = "LicenseRef-PublicDomain";
      copyright = "";
      maintainer = "mail@cmoreau.info";
      author = "mail@cmoreau.info";
      homepage = "https://github.com/k0ral/conduit-parse";
      url = "";
      synopsis = "Parsing framework based on conduit.";
      description = "Please refer to README.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."parsers" or (errorHandler.buildDepError "parsers"))
          (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
          (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
            (hsPkgs."conduit-parse" or (errorHandler.buildDepError "conduit-parse"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."parsers" or (errorHandler.buildDepError "parsers"))
            (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ];
          buildable = true;
        };
        "hlint" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hlint" or (errorHandler.buildDepError "hlint"))
          ];
          buildable = if flags.enable-hlint-test then true else false;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/conduit-parse-0.2.1.1.tar.gz";
      sha256 = "07fb28868ce016b5e1b5fd033c9c73340a09c13140003f070a6952842a01acf5";
    });
  }) // {
    package-description-override = "name:                conduit-parse\r\nversion:             0.2.1.1\r\nx-revision: 1\r\nsynopsis:            Parsing framework based on conduit.\r\ndescription:         Please refer to README.\r\nhomepage:            https://github.com/k0ral/conduit-parse\r\nlicense:             PublicDomain\r\nlicense-file:        LICENSE\r\nauthor:              mail@cmoreau.info\r\nmaintainer:          mail@cmoreau.info\r\ncategory:            Conduit, Text\r\nbuild-type:          Simple\r\ncabal-version:       >=1.10\r\nextra-source-files:  README.md\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: git://github.com/k0ral/conduit-parse.git\r\n\r\nflag enable-hlint-test\r\n  description: Enable hlint test-suite\r\n  manual: True\r\n  default: False\r\n\r\nlibrary\r\n  exposed-modules:\r\n    Data.Conduit.Parser\r\n  other-modules:\r\n    Data.Conduit.Parser.Internal\r\n  build-depends:\r\n      base >= 4.8 && < 5\r\n    , conduit >= 1.3\r\n    , dlist\r\n    , mtl\r\n    , parsers\r\n    , safe\r\n    , safe-exceptions\r\n    , text\r\n    , transformers\r\n  default-language: Haskell2010\r\n  ghc-options: -Wall -fno-warn-unused-do-bind\r\n\r\ntest-suite tests\r\n  type: exitcode-stdio-1.0\r\n  hs-source-dirs: test\r\n  main-is: Main.hs\r\n  build-depends:\r\n      base >= 4.8 && < 5\r\n    , conduit >= 1.3\r\n    , conduit-parse\r\n    , mtl\r\n    , parsers\r\n    , resourcet\r\n    , safe-exceptions\r\n    , tasty\r\n    , tasty-hunit\r\n    -- , tasty-quickcheck\r\n  default-language: Haskell2010\r\n  ghc-options: -Wall -fno-warn-unused-do-bind\r\n\r\ntest-suite hlint\r\n  if flag(enable-hlint-test)\r\n    buildable: True\r\n  else\r\n    buildable: False\r\n  type: exitcode-stdio-1.0\r\n  main-is: HLint.hs\r\n  build-depends:\r\n    base >=4.8,\r\n    hlint -any\r\n  default-language: Haskell2010\r\n  hs-source-dirs: test\r\n";
  }