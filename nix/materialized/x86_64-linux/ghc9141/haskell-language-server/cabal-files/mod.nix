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
    flags = { semirings = true; vector = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "mod"; version = "0.2.2.0"; };
      license = "MIT";
      copyright = "2017-2022 Andrew Lelechenko";
      maintainer = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      homepage = "https://github.com/Bodigrim/mod";
      url = "";
      synopsis = "Fast type-safe modular arithmetic";
      description = "<https://en.wikipedia.org/wiki/Modular_arithmetic Modular arithmetic>,\npromoting moduli to the type level, with an emphasis on performance.\nOriginally part of the <https://hackage.haskell.org/package/arithmoi arithmoi> package.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
        ] ++ pkgs.lib.optional (flags.semirings) (hsPkgs."semirings" or (errorHandler.buildDepError "semirings"))) ++ pkgs.lib.optionals (flags.vector) [
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "mod-tests" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mod" or (errorHandler.buildDepError "mod"))
            (hsPkgs."quickcheck-classes-base" or (errorHandler.buildDepError "quickcheck-classes-base"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ] ++ pkgs.lib.optionals (flags.semirings) [
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."semirings" or (errorHandler.buildDepError "semirings"))
          ]) ++ pkgs.lib.optionals (flags.vector) [
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."quickcheck-classes" or (errorHandler.buildDepError "quickcheck-classes"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "mod-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."mod" or (errorHandler.buildDepError "mod"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mod-0.2.2.0.tar.gz";
      sha256 = "09c9ff47b4e2a14bcaf5f6c9acdfbd9de43f7901a9c40804617555076cff9123";
    });
  }) // {
    package-description-override = "name:          mod\nversion:       0.2.2.0\ncabal-version: >=1.10\nbuild-type:    Simple\nlicense:       MIT\nlicense-file:  LICENSE\ncopyright:     2017-2022 Andrew Lelechenko\nmaintainer:    Andrew Lelechenko <andrew.lelechenko@gmail.com>\nhomepage:      https://github.com/Bodigrim/mod\nbug-reports:   https://github.com/Bodigrim/mod/issues\nsynopsis:      Fast type-safe modular arithmetic\ndescription:\n  <https://en.wikipedia.org/wiki/Modular_arithmetic Modular arithmetic>,\n  promoting moduli to the type level, with an emphasis on performance.\n  Originally part of the <https://hackage.haskell.org/package/arithmoi arithmoi> package.\ncategory:      Math, Number Theory\nauthor:        Andrew Lelechenko <andrew.lelechenko@gmail.com>\ntested-with:   GHC ==9.0.2 GHC ==9.2.8 GHC ==9.4.8 GHC ==9.6.7 GHC ==9.8.4 GHC ==9.10.3 GHC ==9.12.2 GHC ==9.14.1\nextra-source-files:\n  changelog.md\n  README.md\n  cbits/aarch64.h\n\nsource-repository head\n  type: git\n  location: https://github.com/Bodigrim/mod\n\nflag semirings\n  description: Derive semiring instances\n  default: True\n\nflag vector\n  description: Derive unboxed and primitive vector instances\n  default: True\n\nlibrary\n  build-depends:\n    base >=4.15.1 && <5,\n    deepseq <1.6,\n    ghc-bignum <1.5\n  if flag(semirings)\n    build-depends:\n      semirings >=0.5 && <0.8\n  if flag(vector)\n    build-depends:\n      primitive <0.10,\n      vector >=0.12 && <0.14\n  exposed-modules:\n    Data.Mod\n    Data.Mod.Word\n  other-modules:\n    Data.Mod.Compat\n  default-language: Haskell2010\n  ghc-options: -Wall -O2 -Wno-deprecations -Wcompat\n\n  if(arch(aarch64) && impl(ghc <9.12))\n    c-sources: cbits/aarch64.c\n    include-dirs: cbits\n\ntest-suite mod-tests\n  build-depends:\n    base >=4.10 && <5,\n    mod,\n    quickcheck-classes-base,\n    tasty >=0.10,\n    tasty-quickcheck >=0.9 && <0.12\n  if flag(semirings)\n    build-depends:\n      containers,\n      quickcheck-classes >=0.6.3,\n      semirings >= 0.5\n  if flag(vector)\n    build-depends:\n      primitive,\n      quickcheck-classes >=0.6.3,\n      vector >= 0.12\n  type: exitcode-stdio-1.0\n  main-is: Test.hs\n  default-language: Haskell2010\n  hs-source-dirs: test\n  ghc-options: -Wall -threaded -rtsopts -Wcompat\n\nbenchmark mod-bench\n  build-depends:\n    base,\n    mod,\n    -- finite-field >= 0.9,\n    -- finite-typelits,\n    -- modular,\n    -- modular-arithmetic >= 2,\n    tasty-bench >= 0.2.5\n  type: exitcode-stdio-1.0\n  main-is: Bench.hs\n  default-language: Haskell2010\n  hs-source-dirs: bench\n  ghc-options: -Wall -O2 -Wcompat\n";
  }