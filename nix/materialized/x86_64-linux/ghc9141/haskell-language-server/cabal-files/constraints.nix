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
      specVersion = "2.4";
      identifier = { name = "constraints"; version = "0.14.4"; };
      license = "BSD-2-Clause";
      copyright = "Copyright (C) 2011-2021 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/constraints/";
      url = "";
      synopsis = "Constraint manipulation";
      description = "GHC 7.4 gave us the ability to talk about @ConstraintKinds@. They stopped crashing the compiler in GHC 7.6.\n\nThis package provides a vocabulary for working with them.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."boring" or (errorHandler.buildDepError "boring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ (if compiler.isGhc && compiler.version.ge "9.15"
          then [
            (hsPkgs."ghc-bignum" or (errorHandler.buildDepError "ghc-bignum"))
          ]
          else pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.0") (hsPkgs."integer-gmp" or (errorHandler.buildDepError "integer-gmp")));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."constraints" or (errorHandler.buildDepError "constraints"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/constraints-0.14.4.tar.gz";
      sha256 = "808021e217c39eb4aaa76cf85abf43f4e5bf4396143d86bb2275068dd8bb6d39";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname:          constraints\ncategory:      Constraints\nversion:       0.14.4\nlicense:       BSD-2-Clause\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     experimental\nhomepage:      http://github.com/ekmett/constraints/\nbug-reports:   http://github.com/ekmett/constraints/issues\ncopyright:     Copyright (C) 2011-2021 Edward A. Kmett\nsynopsis:      Constraint manipulation\ndescription:\n  GHC 7.4 gave us the ability to talk about @ConstraintKinds@. They stopped crashing the compiler in GHC 7.6.\n  .\n  This package provides a vocabulary for working with them.\n\nbuild-type:    Simple\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n\nextra-source-files: README.markdown\n                  , CHANGELOG.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/constraints.git\n\nlibrary\n  hs-source-dirs: src\n\n  default-language: Haskell2010\n  other-extensions:\n    FunctionalDependencies,\n    ScopedTypeVariables,\n    StandaloneDeriving,\n    FlexibleInstances,\n    FlexibleContexts,\n    ConstraintKinds,\n    KindSignatures,\n    TypeOperators,\n    Rank2Types,\n    GADTs\n\n  build-depends:\n    , base           >= 4.12  && < 5\n    , binary         >= 0.7.1 && < 0.9\n    , boring         >= 0.2   && < 0.3\n    , deepseq        >= 1.3   && < 1.6\n    , hashable       >= 1.2   && < 1.6\n    , mtl            >= 2.2   && < 2.4\n    , transformers   >= 0.5   && < 0.7\n  if impl(ghc >= 9.15)\n    build-depends:\n      ghc-bignum\n  elif impl(ghc < 9.0)\n    build-depends:\n      integer-gmp\n\n  exposed-modules:\n    Data.Constraint\n    Data.Constraint.Deferrable\n    Data.Constraint.Forall\n    Data.Constraint.Lifting\n    Data.Constraint.Nat\n    Data.Constraint.Symbol\n    Data.Constraint.Unsafe\n\n  if impl(ghc >= 9.2)\n    exposed-modules:\n      Data.Constraint.Char\n\n  ghc-options: -Wall -Wno-star-is-type\n\ntest-suite spec\n  type: exitcode-stdio-1.0\n  default-language: Haskell2010\n  hs-source-dirs: tests\n  main-is: Spec.hs\n  other-modules: GH55Spec\n                 GH117Spec\n  ghc-options: -Wall -threaded -rtsopts\n  build-tool-depends: hspec-discover:hspec-discover >= 2\n  build-depends:\n    , base\n    , constraints\n    , hspec >= 2\n";
  }