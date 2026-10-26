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
      identifier = { name = "th-expand-syns"; version = "0.4.12.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Ryan Scott <ryan.gl.scott@gmail.com>";
      author = "Daniel Schüssler";
      homepage = "https://github.com/DanielSchuessler/th-expand-syns";
      url = "";
      synopsis = "Expands type synonyms in Template Haskell ASTs";
      description = "Expands type synonyms in Template Haskell ASTs.\n\nAs of version @0.4.9.0@, this library is a small shim on\ntop of the @applySubstitution@/@resolveTypeSynonyms@\nfunctions from @th-abstraction@, so you may want to\nconsider using @th-abstraction@ instead.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ];
        buildable = true;
      };
      tests = {
        "test-th-expand-syns" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
            (hsPkgs."th-expand-syns" or (errorHandler.buildDepError "th-expand-syns"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/th-expand-syns-0.4.12.0.tar.gz";
      sha256 = "18e19967329c89f376cfc9ec04bd7871854ce0c70f803a1af15532be00c6ef0f";
    });
  }) // {
    package-description-override = "name:                th-expand-syns\r\nversion:             0.4.12.0\r\nx-revision: 1\r\nsynopsis:            Expands type synonyms in Template Haskell ASTs\r\ndescription:         Expands type synonyms in Template Haskell ASTs.\r\n                     .\r\n                     As of version @0.4.9.0@, this library is a small shim on\r\n                     top of the @applySubstitution@/@resolveTypeSynonyms@\r\n                     functions from @th-abstraction@, so you may want to\r\n                     consider using @th-abstraction@ instead.\r\ncategory:            Template Haskell\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Daniel Schüssler\r\nmaintainer:          Ryan Scott <ryan.gl.scott@gmail.com>\r\ncabal-version:       >= 1.10\r\nbuild-type:          Simple\r\nextra-source-files:  changelog.markdown\r\nhomepage:            https://github.com/DanielSchuessler/th-expand-syns\r\ntested-with:\r\n    GHC == 8.0.2\r\n    GHC == 8.2.2\r\n    GHC == 8.4.4\r\n    GHC == 8.6.5\r\n    GHC == 8.8.4\r\n    GHC == 8.10.7\r\n    GHC == 9.0.2\r\n    GHC == 9.2.8\r\n    GHC == 9.4.8\r\n    GHC == 9.6.6\r\n    GHC == 9.8.4\r\n    GHC == 9.10.1\r\n    GHC == 9.12.1\r\n\r\nsource-repository head\r\n type: git\r\n location: https://github.com/DanielSchuessler/th-expand-syns.git\r\n\r\nLibrary\r\n    build-depends:       base             >= 4.9   && < 5\r\n                       , containers\r\n                       , syb\r\n                       , th-abstraction   >= 0.4.3 && < 0.8\r\n                       , template-haskell >= 2.11  && < 2.25\r\n    ghc-options:         -Wall\r\n    exposed-modules:     Language.Haskell.TH.ExpandSyns\r\n    default-language:    Haskell2010\r\n\r\nTest-Suite test-th-expand-syns\r\n    type:               exitcode-stdio-1.0\r\n    hs-source-dirs:     testing\r\n    main-is:            Main.hs\r\n    other-modules:      Util, Types\r\n    build-depends:      base\r\n                      , template-haskell\r\n                      , th-abstraction\r\n                      , th-expand-syns\r\n    ghc-options:        -Wall\r\n    if impl(ghc >= 8.6)\r\n      ghc-options:      -Wno-star-is-type\r\n    default-language:   Haskell2010\r\n";
  }