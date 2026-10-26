{ system
  , compiler
  , flags
  , pkgs
  , hsPkgs
  , pkgconfPkgs
  , errorHandler
  , config
  , ... }:
  {
    flags = {};
    package = {
      specVersion = "2.0";
      identifier = { name = "atelier-core"; version = "0.8.1.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "victor.bakke@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/tweag/tricorder#readme";
      url = "";
      synopsis = "Foundational Effectful-based effects and utilities";
      description = "Core effects and utilities for effect-based applications, built on Effectful — part of the atelier toolkit.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "CHANGELOG.md" "README.md" ];
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."base64-bytestring" or (errorHandler.buildDepError "base64-bytestring"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."casing" or (errorHandler.buildDepError "casing"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."daemons" or (errorHandler.buildDepError "daemons"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
          (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
          (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
          (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."fsnotify" or (errorHandler.buildDepError "fsnotify"))
          (hsPkgs."http-api-data" or (errorHandler.buildDepError "http-api-data"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."ki" or (errorHandler.buildDepError "ki"))
          (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."prometheus-client" or (errorHandler.buildDepError "prometheus-client"))
          (hsPkgs."prometheus-metrics-ghc" or (errorHandler.buildDepError "prometheus-metrics-ghc"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."time-units" or (errorHandler.buildDepError "time-units"))
          (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
          (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."uuid" or (errorHandler.buildDepError "uuid"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
        ];
        buildable = true;
        modules = [
          "Paths_atelier_core"
          "Atelier/Config"
          "Atelier/Effects/Arguments"
          "Atelier/Effects/Arguments/Switch"
          "Atelier/Effects/Await"
          "Atelier/Effects/Cache"
          "Atelier/Effects/Cache/Config"
          "Atelier/Effects/Cache/Singleflight"
          "Atelier/Effects/Chan"
          "Atelier/Effects/Clock"
          "Atelier/Effects/Conc"
          "Atelier/Effects/Console"
          "Atelier/Effects/Debounce"
          "Atelier/Effects/Delay"
          "Atelier/Effects/Env"
          "Atelier/Effects/Exit"
          "Atelier/Effects/File"
          "Atelier/Effects/FileSystem"
          "Atelier/Effects/FileSystem/Glob"
          "Atelier/Effects/FileWatcher"
          "Atelier/Effects/FileWatcher/Event"
          "Atelier/Effects/FileWatcher/Watch"
          "Atelier/Effects/FSNotify"
          "Atelier/Effects/FSNotify/Devel"
          "Atelier/Effects/GenUUID"
          "Atelier/Effects/Input"
          "Atelier/Effects/Internal/Coroutine"
          "Atelier/Effects/Iterator"
          "Atelier/Effects/Log"
          "Atelier/Effects/Posix/Daemons"
          "Atelier/Effects/Posix/IO"
          "Atelier/Effects/Process"
          "Atelier/Effects/Process/Internal"
          "Atelier/Effects/PubSub"
          "Atelier/Effects/PubSub/Pub"
          "Atelier/Effects/PubSub/Sub"
          "Atelier/Effects/Reader"
          "Atelier/Effects/Tally"
          "Atelier/Effects/Timeout"
          "Atelier/Effects/Yield"
          "Atelier/Exception"
          "Atelier/Signal"
          "Atelier/Time"
          "Atelier/Types/HttpApiDataReadShow"
          "Atelier/Types/JSON/Base64"
          "Atelier/Types/JSON/QuietSnake"
          "Atelier/Types/JSON/ReadShow"
          "Atelier/Types/JSON/Renamed"
          "Atelier/Types/JSON/StringLiteral"
          "Atelier/Types/JSON/WithDefaults"
          "Atelier/Types/Semaphore"
          "Atelier/Types/Semaphore/STM"
        ];
        hsSourceDirs = [ "src" ];
      };
      tests = {
        "atelier-test" = {
          depends = [
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hedgehog" or (errorHandler.buildDepError "tasty-hedgehog"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
          modules = [
            "Unit/Atelier/ConfigSpec"
            "Unit/Atelier/Effects/Arguments/SwitchSpec"
            "Unit/Atelier/Effects/AwaitSpec"
            "Unit/Atelier/Effects/Cache/SingleflightSpec"
            "Unit/Atelier/Effects/CacheSpec"
            "Unit/Atelier/Effects/ChanSpec"
            "Unit/Atelier/Effects/Conc/TeardownStressSpec"
            "Unit/Atelier/Effects/ConcSpec"
            "Unit/Atelier/Effects/ConsoleSpec"
            "Unit/Atelier/Effects/DebounceSpec"
            "Unit/Atelier/Effects/FileSystemSpec"
            "Unit/Atelier/Effects/FileWatcherSpec"
            "Unit/Atelier/Effects/IteratorSpec"
            "Unit/Atelier/Effects/LogSpec"
            "Unit/Atelier/Effects/PubSub/PubSpec"
            "Unit/Atelier/Effects/PubSubSpec"
            "Unit/Atelier/Effects/TallySpec"
            "Unit/Atelier/Effects/YieldSpec"
            "Unit/Atelier/Types/JSON/WithDefaultsSpec"
            "Unit/Atelier/Types/Semaphore/STMSpec"
            "Unit/Atelier/Types/SemaphoreSpec"
            "Paths_atelier_core"
          ];
          hsSourceDirs = [ "test" ];
          mainPath = [ "Driver.hs" ];
        };
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../packages/atelier-core; }