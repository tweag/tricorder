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
      specVersion = "1.12";
      identifier = { name = "data-sketches-core"; version = "0.3.0.0"; };
      license = "BSD-3-Clause";
      copyright = "2021 Ian Duncan, Rob Bassi, Mercury Technologies";
      maintainer = "ian@iankduncan.com";
      author = "Ian Duncan";
      homepage = "https://github.com/iand675/datasketches-haskell#readme";
      url = "";
      synopsis = "";
      description = "Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
        ];
        buildable = true;
      };
      tests = {
        "data-sketches-core-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-sketches-core" or (errorHandler.buildDepError "data-sketches-core"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/data-sketches-core-0.3.0.0.tar.gz";
      sha256 = "9522a834e8560a42c35c944e8c9f808d52c4933eb83187ebe2bfe905d698dceb";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\n\n-- This file has been generated from package.yaml by hpack version 0.38.1.\n--\n-- see: https://github.com/sol/hpack\n\nname:           data-sketches-core\nversion:        0.3.0.0\ndescription:    Please see the README on GitHub at <https://github.com/iand675/datasketches-haskell#readme>\nhomepage:       https://github.com/iand675/datasketches-haskell#readme\nbug-reports:    https://github.com/iand675/datasketches-haskell/issues\nauthor:         Ian Duncan\nmaintainer:     ian@iankduncan.com\ncopyright:      2021 Ian Duncan, Rob Bassi, Mercury Technologies\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\nextra-source-files:\n    README.md\n    ChangeLog.md\n    cbits/kll.h\n    cbits/req.h\n\nsource-repository head\n  type: git\n  location: https://github.com/iand675/datasketches-haskell\n\nlibrary\n  exposed-modules:\n      DataSketches.Quantiles.RelativeErrorQuantile.Internal.Constants\n      DataSketches.Quantiles.RelativeErrorQuantile.Types\n      DataSketches.Quantiles.KLL.Internal\n      DataSketches.Frequencies.CountMin.Internal\n      DataSketches.Distinct.HyperLogLog.Internal\n      DataSketches.Distinct.Theta.Internal\n      DataSketches.Core.Internal.CBindings\n      DataSketches.Quantiles.RelativeErrorQuantile.CInternal\n  other-modules:\n      Paths_data_sketches_core\n  hs-source-dirs:\n      src\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  include-dirs:\n      cbits\n  cc-options: -O2\n  c-sources:\n      cbits/sketches.c\n      cbits/kll.c\n      cbits/hll.c\n      cbits/countmin.c\n      cbits/theta.c\n      cbits/req.c\n  build-depends:\n      base >=4.7 && <5\n    , deepseq\n    , ghc-prim\n    , primitive\n    , vector\n  default-language: Haskell2010\n\ntest-suite data-sketches-core-test\n  type: exitcode-stdio-1.0\n  main-is: Spec.hs\n  other-modules:\n      Paths_data_sketches_core\n  hs-source-dirs:\n      test\n  default-extensions:\n      BangPatterns\n      FlexibleInstances\n      RecordWildCards\n      ScopedTypeVariables\n      StandaloneDeriving\n      TypeFamilies\n      TypeOperators\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  build-depends:\n      base >=4.7 && <5\n    , data-sketches-core\n    , deepseq\n    , ghc-prim\n    , primitive\n    , vector\n  default-language: Haskell2010\n";
  }