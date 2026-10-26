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
      identifier = { name = "invariant"; version = "0.6.5"; };
      license = "BSD-2-Clause";
      copyright = "";
      maintainer = "Nicolas Frisby <nicolas.frisby@gmail.com>,\nRyan Scott <ryan.gl.scott@gmail.com>";
      author = "Nicolas Frisby <nicolas.frisby@gmail.com>";
      homepage = "https://github.com/nfrisby/invariant-functors";
      url = "";
      synopsis = "Haskell98 invariant functors";
      description = "Haskell98 invariant functors (also known as exponential functors).\n\nFor more information, see Edward Kmett's article \\\"Rotten Bananas\\\":\n\n<http://comonad.com/reader/2008/rotten-bananas/>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bifunctors" or (errorHandler.buildDepError "bifunctors"))
          (hsPkgs."comonad" or (errorHandler.buildDepError "comonad"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."contravariant" or (errorHandler.buildDepError "contravariant"))
          (hsPkgs."profunctors" or (errorHandler.buildDepError "profunctors"))
          (hsPkgs."StateVar" or (errorHandler.buildDepError "StateVar"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."th-abstraction" or (errorHandler.buildDepError "th-abstraction"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8.0")) (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."invariant" or (errorHandler.buildDepError "invariant"))
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
      url = "http://hackage.haskell.org/package/invariant-0.6.5.tar.gz";
      sha256 = "626bdec7c925fb0f15896dcc776992cb00a5fcf99211528c13e7535e72396e3a";
    });
  }) // {
    package-description-override = "name:                invariant\nversion:             0.6.5\nsynopsis:            Haskell98 invariant functors\ndescription:         Haskell98 invariant functors (also known as exponential functors).\n                     .\n                     For more information, see Edward Kmett's article \\\"Rotten Bananas\\\":\n                     .\n                     <http://comonad.com/reader/2008/rotten-bananas/>\ncategory:            Control, Data\nlicense:             BSD2\nlicense-file:        LICENSE\nhomepage:            https://github.com/nfrisby/invariant-functors\nbug-reports:         https://github.com/nfrisby/invariant-functors/issues\nauthor:              Nicolas Frisby <nicolas.frisby@gmail.com>\nmaintainer:          Nicolas Frisby <nicolas.frisby@gmail.com>,\n                     Ryan Scott <ryan.gl.scott@gmail.com>\nbuild-type:          Simple\ncabal-version:       >= 1.10\ntested-with:         GHC == 8.0.2\n                   , GHC == 8.2.2\n                   , GHC == 8.4.4\n                   , GHC == 8.6.5\n                   , GHC == 8.8.4\n                   , GHC == 8.10.7\n                   , GHC == 9.0.2\n                   , GHC == 9.2.8\n                   , GHC == 9.4.8\n                   , GHC == 9.6.7\n                   , GHC == 9.8.4\n                   , GHC == 9.10.3\n                   , GHC == 9.12.2\n                   , GHC == 9.14.1\nextra-source-files:  CHANGELOG.md, README.md\n\nsource-repository head\n  type:                git\n  location:            https://github.com/nfrisby/invariant-functors\n\nlibrary\n  exposed-modules:     Data.Functor.Invariant\n                     , Data.Functor.Invariant.TH\n  other-modules:       Data.Functor.Invariant.TH.Internal\n                     , Paths_invariant\n  hs-source-dirs:      src\n  default-language:    Haskell2010\n  build-depends:       array                >= 0.3    && < 0.6\n                     , base                 >= 4.9    && < 5\n                     , bifunctors           >= 5.2    && < 6\n                     , comonad              >= 5      && < 6\n                     , containers           >= 0.1    && < 0.9\n                     , contravariant        >= 0.5    && < 2\n                     , profunctors          >= 5.2.1  && < 6\n                     , StateVar             >= 1.1    && < 2\n                     , stm                  >= 2.2    && < 3\n                     , tagged               >= 0.7.3  && < 1\n                     , template-haskell     >= 2.11   && < 2.25\n                     , th-abstraction       >= 0.5    && < 0.8\n                     , transformers         >= 0.2    && < 0.7\n                     , unordered-containers >= 0.2.4  && < 0.3\n  ghc-options:         -Wall\n\n  if !impl(ghc >= 8.0)\n    build-depends:     semigroups           >= 0.16.2 && < 1\n\ntest-suite spec\n  type:                exitcode-stdio-1.0\n  hs-source-dirs:      test\n  default-language:    Haskell2010\n  main-is:             Spec.hs\n  other-modules:       InvariantSpec\n                       THSpec\n  build-depends:       base             >= 4    && < 5\n                     , hspec            >= 1.8\n                     , invariant\n                     , QuickCheck       >= 2.11 && < 3\n  build-tool-depends:  hspec-discover:hspec-discover\n  ghc-options:         -Wall\n  if impl(ghc >= 8.6)\n    ghc-options:       -Wno-star-is-type\n";
  }