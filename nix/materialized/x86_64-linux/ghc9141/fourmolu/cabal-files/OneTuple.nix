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
    flags = { base-ge-4-15 = true; base-ge-4-16 = true; };
    package = {
      specVersion = "1.12";
      identifier = { name = "OneTuple"; version = "0.4.3"; };
      license = "BSD-3-Clause";
      copyright = "(c) John Dorsey 2008";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>, John Dorsey <haskell@colquitt.org>";
      author = "John Dorsey <haskell@colquitt.org>";
      homepage = "";
      url = "";
      synopsis = "Singleton Tuple";
      description = "This package is a compatibility package for a singleton data type\n\n> data Solo a = MkSolo a\n\nNote: it's not a @newtype@\n\n@Solo@ is available in @base-4.16@ (GHC-9.2).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
        ] ++ (if flags.base-ge-4-15
          then [
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          ]
          else [
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          ])) ++ pkgs.lib.optional (!flags.base-ge-4-15) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"))) ++ pkgs.lib.optional (!flags.base-ge-4-16) (hsPkgs."base-orphans" or (errorHandler.buildDepError "base-orphans"))) ++ [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ]) ++ [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "instances" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
          ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.0")) [
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
          ]) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"));
          buildable = true;
        };
        "th" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."OneTuple" or (errorHandler.buildDepError "OneTuple"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/OneTuple-0.4.3.tar.gz";
      sha256 = "643d1f48e63480ac6d03a8f0ab5976d66527c9b42b1fca81d1bf373d10099c6b";
    });
  }) // {
    package-description-override = "cabal-version:      1.12\nname:               OneTuple\nversion:            0.4.3\nsynopsis:           Singleton Tuple\ncategory:           Data\ndescription:\n  This package is a compatibility package for a singleton data type\n  .\n  > data Solo a = MkSolo a\n  .\n  Note: it's not a @newtype@\n  .\n  @Solo@ is available in @base-4.16@ (GHC-9.2).\n\ncopyright:          (c) John Dorsey 2008\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             John Dorsey <haskell@colquitt.org>\nmaintainer:\n  Oleg Grenrus <oleg.grenrus@iki.fi>, John Dorsey <haskell@colquitt.org>\n\nstability:          experimental\nbuild-type:         Simple\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.4\n   || ==9.8.6\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-source-files: Changelog.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/OneTuple.git\n\nflag base-ge-4-15\n  description: @base >=4.15@ (GHC-9.0)\n  default:     True\n  manual:      False\n\nflag base-ge-4-16\n  description: @base >=4.16@ (GHC-9.2)\n  default:     True\n  manual:      False\n\nlibrary\n  default-language: Haskell98\n  exposed-modules:\n    Data.Tuple.OneTuple\n    Data.Tuple.Solo\n    Data.Tuple.Solo.TH\n\n  hs-source-dirs:   src\n  build-depends:\n      base              >=4.12 && <4.23\n    , template-haskell\n\n  if flag(base-ge-4-15)\n    build-depends: ghc-prim\n\n  else\n    build-depends: hashable >=1.3.5.0 && <1.6\n\n  if !flag(base-ge-4-15)\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\n\n  if !flag(base-ge-4-16)\n    build-depends: base-orphans >=0.8.6\n\n  -- flag selection forcing conditionals\n  if flag(base-ge-4-15)\n    build-depends: base >=4.15\n\n  else\n    build-depends: base <4.15\n\n  if flag(base-ge-4-16)\n    build-depends: base >=4.16\n\n  else\n    build-depends: base <4.16\n\ntest-suite instances\n  type:             exitcode-stdio-1.0\n  default-language: Haskell98\n  hs-source-dirs:   test\n  main-is:          instances.hs\n  build-depends:\n      base\n    , hashable\n    , OneTuple\n\n  if !impl(ghc >=8.0)\n    build-depends:\n        semigroups\n      , transformers\n      , transformers-compat\n\n  if !impl(ghc >=9.6)\n    build-depends: foldable1-classes-compat >=0.1 && <0.2\n\ntest-suite th\n  type:             exitcode-stdio-1.0\n  default-language: Haskell98\n  hs-source-dirs:   test\n  main-is:          th.hs\n  build-depends:\n      base\n    , OneTuple\n";
  }