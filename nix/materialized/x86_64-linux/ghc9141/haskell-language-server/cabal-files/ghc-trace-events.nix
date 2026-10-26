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
      identifier = { name = "ghc-trace-events"; version = "0.1.2.10"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2018-2025 Mitsutoshi Aoe";
      maintainer = "Mitsutoshi Aoe <me@maoe.name>";
      author = "Mitsutoshi Aoe";
      homepage = "https://github.com/maoe/ghc-trace-events";
      url = "";
      synopsis = "Faster traceEvent and traceMarker, and binary object logging for\neventlog";
      description = "ghc-trace-events provides faster traceEvent and traceMarker as well\nas arbitrary binary object logging for the eventlog framework. Unlike the\n<http://hackage.haskell.org/package/base/docs/Debug-Trace.html#g:2 eventlog tracing functions in base>,\nall the tracing functions in this library don't evaluate the input if user\nevent logging (the\n<https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--l%20⟨flags⟩ -lu>\nflag) is disabled, which can give a significant boost in performance. Take a\nlook at the benchmark suite for the details.\n\nThis library provies the following modules:\n\n[\"Debug.Trace.String\"] Drop-in replacement for the event tracing functions in\n\"Debug.Trace\".\n[\"Debug.Trace.ByteString\"] UTF-8 encoded 'ByteString' variant\nof the event tracing functions in \"Debug.Trace\". It's faster than the 'String'\nvariant.\n[\"Debug.Trace.Text\"] 'Text' variant of the event tracing functions\nin \"Debug.Trace\". It's faster than the 'String' variant.\n[\"Debug.Trace.Binary\"] Arbitary binary object logging available for GHC 8.8 or\nlater. Unlike the other tracing functions 'Debug.Trace.Binary.traceBinaryEvent'\ntakes an arbitrary 'ByteString' object as opposed to a UTF-8\nencoded string.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      benchmarks = {
        "bench-trace-enabled" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."ghc-trace-events" or (errorHandler.buildDepError "ghc-trace-events"))
          ];
          buildable = true;
        };
        "bench-trace-disabled" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
            (hsPkgs."ghc-trace-events" or (errorHandler.buildDepError "ghc-trace-events"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/ghc-trace-events-0.1.2.10.tar.gz";
      sha256 = "f0823e1f86797e31703d965abf49af3a72021c4f01d10f11870734f2c2d47438";
    });
  }) // {
    package-description-override = "cabal-version: 2.2\nname: ghc-trace-events\nversion: 0.1.2.10\nsynopsis: Faster traceEvent and traceMarker, and binary object logging for\n  eventlog\ndescription: ghc-trace-events provides faster traceEvent and traceMarker as well\n  as arbitrary binary object logging for the eventlog framework. Unlike the\n  <http://hackage.haskell.org/package/base/docs/Debug-Trace.html#g:2 eventlog tracing functions in base>,\n  all the tracing functions in this library don't evaluate the input if user\n  event logging (the\n  <https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/runtime_control.html#rts-flag--l%20⟨flags⟩ -lu>\n  flag) is disabled, which can give a significant boost in performance. Take a\n  look at the benchmark suite for the details.\n  .\n  This library provies the following modules:\n  .\n  [\"Debug.Trace.String\"] Drop-in replacement for the event tracing functions in\n  \"Debug.Trace\".\n  [\"Debug.Trace.ByteString\"] UTF-8 encoded 'ByteString' variant\n  of the event tracing functions in \"Debug.Trace\". It's faster than the 'String'\n  variant.\n  [\"Debug.Trace.Text\"] 'Text' variant of the event tracing functions\n  in \"Debug.Trace\". It's faster than the 'String' variant.\n  [\"Debug.Trace.Binary\"] Arbitary binary object logging available for GHC 8.8 or\n  later. Unlike the other tracing functions 'Debug.Trace.Binary.traceBinaryEvent'\n  takes an arbitrary 'ByteString' object as opposed to a UTF-8\n  encoded string.\nhomepage: https://github.com/maoe/ghc-trace-events\nlicense: BSD-3-Clause\nlicense-file: LICENSE\nauthor: Mitsutoshi Aoe\nmaintainer: Mitsutoshi Aoe <me@maoe.name>\ncopyright: Copyright (C) 2018-2025 Mitsutoshi Aoe\ncategory: Development, GHC, Trace\nbuild-type: Simple\nextra-source-files:\n  README.md\nextra-doc-files:\n  CHANGELOG.md\ntested-with: GHC == 7.10.3\n  || == 8.0.2\n  || == 8.2.2\n  || == 8.4.4\n  || == 8.6.5\n  || == 8.8.4\n  || == 8.10.7\n  || == 9.0.2\n  || == 9.2.8\n  || == 9.4.8\n  || == 9.6.5\n  || == 9.8.2\n  || == 9.10.1\n  || == 9.12.1\n\ncommon base { build-depends: base >= 4.8 && < 4.22 }\ncommon bytestring { build-depends: bytestring >= 0.9.2 && < 0.13 }\ncommon criterion { build-depends: criterion < 1.6 }\ncommon ghc-trace-events { build-depends: ghc-trace-events }\ncommon text { build-depends: text >= 1.0.0 && < 1.3 || >= 2.0 && < 2.2 }\ncommon tasty-bench { build-depends: tasty-bench < 0.4 }\n\nlibrary\n  import:\n      base\n    , bytestring\n    , text\n  ghc-options: -Wall\n  exposed-modules:\n    Debug.Trace.ByteString\n    Debug.Trace.Flags\n    Debug.Trace.String\n    Debug.Trace.Text\n  if impl(ghc >= 8.7)\n    exposed-modules:\n      Debug.Trace.Binary\n  hs-source-dirs: src\n  c-sources: cbits/tracing.c\n  default-language: Haskell2010\n\nbenchmark bench-trace-enabled\n  import:\n      base\n    , bytestring\n    , tasty-bench\n    , ghc-trace-events\n  type: exitcode-stdio-1.0\n  ghc-options: -eventlog -threaded \"-with-rtsopts=-l\"\n  main-is: bench-trace.hs\n  hs-source-dirs: benchmarks\n  default-language: Haskell2010\n\nbenchmark bench-trace-disabled\n  import:\n      base\n    , bytestring\n    , tasty-bench\n    , ghc-trace-events\n  type: exitcode-stdio-1.0\n  ghc-options: -threaded\n  main-is: bench-trace.hs\n  hs-source-dirs: benchmarks\n  default-language: Haskell2010\n\nsource-repository head\n  type: git\n  branch: develop\n  location: https://github.com/maoe/ghc-trace-events.git\n";
  }