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
    flags = { containers = true; unordered-containers = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "semirings"; version = "0.7"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2018 chessai";
      maintainer = "chessai <chessai1996@gmail.com>";
      author = "chessai";
      homepage = "http://github.com/chessai/semirings";
      url = "";
      synopsis = "two monoids as one, in holy haskimony";
      description = "Haskellers are usually familiar with monoids and semigroups. A monoid has an appending operation `<>` (or `mappend`),\nand an identity element, `mempty`. A semigroup has an appending `<>` operation, but does not require a `mempty` element.\n\nA Semiring has two appending operations, `plus` and `times`, and two respective identity elements, `zero` and `one`.\n\nMore formally, a Semiring R is a set equipped with two binary relations `+` and `*`, such that:\n\n(R,+) is a commutative monoid with identity element 0,\n\n(R,*) is a monoid with identity element 1,\n\n(*) left and right distributes over addition, and\n\nmultiplication by '0' annihilates R.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.6.1") (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))) ++ pkgs.lib.optional (flags.containers) (hsPkgs."containers" or (errorHandler.buildDepError "containers"))) ++ pkgs.lib.optionals (flags.unordered-containers) [
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/semirings-0.7.tar.gz";
      sha256 = "8fc80ae222196de2c7426e4be011d1f0ba3ee55ac5d268a705c5beeb83fe5de6";
    });
  }) // {
    package-description-override = "name:          semirings\ncategory:      Algebra, Data, Data Structures, Math, Maths, Mathematics\nversion:       0.7\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        chessai\nmaintainer:    chessai <chessai1996@gmail.com>\nstability:     provisional\nhomepage:      http://github.com/chessai/semirings\nbug-reports:   http://github.com/chessai/semirings/issues\ncopyright:     Copyright (C) 2018 chessai\nsynopsis:      two monoids as one, in holy haskimony\ndescription:\n  Haskellers are usually familiar with monoids and semigroups. A monoid has an appending operation `<>` (or `mappend`),\n  and an identity element, `mempty`. A semigroup has an appending `<>` operation, but does not require a `mempty` element.\n  .\n  A Semiring has two appending operations, `plus` and `times`, and two respective identity elements, `zero` and `one`.\n  .\n  More formally, a Semiring R is a set equipped with two binary relations `+` and `*`, such that:\n  .\n  (R,+) is a commutative monoid with identity element 0,\n  .\n  (R,*) is a monoid with identity element 1,\n  .\n  (*) left and right distributes over addition, and\n  .\n  multiplication by '0' annihilates R.\n\nbuild-type:    Simple\nextra-source-files: README.md CHANGELOG.md\ntested-with:\n  GHC == 8.0\n  GHC == 8.2\n  GHC == 8.4\n  GHC == 8.6\n  GHC == 8.8\n  GHC == 8.10\n  GHC == 9.0\n  GHC == 9.2\n  GHC == 9.4\n  GHC == 9.6\n\nsource-repository head\n  type: git\n  location: git://github.com/chessai/semirings.git\n\nflag containers\n  description:\n    You can disable the use of the `containers` package using `-f-containers`.\n    .\n    Disabling this may be useful for accelerating builds in sandboxes for expert users.\n  default: True\n  manual: True\n\nflag unordered-containers\n  description:\n    You can disable the use of the `unordered-containers` package using `-f-unordered-containers`.\n    .\n    Disabling this may be useful for accelerating builds in sandboxes for expert users.\n  default: True\n  manual: True\n\nlibrary\n  default-language: Haskell98\n  ghc-options: -Wall\n\n  build-depends:\n      base >= 4.8 && < 5\n  exposed-modules:\n    Data.Euclidean\n    Data.Field\n    Data.Ring.Ordered\n    Data.Semiring\n    Data.Star\n    Data.Semiring.Directed\n    Data.Semiring.Tropical\n    Data.Semiring.Generic\n\n  if impl(ghc < 8.6.1)\n    build-depends: template-haskell >= 2.4.0.0\n\n  if flag(containers)\n    build-depends: containers >= 0.5.4\n\n  if flag(unordered-containers)\n    build-depends:\n        hashable >= 1.1\n      , unordered-containers >= 0.2\n";
  }