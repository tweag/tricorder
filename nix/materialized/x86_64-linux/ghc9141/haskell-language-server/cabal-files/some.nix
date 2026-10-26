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
    flags = { newtype-unsafe = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "some"; version = "1.0.6"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "James Cook <mokus@deepbondi.net>, Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/haskellari/some";
      url = "";
      synopsis = "Existential type: Some";
      description = "This library defines an existential type 'Some'.\n\n@\ndata Some f where\n\\    Some :: f a -> Some f\n@\n\nin few variants, and utilities to work with it.\n\nIf you are unsure which variant to use, use the one in \"Data.Some\" module.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.8")) (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"));
        buildable = true;
      };
      tests = {
        "hkd-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."some" or (errorHandler.buildDepError "some"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/some-1.0.6.tar.gz";
      sha256 = "f7a606ad5df4a07459986364f7d739eb653495fbbe1d7158582fb29a4584bfb9";
    });
  }) // {
    package-description-override = "name:               some\nversion:            1.0.6\nx-revision:         3\ncabal-version:      >=1.10\nbuild-type:         Simple\nauthor:\n  James Cook <mokus@deepbondi.net>, Oleg Grenrus <oleg.grenrus@iki.fi>\n\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nlicense:            BSD3\nlicense-file:       LICENSE\nhomepage:           https://github.com/haskellari/some\ncategory:           Data, Dependent Types\nsynopsis:           Existential type: Some\ndescription:\n  This library defines an existential type 'Some'.\n  .\n  @\n  data Some f where\n  \\    Some :: f a -> Some f\n  @\n  .\n  in few variants, and utilities to work with it.\n  .\n  If you are unsure which variant to use, use the one in \"Data.Some\" module.\n\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.4\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.7\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-source-files: ChangeLog.md\n\nflag newtype-unsafe\n  description:\n    Use implementation using @newtype@ and unsafe @Any@, instead of GADT\n\n  manual:      True\n  default:     True\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskellari/some.git\n  subdir:   some\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n\n  if flag(newtype-unsafe)\n    cpp-options: -DSOME_NEWTYPE\n\n  -- main module\n  exposed-modules:  Data.Some\n  exposed-modules:\n    Data.EqP\n    Data.GADT.Compare\n    Data.GADT.DeepSeq\n    Data.GADT.Show\n    Data.OrdP\n    Data.Some.Church\n    Data.Some.GADT\n    Data.Some.Newtype\n\n  other-modules:    Data.GADT.Internal\n  build-depends:\n      base     >=4.12    && <4.23\n    , deepseq  >=1.4.4.0 && <1.6\n\n  if !impl(ghc >= 9.8)\n    build-depends:\n      base-orphans >= 0.9.1 && <0.10\n\n  if impl(ghc >=9.0)\n    -- these flags may abort compilation with GHC-8.10\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\n\n  if impl(ghc >=9.1)\n    ghc-options: -Wmissing-kind-signatures\n\ntest-suite hkd-example\n  default-language: Haskell2010\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   test\n  main-is:          HKD.hs\n  build-depends:\n      base\n    , some\n";
  }