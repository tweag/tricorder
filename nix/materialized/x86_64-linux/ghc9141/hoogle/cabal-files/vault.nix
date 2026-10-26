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
    flags = { useghc = true; };
    package = {
      specVersion = "3.4";
      identifier = { name = "vault"; version = "0.3.2.0"; };
      license = "BSD-3-Clause";
      copyright = "(c) Heinrich Apfelmus 2011-2026";
      maintainer = "Heinrich Apfelmus <apfelmus at quantentunnel de>";
      author = "Heinrich Apfelmus, Elliott Hird";
      homepage = "https://github.com/HeinrichApfelmus/vault";
      url = "";
      synopsis = "a persistent store for values of arbitrary types";
      description = "A /vault/ is a persistent store for values of arbitrary types.\nIt's like having first-class access to the storage space behind IORefs.\n.\nThe data structure is analogous to a bank vault,\nwhere you can access different bank boxes with different keys;\nhence the name.\n.\nAlso provided is a /locker/ type, representing a store for a single element.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ pkgs.lib.optional (compiler.isMhs && true) (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"));
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/vault-0.3.2.0.tar.gz";
      sha256 = "8ee4c8e71feb26841e667ee23e41d7a380f64c14703da93b3a4ea9164da79023";
    });
  }) // {
    package-description-override = "cabal-version:      3.4\nname:               vault\n\n-- Package Versioning Policy: https://pvp.haskell.org\n-- PVP summary:     +-+------- breaking API changes\n--                  | | +----- non-breaking API additions\n--                  | | | +--- code changes with no API change\nversion:            0.3.2.0\nsynopsis:           a persistent store for values of arbitrary types\ndescription:\n  A /vault/ is a persistent store for values of arbitrary types.\n  It's like having first-class access to the storage space behind IORefs.\n  .\n  The data structure is analogous to a bank vault,\n  where you can access different bank boxes with different keys;\n  hence the name.\n  .\n  Also provided is a /locker/ type, representing a store for a single element.\n\ncategory:           Data\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Heinrich Apfelmus, Elliott Hird\nmaintainer:         Heinrich Apfelmus <apfelmus at quantentunnel de>\nhomepage:           https://github.com/HeinrichApfelmus/vault\ncopyright:          (c) Heinrich Apfelmus 2011-2026\ntested-with:\n  GHC ==8.4.4\n   || ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.7\n   || ==9.8.4\n   || ==9.10.3\n   || ==9.12.4\n\nextra-source-files:\n  src/Data/Unique/Really/Core.h\n  src/Data/Vault/IO.h\n  src/Data/Vault/ST/backends/GHC.h\n  src/Data/Vault/ST/backends/IORef.hs\n  src/Data/Vault/ST/ST.h\n  test/Data/Vault/Spec.h\nextra-doc-files:\n  CHANGELOG.md\n  README.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/HeinrichApfelmus/vault.git\n\nflag UseGHC\n  description: Use GHC-specific packages and extensions.\n  default:     True\n\nlibrary\n  default-language:   Haskell2010\n  default-extensions: CPP\n  build-depends:\n    , base                  >=4.11    && <4.23\n    , containers            >=0.5     && <0.9\n    , hashable              >=1.1.2.5 && <1.6\n    , unordered-containers  >=0.2.3.0 && <0.3\n\n  ghc-options:        -Wall -fno-warn-missing-signatures\n  hs-source-dirs:     src\n  exposed-modules:\n    Data.Unique.Really\n    Data.Vault.Lazy\n    Data.Vault.ST.Lazy\n    Data.Vault.ST.Strict\n    Data.Vault.Strict\n    Internal.Data.Vault.ST.IORef\n  other-modules:\n    Data.Unique.Really.Any\n    Data.Unique.Really.GHC\n\n  if (impl(ghc) && flag(useghc))\n    cpp-options: -DUseGHC\n\n  if impl(mhs)\n    build-depends:\n      , unordered-containers >= 0.2.21\n\ntest-suite test\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     test\n  default-language:   Haskell2010\n  default-extensions: CPP\n  ghc-options:        -threaded\n  build-depends:\n    , base\n    , vault\n    , hspec           >=2.11.0 && <2.12\n\n  main-is:            Spec.hs\n  other-modules:\n    Data.Vault.ST.LazySpec\n    Internal.Data.Vault.ST.IORefSpec\n";
  }