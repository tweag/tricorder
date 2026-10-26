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
      identifier = { name = "http-types"; version = "0.12.6"; };
      license = "BSD-3-Clause";
      copyright = "(C) 2011 Aristid Breitkreuz, (C) 2023 Felix Paulusma";
      maintainer = "felix.paulusma@gmail.com";
      author = "Aristid Breitkreuz, Michael Snoyman";
      homepage = "https://github.com/Vlix/http-types";
      url = "";
      synopsis = "Generic HTTP types for Haskell (for both client and server code).";
      description = "Types and functions to describe and handle HTTP concepts.\nIncluding \"methods\", \"headers\", \"query strings\", \"paths\" and \"HTTP versions\".";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."hspec-golden" or (errorHandler.buildDepError "hspec-golden"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."quickcheck-instances" or (errorHandler.buildDepError "quickcheck-instances"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "doctests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http-types-0.12.6.tar.gz";
      sha256 = "b688042acb4e53f1f5efed26056cf1fdc3ae5dc6b85cfbe321edffc3079c106c";
    });
  }) // {
    package-description-override = "Cabal-version:       2.2\nName:                http-types\nVersion:             0.12.6\nSynopsis:            Generic HTTP types for Haskell (for both client and server code).\nDescription:         Types and functions to describe and handle HTTP concepts.\n                     Including \"methods\", \"headers\", \"query strings\", \"paths\" and \"HTTP versions\".\nHomepage:            https://github.com/Vlix/http-types\nLicense:             BSD-3-Clause\nLicense-file:        LICENSE\nAuthor:              Aristid Breitkreuz, Michael Snoyman\nMaintainer:          felix.paulusma@gmail.com\nCopyright:           (C) 2011 Aristid Breitkreuz, (C) 2023 Felix Paulusma\nCategory:            Network, Web\nBuild-type:          Simple\nTested-with:\n    GHC == 7.10.3, GHC == 9.6.7, GHC == 9.8.4, GHC == 9.10.3, GHC == 9.12.4, GHC == 9.14.1\nExtra-source-files:\n    test/.golden/urlEncode-path/golden\n    test/.golden/urlEncode-query/golden\nExtra-doc-files:\n    README.md\n    CHANGELOG.md\n\nSource-repository this\n  type: git\n  location: https://github.com/Vlix/http-types.git\n  tag: v0.12.6\n\nSource-repository head\n  type: git\n  location: https://github.com/Vlix/http-types.git\n\nLibrary\n  Exposed-modules:     Network.HTTP.Types\n                       Network.HTTP.Types.Header\n                       Network.HTTP.Types.Method\n                       Network.HTTP.Types.QueryLike\n                       Network.HTTP.Types.Status\n                       Network.HTTP.Types.URI\n                       Network.HTTP.Types.Version\n  GHC-Options:         -Wall\n  Build-depends:       base >= 4.8 && < 5,\n                       bytestring >= 0.10.6.0 && < 1,\n                       case-insensitive >= 1.2.0.2 && < 1.3,\n                       text >= 1.2.0.2 && < 3\n  Default-language:    Haskell2010\n\nTest-suite spec\n  main-is:             Spec.hs\n  hs-source-dirs:      test\n  other-modules:       Network.HTTP.Types.HeaderSpec\n                       Network.HTTP.Types.MethodSpec\n                       Network.HTTP.Types.StatusSpec\n                       Network.HTTP.Types.URISpec\n                       Network.HTTP.Types.VersionSpec\n  type:                exitcode-stdio-1.0\n  GHC-Options:         -Wall\n  default-language:    Haskell2010\n  build-tool-depends:  hspec-discover:hspec-discover\n  build-depends:       base < 5,\n                       bytestring,\n                       case-insensitive,\n                       filepath,\n                       hspec >= 1.3,\n                       hspec-golden >= 0.2,\n                       http-types,\n                       QuickCheck,\n                       quickcheck-instances,\n                       text\n\nTest-Suite doctests\n  main-is:             doctests.hs\n  hs-source-dirs:      test\n  type:                exitcode-stdio-1.0\n  ghc-options:         -threaded -Wall\n  default-language:    Haskell2010\n  build-depends:       base < 5, doctest >= 0.19.0\n";
  }