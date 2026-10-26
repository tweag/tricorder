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
    flags = { statevar = true; };
    package = {
      specVersion = "1.10";
      identifier = { name = "contravariant"; version = "1.5.6"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2007-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/contravariant/";
      url = "";
      synopsis = "Contravariant functors";
      description = "Contravariant functors.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ pkgs.lib.optional (flags.statevar) (hsPkgs."StateVar" or (errorHandler.buildDepError "StateVar"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/contravariant-1.5.6.tar.gz";
      sha256 = "65f3260354ee5fd1f2c7ffc54cff99d22b794c254f053734979ad37820e6efe3";
    });
  }) // {
    package-description-override = "name:          contravariant\ncategory:      Control, Data\nversion:       1.5.6\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     provisional\nhomepage:      http://github.com/ekmett/contravariant/\nbug-reports:   http://github.com/ekmett/contravariant/issues\ncopyright:     Copyright (C) 2007-2015 Edward A. Kmett\nsynopsis:      Contravariant functors\ndescription:   Contravariant functors.\nbuild-type:    Simple\ntested-with:   GHC == 8.0.2\n             , GHC == 8.2.2\n             , GHC == 8.4.4\n             , GHC == 8.6.5\n             , GHC == 8.8.4\n             , GHC == 8.10.7\n             , GHC == 9.0.2\n             , GHC == 9.2.8\n             , GHC == 9.4.8\n             , GHC == 9.6.7\n             , GHC == 9.8.4\n             , GHC == 9.10.3\n             , GHC == 9.12.2\n             , GHC == 9.14.1\nextra-source-files:\n  .hlint.yaml\n  CHANGELOG.markdown\n  README.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/contravariant.git\n\nflag StateVar\n  description:\n    You can disable the use of the `StateVar` package using `-f-StateVar`.\n    .\n    Disabling this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\n  default: True\n  manual: True\n\nlibrary\n  hs-source-dirs: src\n  build-depends:\n    base         >= 4.9 && < 5,\n    transformers >= 0.3 && < 0.7\n\n  if flag(StateVar)\n    build-depends: StateVar >= 1.2.1 && < 1.3\n\n  exposed-modules:\n    Data.Functor.Contravariant.Compose\n    Data.Functor.Contravariant.Divisible\n\n  if impl(ghc)\n    -- MicroHs doesn't support type families yet\n    exposed-modules:\n      Data.Functor.Contravariant.Generic\n\n  if impl(ghc < 8.5)\n    hs-source-dirs: old-src\n    exposed-modules: Data.Functor.Contravariant\n\n  if impl(ghc >= 8.6)\n    ghc-options: -Wno-star-is-type\n\n  if impl(ghc >= 9.0)\n    -- these flags may abort compilation with GHC-8.10\n    -- https://gitlab.haskell.org/ghc/ghc/-/merge_requests/3295\n    ghc-options: -Winferred-safe-imports -Wmissing-safe-haskell-mode\n\n  ghc-options: -Wall\n  default-language: Haskell2010\n";
  }