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
      identifier = { name = "tricorder"; version = "0.7.0.0"; };
      license = "MIT";
      copyright = "";
      maintainer = "victor.bakke@tweag.io";
      author = "Christian Georgii";
      homepage = "https://github.com/tweag/tricorder#readme";
      url = "";
      synopsis = "Continuous Haskell build status, diagnostics, and tests via a shared daemon";
      description = "tricorder rebuilds your Haskell project continuously and surfaces build status, diagnostics, test results, and documentation - for developers and LLM coding agents. Like ghcid and ghciwatch it reloads on every change, but builds run in a background daemon so multiple clients (an interactive TUI, a status CLI, an agent skill) share a single build state without triggering redundant rebuilds. It discovers components across multi-package cabal.project workspaces automatically and ships context-friendly output for agentic use via the CLI.";
      buildType = "Simple";
      isLocal = true;
      detailLevel = "FullDetails";
      licenseFiles = [ "LICENSE" ];
      dataDir = ".";
      dataFiles = [];
      extraSrcFiles = [];
      extraTmpFiles = [];
      extraDocFiles = [ "README.md" "CHANGELOG.md" ];
    };
    components = {
      sublibs = {
        "tricorder-internal" = {
          depends = [
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."atelier-core" or (errorHandler.buildDepError "atelier-core"))
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."brick" or (errorHandler.buildDepError "brick"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."casing" or (errorHandler.buildDepError "casing"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."effectful" or (errorHandler.buildDepError "effectful"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."effectful-th" or (errorHandler.buildDepError "effectful-th"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."relude" or (errorHandler.buildDepError "relude"))
            (hsPkgs."req" or (errorHandler.buildDepError "req"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."time-units" or (errorHandler.buildDepError "time-units"))
            (hsPkgs."tricorder-types" or (errorHandler.buildDepError "tricorder-types"))
            (hsPkgs."vty" or (errorHandler.buildDepError "vty"))
            (hsPkgs."vty-crossplatform" or (errorHandler.buildDepError "vty-crossplatform"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
          ];
          buildable = true;
          modules = [
            "Paths_tricorder"
            "Tricorder/Build"
            "Tricorder/Build/ByteSize"
            "Tricorder/Build/Changes"
            "Tricorder/Build/Duration"
            "Tricorder/Build/EvalComment"
            "Tricorder/Build/Test"
            "Tricorder/CLI/App"
            "Tricorder/CLI/App/CLIResponse"
            "Tricorder/CLI/App/Daemon"
            "Tricorder/CLI/App/Output"
            "Tricorder/CLI/App/Test"
            "Tricorder/CLI/App/Test/Json"
            "Tricorder/CLI/App/Test/Json/Responses"
            "Tricorder/CLI/App/Test/SuiteView"
            "Tricorder/CLI/App/Test/Text"
            "Tricorder/CLI/Arguments"
            "Tricorder/CLI/Daemon"
            "Tricorder/CLI/Main"
            "Tricorder/CLI/Operations"
            "Tricorder/CLI/Render"
            "Tricorder/CLI/UI"
            "Tricorder/CLI/UI/Brick"
            "Tricorder/CLI/UI/BrickChan"
            "Tricorder/CLI/UI/Event"
            "Tricorder/CLI/UI/Keys"
            "Tricorder/CLI/UI/Misc"
            "Tricorder/CLI/UI/Route"
            "Tricorder/CLI/UI/State"
            "Tricorder/CLI/UI/View"
            "Tricorder/Config"
            "Tricorder/Config/LoadedConfig"
            "Tricorder/Daemon/Builder"
            "Tricorder/Daemon/Core"
            "Tricorder/Daemon/DaemonInfo"
            "Tricorder/Daemon/Dispatch"
            "Tricorder/Daemon/EvalCommentRunner"
            "Tricorder/Daemon/Ghci/Config"
            "Tricorder/Daemon/Ghci/Config/File"
            "Tricorder/Daemon/Ghci/Controls"
            "Tricorder/Daemon/Ghci/Diagnostic"
            "Tricorder/Daemon/Ghci/InterruptDecision"
            "Tricorder/Daemon/Ghci/LineParser"
            "Tricorder/Daemon/Ghci/Load"
            "Tricorder/Daemon/Ghci/LoadedModule"
            "Tricorder/Daemon/Ghci/Loading"
            "Tricorder/Daemon/Ghci/LoadOutcome"
            "Tricorder/Daemon/Ghci/LoadResult"
            "Tricorder/Daemon/Ghci/Message"
            "Tricorder/Daemon/Ghci/Output"
            "Tricorder/Daemon/Ghci/Path"
            "Tricorder/Daemon/Ghci/Position"
            "Tricorder/Daemon/Ghci/Process"
            "Tricorder/Daemon/Ghci/Result"
            "Tricorder/Daemon/Ghci/Session"
            "Tricorder/Daemon/Ghci/Session/State"
            "Tricorder/Daemon/Ghci/Severity"
            "Tricorder/Daemon/Ghci/TextParser"
            "Tricorder/Daemon/HookDispatch"
            "Tricorder/Daemon/Hpack"
            "Tricorder/Daemon/Hpack/Effect"
            "Tricorder/Daemon/IdleTimer"
            "Tricorder/Daemon/Main"
            "Tricorder/Daemon/TestRunner"
            "Tricorder/Daemon/Watch"
            "Tricorder/Logging"
            "Tricorder/Runtime"
            "Tricorder/Session"
            "Tricorder/Session/CabalFile"
            "Tricorder/Session/Command/RenderedCommand"
            "Tricorder/Session/CommandConfig"
            "Tricorder/Session/CommandTemplate"
            "Tricorder/Session/Config"
            "Tricorder/Session/GenerateWithHpack"
            "Tricorder/Session/HaskellHooks"
            "Tricorder/Session/Hook"
            "Tricorder/Session/Hooks"
            "Tricorder/Session/IdleTimeout"
            "Tricorder/Session/Repl"
            "Tricorder/Session/ReplBuildDir"
            "Tricorder/Session/StackProject"
            "Tricorder/Session/Stage"
            "Tricorder/Session/Stage/Build/Command"
            "Tricorder/Session/Stage/Build/Session"
            "Tricorder/Session/Stage/Eval/Command"
            "Tricorder/Session/Stage/Eval/Session"
            "Tricorder/Session/Stage/Test/Command"
            "Tricorder/Session/Stage/Test/Config"
            "Tricorder/Session/Stage/Test/Session"
            "Tricorder/Session/State"
            "Tricorder/Session/State/Invalid"
            "Tricorder/Session/State/Result"
            "Tricorder/Session/Target"
            "Tricorder/Session/TestTarget"
            "Tricorder/Session/Util"
            "Tricorder/Session/WatchDirs"
            "Tricorder/Session/WatchExclusionPatterns"
            "Tricorder/Socket/Client"
            "Tricorder/Socket/Protocol"
            "Tricorder/Socket/Server"
            "Tricorder/Socket/UnixSocket"
            "Tricorder/SourceLookup"
            "Tricorder/SourceLookup/GhcPkg"
            "Tricorder/SourceLookup/Hackage"
            "Tricorder/SourceLookup/PackageStore"
            "Tricorder/SourceLookup/Reexport"
            "Tricorder/SourceLookup/Slice"
            "Tricorder/SourceLookup/Tarball"
            "Tricorder/TestOutput"
            "Tricorder/Version"
            "Tricorder/Waiters"
          ];
          hsSourceDirs = [ "src" ];
        };
      };
      exes = {
        "tricorder" = {
          depends = [
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."tricorder".components.sublibs.tricorder-internal or (errorHandler.buildDepError "tricorder:tricorder-internal"))
          ];
          buildable = true;
          modules = [ "Paths_tricorder" ];
          hsSourceDirs = [ "app" ];
          mainPath = [
            "Main.hs"
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.8") "";
        };
        "tricorder-daemon" = {
          depends = [
            (hsPkgs."atelier-prelude" or (errorHandler.buildDepError "atelier-prelude"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."effectful-core" or (errorHandler.buildDepError "effectful-core"))
            (hsPkgs."effectful-plugin" or (errorHandler.buildDepError "effectful-plugin"))
            (hsPkgs."tricorder".components.sublibs.tricorder-internal or (errorHandler.buildDepError "tricorder:tricorder-internal"))
          ];
          buildable = true;
          modules = [ "Paths_tricorder" ];
          hsSourceDirs = [ "daemon" ];
          mainPath = [
            "Main.hs"
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.8") "";
        };
      };
      tests = {
        "tricorder-test" = {
          depends = [
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
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
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-discover" or (errorHandler.buildDepError "tasty-discover"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."time-units" or (errorHandler.buildDepError "time-units"))
            (hsPkgs."tricorder".components.sublibs.tricorder-internal or (errorHandler.buildDepError "tricorder:tricorder-internal"))
            (hsPkgs."tricorder-types" or (errorHandler.buildDepError "tricorder-types"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
            (hsPkgs."unagi-chan" or (errorHandler.buildDepError "unagi-chan"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.tasty-discover.components.exes.tasty-discover or (pkgs.pkgsBuildBuild.tasty-discover or (errorHandler.buildToolDepError "tasty-discover:tasty-discover")))
          ];
          buildable = true;
          modules = [
            "Unit/Tricorder/Build/ByteSizeSpec"
            "Unit/Tricorder/Build/EvalCommentSpec"
            "Unit/Tricorder/CLI/App/Test/SuiteViewSpec"
            "Unit/Tricorder/CLI/RenderSpec"
            "Unit/Tricorder/Daemon/BuilderSpec"
            "Unit/Tricorder/Daemon/BuildStateSpec"
            "Unit/Tricorder/Daemon/DispatchSpec"
            "Unit/Tricorder/Daemon/Ghci/LoadResultSpec"
            "Unit/Tricorder/Daemon/Ghci/OutputSpec"
            "Unit/Tricorder/Daemon/Ghci/ProcessSpec"
            "Unit/Tricorder/Daemon/Ghci/ResultSpec"
            "Unit/Tricorder/Daemon/Ghci/SessionSpec"
            "Unit/Tricorder/Daemon/TestRunnerSpec"
            "Unit/Tricorder/Daemon/WatchSpec"
            "Unit/Tricorder/Session/CabalFileSpec"
            "Unit/Tricorder/Session/CommandTemplateSpec"
            "Unit/Tricorder/Session/Helpers"
            "Unit/Tricorder/Session/ReplSpec"
            "Unit/Tricorder/Session/Stage/Build/CommandSpec"
            "Unit/Tricorder/Session/Stage/Eval/CommandSpec"
            "Unit/Tricorder/Session/Stage/Eval/SessionSpec"
            "Unit/Tricorder/Session/Stage/Test/CommandSpec"
            "Unit/Tricorder/Session/TargetSpec"
            "Unit/Tricorder/Session/TestTargetSpec"
            "Unit/Tricorder/Session/WatchDirsSpec"
            "Unit/Tricorder/SessionSpec"
            "Unit/Tricorder/SocketSpec"
            "Unit/Tricorder/SourceLookup/GhcPkgSpec"
            "Unit/Tricorder/SourceLookup/ReexportSpec"
            "Unit/Tricorder/SourceLookup/SliceSpec"
            "Unit/Tricorder/SourceLookup/TarballSpec"
            "Unit/Tricorder/SourceLookupSpec"
            "Unit/Tricorder/TestOutputSpec"
            "Unit/Tricorder/WaitersSpec"
            "Paths_tricorder"
          ];
          hsSourceDirs = [ "test" ];
          mainPath = [ "Driver.hs" ];
        };
      };
    };
  } // rec { src = pkgs.lib.mkDefault ../packages/tricorder; }