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
      specVersion = "1.10";
      identifier = { name = "distributive"; version = "0.6.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2011-2016 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/distributive/";
      url = "";
      synopsis = "Distributive functors -- Dual to Traversable";
      description = "Distributive functors -- Dual to @Traversable@";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ pkgs.lib.optional (flags.tagged) (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"));
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."distributive" or (errorHandler.buildDepError "distributive"))
            (hsPkgs."generic-deriving" or (errorHandler.buildDepError "generic-deriving"))
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
      url = "http://hackage.haskell.org/package/distributive-0.6.3.tar.gz";
      sha256 = "aeeb028a23db9f9b073e24a6bd766b79b9d58c2b407b06bf33296c27e9264baa";
    });
  }) // {
    package-description-override = "name:          distributive\ncategory:      Data Structures\nversion:       0.6.3\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     provisional\nhomepage:      http://github.com/ekmett/distributive/\nbug-reports:   http://github.com/ekmett/distributive/issues\ncopyright:     Copyright (C) 2011-2016 Edward A. Kmett\nsynopsis:      Distributive functors -- Dual to Traversable\ndescription:   Distributive functors -- Dual to @Traversable@\nbuild-type:    Simple\ntested-with:   GHC == 8.0.2\n             , GHC == 8.2.2\n             , GHC == 8.4.4\n             , GHC == 8.6.5\n             , GHC == 8.8.4\n             , GHC == 8.10.4\n             , GHC == 9.0.2\n             , GHC == 9.2.8\n             , GHC == 9.4.8\n             , GHC == 9.6.7\n             , GHC == 9.8.4\n             , GHC == 9.10.3\n             , GHC == 9.12.2\n             , GHC == 9.14.1\nextra-source-files:\n  .hlint.yaml\n  .vim.custom\n  config\n  CHANGELOG.markdown\n  README.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/distributive.git\n\nflag tagged\n  manual: True\n  default: True\n  description:\n    You can disable the use of the `tagged` package using `-f-tagged`.\n    .\n    Disabling this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\n\nlibrary\n  build-depends:\n    base                >= 4.9 && < 5,\n    transformers        >= 0.3 && < 0.7\n\n  hs-source-dirs:  src\n  exposed-modules:\n    Data.Distributive\n    Data.Distributive.Generic\n\n  if flag(tagged)\n    build-depends: tagged >= 0.7 && < 1\n\n  ghc-options: -Wall\n\n  if impl(ghc >= 9.0)\n    -- these flags may abort compilation with GHC-8.10\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\n\n  default-language: Haskell2010\n\ntest-suite spec\n  type:           exitcode-stdio-1.0\n  hs-source-dirs: tests\n  build-tool-depends:\n    hspec-discover:hspec-discover\n\n  build-depends:\n    base             >= 4    && < 5,\n    distributive,\n    generic-deriving >= 1.11 && < 2,\n    hspec            >= 2    && < 3\n\n  main-is: Spec.hs\n  other-modules: GenericsSpec\n\n  ghc-options: -Wall -threaded -rtsopts\n  default-language: Haskell2010\n";
  }