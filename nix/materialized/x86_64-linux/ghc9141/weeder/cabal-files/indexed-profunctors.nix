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
      specVersion = "2.2";
      identifier = { name = "indexed-profunctors"; version = "0.1.1.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "optics@well-typed.com";
      author = "Adam Gundry, Andres Löh, Andrzej Rybczak, Oleg Grenrus";
      homepage = "";
      url = "";
      synopsis = "Utilities for indexed profunctors";
      description = "This package contains basic definitions related to indexed profunctors.  These\nare primarily intended as internal utilities to support the @optics@ and\n@generic-lens@ package families.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/indexed-profunctors-0.1.1.1.tar.gz";
      sha256 = "2e69bb2900bb7e562efffff7bcf3f72daf79f013232ce603263a57595412c398";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname:          indexed-profunctors\nversion:       0.1.1.1\nlicense:       BSD-3-Clause\nlicense-file:  LICENSE\nbuild-type:    Simple\nmaintainer:    optics@well-typed.com\nauthor:        Adam Gundry, Andres Löh, Andrzej Rybczak, Oleg Grenrus\ntested-with:   GHC ==8.2.2 || ==8.4.4 || ==8.6.5 || ==8.8.4 || ==8.10.7\n                || ==9.0.2 || ==9.2.8 || ==9.4.5 || ==9.6.2, GHCJS ==8.4\nsynopsis:      Utilities for indexed profunctors\ncategory:      Data, Optics, Lenses, Profunctors\ndescription:\n  This package contains basic definitions related to indexed profunctors.  These\n  are primarily intended as internal utilities to support the @optics@ and\n  @generic-lens@ package families.\n\nextra-doc-files:\n  CHANGELOG.md\n\nbug-reports:   https://github.com/well-typed/optics/issues\nsource-repository head\n  type:     git\n  location: https://github.com/well-typed/optics.git\n  subdir:   indexed-profunctors\n\ncommon language\n    ghc-options:        -Wall -Wcompat\n\n    default-language:   Haskell2010\n\n    default-extensions: BangPatterns\n                        ConstraintKinds\n                        DefaultSignatures\n                        DeriveFoldable\n                        DeriveFunctor\n                        DeriveGeneric\n                        DeriveTraversable\n                        EmptyCase\n                        FlexibleContexts\n                        FlexibleInstances\n                        FunctionalDependencies\n                        GADTs\n                        GeneralizedNewtypeDeriving\n                        InstanceSigs\n                        KindSignatures\n                        LambdaCase\n                        OverloadedLabels\n                        PatternSynonyms\n                        RankNTypes\n                        ScopedTypeVariables\n                        TupleSections\n                        TypeApplications\n                        TypeFamilies\n                        TypeOperators\n                        ViewPatterns\n\nlibrary\n  import:           language\n  hs-source-dirs:   src\n\n  build-depends: base                   >= 4.10       && <5\n\n  exposed-modules:    Data.Profunctor.Indexed\n";
  }