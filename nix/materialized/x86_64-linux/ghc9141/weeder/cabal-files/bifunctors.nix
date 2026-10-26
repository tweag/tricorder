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
    flags = { tagged = true; };
    package = {
      specVersion = "1.24";
      identifier = { name = "bifunctors"; version = "5.6.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2008-2016 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/bifunctors/";
      url = "";
      synopsis = "Bifunctors";
      description = "Bifunctors.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."assoc" or (errorHandler.buildDepError "assoc"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
        ] ++ pkgs.lib.optionals (!(compiler.isGhc && compiler.version.ge "8.2")) [
          (hsPkgs."bifunctor-classes-compat" or (errorHandler.buildDepError "bifunctor-classes-compat"))
          (hsPkgs."transformers-compat" or (errorHandler.buildDepError "transformers-compat"))
        ]) ++ pkgs.lib.optional (flags.tagged) (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))) ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "9.6")) (hsPkgs."foldable1-classes-compat" or (errorHandler.buildDepError "foldable1-classes-compat"));
        buildable = true;
      };
      tests = {
        "bifunctors-spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
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
      url = "http://hackage.haskell.org/package/bifunctors-5.6.3.tar.gz";
      sha256 = "ad7a357f022f4c780c505040d73f1c06a4fd697b4a0bab6123bbd73b55d8115c";
    });
  }) // {
    package-description-override = "cabal-version: 1.24\r\nname:          bifunctors\r\ncategory:      Data, Functors\r\nversion:       5.6.3\r\nx-revision: 1\r\nlicense:       BSD3\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     provisional\r\nhomepage:      http://github.com/ekmett/bifunctors/\r\nbug-reports:   http://github.com/ekmett/bifunctors/issues\r\ncopyright:     Copyright (C) 2008-2016 Edward A. Kmett\r\nsynopsis:      Bifunctors\r\ndescription:   Bifunctors.\r\nbuild-type:    Simple\r\ntested-with:   GHC == 8.0.2\r\n             , GHC == 8.2.2\r\n             , GHC == 8.4.4\r\n             , GHC == 8.6.5\r\n             , GHC == 8.8.4\r\n             , GHC == 8.10.7\r\n             , GHC == 9.0.2\r\n             , GHC == 9.2.8\r\n             , GHC == 9.4.8\r\n             , GHC == 9.6.7\r\n             , GHC == 9.8.4\r\n             , GHC == 9.10.3\r\n             , GHC == 9.12.2\r\n             , GHC == 9.14.1\r\nextra-source-files:\r\n  CHANGELOG.markdown\r\n  README.markdown\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/bifunctors.git\r\n\r\nflag tagged\r\n  default: True\r\n  manual: True\r\n  description:\r\n    You can disable the use of the `tagged` package using `-f-tagged`.\r\n    .\r\n    Disabing this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\r\n\r\nlibrary\r\n  hs-source-dirs: src\r\n  build-depends:\r\n    base                     >= 4.9     && < 5,\r\n    assoc                    >= 1.1     && < 1.2,\r\n    comonad                  >= 5.0.7   && < 6,\r\n    containers               >= 0.5.7.1 && < 0.9,\r\n    template-haskell         >= 2.11    && < 2.25,\r\n    th-abstraction           >= 0.4.2.0 && < 0.8\r\n\r\n  if !impl(ghc >= 8.2)\r\n    build-depends:\r\n      bifunctor-classes-compat >= 0.1 && < 0.2,\r\n      transformers-compat      >= 0.6 && < 0.9\r\n\r\n  if flag(tagged)\r\n    build-depends: tagged >= 0.8.6 && < 1\r\n\r\n  if impl(ghc<8.1)\r\n    reexported-modules:\r\n        Data.Bifoldable\r\n      , Data.Bitraversable\r\n\r\n  if !impl(ghc >= 9.6)\r\n    build-depends: foldable1-classes-compat >= 0.1 && < 0.2\r\n\r\n  exposed-modules:\r\n    Data.Biapplicative\r\n    Data.Bifunctor.Biap\r\n    Data.Bifunctor.Biff\r\n    Data.Bifunctor.Clown\r\n    Data.Bifunctor.Fix\r\n    Data.Bifunctor.Flip\r\n    Data.Bifunctor.Functor\r\n    Data.Bifunctor.Join\r\n    Data.Bifunctor.Joker\r\n    Data.Bifunctor.Product\r\n    Data.Bifunctor.Sum\r\n    Data.Bifunctor.Tannen\r\n    Data.Bifunctor.TH\r\n    Data.Bifunctor.Wrapped\r\n\r\n  other-modules:\r\n    Data.Bifunctor.TH.Internal\r\n\r\n  ghc-options: -Wall\r\n  default-language: Haskell2010\r\n\r\n  if impl(ghc >= 9.0)\r\n    -- these flags may abort compilation with GHC-8.10\r\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\r\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\r\n\r\ntest-suite bifunctors-spec\r\n  type: exitcode-stdio-1.0\r\n  hs-source-dirs: tests\r\n  main-is: Spec.hs\r\n  other-modules: BifunctorSpec T89Spec\r\n  ghc-options: -Wall\r\n  if impl(ghc >= 8.6)\r\n    ghc-options: -Wno-star-is-type\r\n  default-language: Haskell2010\r\n  build-tool-depends: hspec-discover:hspec-discover >= 1.8\r\n  build-depends:\r\n    base                >= 4   && < 5,\r\n    bifunctors,\r\n    hspec               >= 1.8,\r\n    QuickCheck          >= 2   && < 3\r\n";
  }