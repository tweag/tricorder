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
      identifier = { name = "opentelemetry"; version = "0.8.0"; };
      license = "Apache-2.0";
      copyright = "";
      maintainer = "ethercrow@gmail.com";
      author = "Dmitry Ivanov";
      homepage = "";
      url = "";
      synopsis = "";
      description = "The OpenTelemetry Haskell Client https://opentelemetry.io";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."ghc-trace-events" or (errorHandler.buildDepError "ghc-trace-events"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/opentelemetry-0.8.0.tar.gz";
      sha256 = "e9bf1c3876de1be12e0cb1d7eeb758527e863989ea6f088a7241b2cb0493e415";
    });
  }) // {
    package-description-override = "cabal-version:       2.4\nname:                opentelemetry\ndescription:         The OpenTelemetry Haskell Client https://opentelemetry.io\ncategory:            OpenTelemetry\nversion: 0.8.0\nlicense-file:        LICENSE\nlicense:             Apache-2.0\nauthor:              Dmitry Ivanov\nmaintainer:          ethercrow@gmail.com\nbuild-type:          Simple\n\nsource-repository head\n  type: git\n  location: https://github.com/ethercrow/opentelemetry-haskell\n\ncommon options\n  default-language: Haskell2010\n  default-extensions:\n    BangPatterns\n    BlockArguments\n    DataKinds\n    DeriveGeneric\n    DerivingStrategies\n    DerivingVia\n    FlexibleInstances\n    InstanceSigs\n    LambdaCase\n    MultiParamTypeClasses\n    MultiWayIf\n    NamedFieldPuns\n    NumericUnderscores\n    RecordWildCards\n    ScopedTypeVariables\n    TupleSections\n    TypeApplications\n    ViewPatterns\n  ghc-options:\n    -Wall\n    -Wcompat\n    -Widentities\n    -Wincomplete-record-updates\n    -Wincomplete-uni-patterns\n    -Wpartial-fields\n    -fhide-source-paths\n    -ferror-spans\n    -freverse-errors\n\nlibrary\n  import: options\n  build-depends:\n    base >= 4.12 && < 5,\n    bytestring,\n    ghc-trace-events >= 0.1.0.1,\n    hashable,\n    exceptions\n  hs-source-dirs: src\n  exposed-modules:\n    OpenTelemetry.SpanContext\n    OpenTelemetry.Propagation\n    OpenTelemetry.Eventlog\n    OpenTelemetry.Metrics_Internal\n    OpenTelemetry.Eventlog_Internal\n";
  }