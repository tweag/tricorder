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
    flags = {
      five = false;
      five-three = true;
      mtl = true;
      generic-deriving = true;
    };
    package = {
      specVersion = "1.10";
      identifier = { name = "transformers-compat"; version = "0.8"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2012-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "https://github.com/ekmett/transformers-compat/";
      url = "";
      synopsis = "A small compatibility shim for the transformers library";
      description = "This package includes backported versions of types that were added to\n@transformers@ in @transformers-0.5@ for users who need strict\n@transformers-0.5@ compatibility, but also need those types.\n\nThose users should be able to just depend on @transformers >= 0.5@ and\n@transformers-compat >= 0.7.3@.\n\nNote: missing methods are not supplied, but this at least permits the types to be used.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ] ++ [
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ]) ++ [
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/transformers-compat-0.8.tar.gz";
      sha256 = "f05c2145ee8d77ed773908d27a77c7f8be4d9419af90a757076b799c4a194da8";
    });
  }) // {
    package-description-override = "name:          transformers-compat\ncategory:      Compatibility\nversion:       0.8\nlicense:       BSD3\ncabal-version: >= 1.10\nlicense-file:  LICENSE\nauthor:        Edward A. Kmett\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\nstability:     provisional\nhomepage:      https://github.com/ekmett/transformers-compat/\nbug-reports:   https://github.com/ekmett/transformers-compat/issues\ncopyright:     Copyright (C) 2012-2015 Edward A. Kmett\nsynopsis:      A small compatibility shim for the transformers library\ndescription:\n  This package includes backported versions of types that were added to\n  @transformers@ in @transformers-0.5@ for users who need strict\n  @transformers-0.5@ compatibility, but also need those types.\n  .\n  Those users should be able to just depend on @transformers >= 0.5@ and\n  @transformers-compat >= 0.7.3@.\n  .\n  Note: missing methods are not supplied, but this at least permits the types to be used.\n\nbuild-type:    Simple\ntested-with:   GHC == 8.0.2\n             , GHC == 8.2.2\n             , GHC == 8.4.4\n             , GHC == 8.6.5\n             , GHC == 8.8.4\n             , GHC == 8.10.7\n             , GHC == 9.0.2\n             , GHC == 9.2.8\n             , GHC == 9.4.8\n             , GHC == 9.6.7\n             , GHC == 9.8.4\n             , GHC == 9.10.3\n             , GHC == 9.12.2\n             , GHC == 9.14.1\nextra-source-files:\n  .ghci\n  .gitignore\n  .hlint.yaml\n  .vim.custom\n  config\n  tests/*.hs\n  tests/LICENSE\n  tests/transformers-compat-tests.cabal\n  README.markdown\n  CHANGELOG.markdown\n\nsource-repository head\n  type: git\n  location: https://github.com/ekmett/transformers-compat.git\n\nflag five\n  default: False\n  manual: False\n  description: Use transformers 0.5 up until (but not including) 0.5.3. This will be selected by cabal picking the appropriate version.\n\nflag five-three\n  default: True\n  manual: False\n  description: Use transformers 0.5.3. This will be selected by cabal picking the appropriate version.\n\nflag mtl\n  default: True\n  manual: True\n  description: -f-mtl Disables support for mtl for transformers 0.2 and 0.3. That is an unsupported configuration, and results in missing instances for `ExceptT`.\n\nflag generic-deriving\n  default: True\n  manual: True\n  description: -f-generic-deriving prevents generic-deriving from being built as a dependency.\n               This disables certain aspects of generics for older versions of GHC. In particular,\n               Generic(1) instances will not be backported prior to GHC 7.2, and generic operations\n               over unlifted types will not be backported prior to GHC 8.0. This is an unsupported\n               configuration.\n\nlibrary\n  build-depends:\n    base >= 4.9 && < 5,\n    -- These are all transformers versions we support.\n    -- each flag below splits this interval into two parts.\n    -- flag-true parts are mutually exclusive, so at least one have to be on.\n    transformers >= 0.5 && <0.7\n\n  hs-source-dirs:\n    src\n\n  exposed-modules:\n    Control.Monad.Trans.Instances\n\n  other-modules:\n    Paths_transformers_compat\n\n  default-language:\n    Haskell2010\n\n  -- automatic flags\n  if flag(five-three)\n    build-depends: transformers >= 0.5.3\n  else\n    build-depends: transformers < 0.5.3\n\n  if flag(five)\n    hs-source-dirs: 0.5\n    build-depends: transformers >= 0.5 && < 0.5.3\n  else\n    build-depends: transformers >= 0.5.3\n\n  -- other flags\n  if impl(ghc) && flag(generic-deriving)\n    hs-source-dirs: generics\n    exposed-modules:\n      Data.Functor.Classes.Generic\n      Data.Functor.Classes.Generic.Internal\n\n  if flag(mtl)\n    cpp-options: -DMTL\n\n  if !flag(mtl) && !flag(generic-deriving)\n    cpp-options: -DHASKELL98\n\n  if flag(five)\n    exposed-modules:\n      Control.Monad.Trans.Accum\n      Control.Monad.Trans.Select\n";
  }