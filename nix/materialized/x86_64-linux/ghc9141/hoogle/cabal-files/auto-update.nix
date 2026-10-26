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
      identifier = { name = "auto-update"; version = "0.2.8"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman";
      homepage = "https://github.com/yesodweb/wai";
      url = "";
      synopsis = "Efficiently run periodic, on-demand actions";
      description = "API docs and the README are available at <http://www.stackage.org/package/auto-update>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
        ];
        buildable = true;
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."retry" or (errorHandler.buildDepError "retry"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
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
      url = "http://hackage.haskell.org/package/auto-update-0.2.8.tar.gz";
      sha256 = "cfe1f949514987d2ae3dfcd0c445d8c3bb55e951b3f90da443d0cf2bc337fe7d";
    });
  }) // {
    package-description-override = "name:                auto-update\nversion:             0.2.8\nsynopsis:            Efficiently run periodic, on-demand actions\ndescription:         API docs and the README are available at <http://www.stackage.org/package/auto-update>.\nhomepage:            https://github.com/yesodweb/wai\nlicense:             MIT\nlicense-file:        LICENSE\nauthor:              Michael Snoyman\nmaintainer:          michael@snoyman.com\ncategory:            Control\nbuild-type:          Simple\nextra-source-files:  README.md\n                     ChangeLog.md\ncabal-version:       >=1.10\n\nlibrary\n  ghc-options:         -Wall\n  exposed-modules:     Control.AutoUpdate\n                       Control.Debounce\n                       Control.Debounce.Internal\n                       Control.Reaper\n                       Control.Reaper.Internal\n  other-modules:       Control.AutoUpdate.Types\n                       Control.AutoUpdate.Thread\n  if !os(windows)\n    exposed-modules:   Control.AutoUpdate.Internal\n    other-modules:     Control.AutoUpdate.Event\n  build-depends:       base >= 4.12 && < 5,\n                       stm\n  default-language:    Haskell2010\n  if impl(ghc >= 8)\n      default-extensions:  Strict StrictData\n\n-- Test suite is currently not robust enough, gives too many false negatives.\n\ntest-suite spec\n  main-is:         Spec.hs\n  other-modules:   Control.AutoUpdateSpec\n                   Control.DebounceSpec\n                   Control.ReaperSpec\n  hs-source-dirs:  test\n  type:            exitcode-stdio-1.0\n  build-depends:   base, auto-update, exceptions, hspec, retry, HUnit\n  build-tool-depends: hspec-discover:hspec-discover\n  default-language:    Haskell2010\n";
  }