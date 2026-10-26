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
      specVersion = "3.8";
      identifier = { name = "effectful-core"; version = "2.7.1.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "andrzej@rybczak.net";
      author = "Andrzej Rybczak";
      homepage = "";
      url = "";
      synopsis = "An easy to use, performant extensible effects library.";
      description = "An easy to use, performant extensible effects library with seamless\nintegration with the existing Haskell ecosystem.\n\nThis library provides core definitions with a minimal dependency\nfootprint. See the @<https://hackage.haskell.org/package/effectful effectful>@\npackage for the \"batteries-included\" variant.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
          (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
          (hsPkgs."monad-control" or (errorHandler.buildDepError "monad-control"))
          (hsPkgs."primitive" or (errorHandler.buildDepError "primitive"))
          (hsPkgs."strict-mutable-base" or (errorHandler.buildDepError "strict-mutable-base"))
          (hsPkgs."transformers-base" or (errorHandler.buildDepError "transformers-base"))
          (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/effectful-core-2.7.1.2.tar.gz";
      sha256 = "4823fc60ba1a7c9369c1b3fc86621ef1a6e9a80a26ff26bebf93fe7e40d4d9a6";
    });
  }) // {
    package-description-override = "cabal-version:      3.8\nbuild-type:         Simple\nname:               effectful-core\nversion:            2.7.1.2\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\ncategory:           Control\nmaintainer:         andrzej@rybczak.net\nauthor:             Andrzej Rybczak\nsynopsis:           An easy to use, performant extensible effects library.\n\ndescription:\n  An easy to use, performant extensible effects library with seamless\n  integration with the existing Haskell ecosystem.\n\n  This library provides core definitions with a minimal dependency\n  footprint. See the @<https://hackage.haskell.org/package/effectful effectful>@\n  package for the \"batteries-included\" variant.\n\nextra-source-files:\n  CHANGELOG.md\n  README.md\n\ntested-with: GHC == { 9.6.7, 9.8.4, 9.10.3, 9.12.4, 9.14.1 }\n\nbug-reports:   https://github.com/haskell-effectful/effectful/issues\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-effectful/effectful.git\n\ncommon language\n    ghc-options:        -Wall\n                        -Wcompat\n                        -Werror=missing-deriving-strategies\n                        -Werror=prepositive-qualified-module\n\n    default-language:   GHC2021\n\n    default-extensions: DataKinds\n                        DeepSubsumption\n                        DerivingStrategies\n                        DuplicateRecordFields\n                        LambdaCase\n                        NoFieldSelectors\n                        NoStarIsType\n                        OverloadedRecordDot\n                        RoleAnnotations\n                        TypeFamilies\n                        UndecidableInstances\n\nlibrary\n    import:         language\n\n    -- -O2 enables -ffast-pap-calls, without which the handler invocation in\n    -- send and passthrough (an unknown call with 5 pointers and the State#\n    -- token that matches no precompiled RTS apply pattern) allocates an\n    -- intermediate PAP on every operation of a dynamically dispatched effect.\n    ghc-options:    -O2\n\n    build-depends:    base                >= 4.18      && < 5\n                    , containers          >= 0.6\n                    , deepseq             >= 1.2\n                    , exceptions          >= 0.10.4\n                    , mtl                 >= 2.2.1\n                    , monad-control       >= 1.0.3\n                    , primitive           >= 0.9.0.0\n                    , strict-mutable-base >= 2.0.0.0  && < 3\n                    , transformers-base   >= 0.4.6\n                    , unliftio-core       >= 0.2.0.1\n\n    hs-source-dirs:  src\n\n    exposed-modules: Effectful\n                     Effectful.Dispatch.Dynamic\n                     Effectful.Dispatch.Static\n                     Effectful.Dispatch.Static.Primitive\n                     Effectful.Dispatch.Static.Unsafe\n                     Effectful.Error.Dynamic\n                     Effectful.Error.Static\n                     Effectful.Exception\n                     Effectful.Fail\n                     Effectful.Input.Dynamic\n                     Effectful.Input.Static\n                     Effectful.Input.Static.Action\n                     Effectful.Internal.Effect\n                     Effectful.Internal.Effect.Dynamic\n                     Effectful.Internal.Env\n                     Effectful.Internal.Monad\n                     Effectful.Internal.Unlift\n                     Effectful.Internal.Utils\n                     Effectful.Internal.Utils.Word64Map\n                     Effectful.Labeled\n                     Effectful.Labeled.Error\n                     Effectful.Labeled.Input\n                     Effectful.Labeled.Output\n                     Effectful.Labeled.Provider\n                     Effectful.Labeled.Provider.List\n                     Effectful.Labeled.Reader\n                     Effectful.Labeled.ReturnWith\n                     Effectful.Labeled.State\n                     Effectful.Labeled.Writer\n                     Effectful.NonDet\n                     Effectful.Output.Dynamic\n                     Effectful.Output.Static.Action\n                     Effectful.Output.Static.Local.Array\n                     Effectful.Output.Static.Local.List\n                     Effectful.Output.Static.Shared.Array\n                     Effectful.Output.Static.Shared.List\n                     Effectful.Prim\n                     Effectful.Provider\n                     Effectful.Provider.List\n                     Effectful.Reader.Dynamic\n                     Effectful.Reader.Static\n                     Effectful.ReturnWith.Dynamic\n                     Effectful.ReturnWith.Static\n                     Effectful.State.Dynamic\n                     Effectful.State.Static.Local\n                     Effectful.State.Static.Shared\n                     Effectful.Writer.Dynamic\n                     Effectful.Writer.Static.Local\n                     Effectful.Writer.Static.Shared\n";
  }