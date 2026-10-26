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
      network-bytestring = false;
      allow-sendfilefd = true;
      include-warp-version = true;
      warp-debug = false;
      x509 = true;
    };
    package = {
      specVersion = "1.10";
      identifier = { name = "warp"; version = "3.4.16"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman, Kazu Yamamoto, Matt Brown";
      homepage = "https://github.com/yesodweb/wai";
      url = "";
      synopsis = "A fast, light-weight web server for WAI applications.";
      description = "HTTP\\/1.0, HTTP\\/1.1 and HTTP\\/2 are supported.\nFor HTTP\\/2,  Warp supports direct and ALPN (in TLS)\nbut not upgrade.\nAPI docs and the README are available at\n<https://www.stackage.org/package/warp>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
          (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
          (hsPkgs."simple-sendfile" or (errorHandler.buildDepError "simple-sendfile"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
          (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
        ] ++ pkgs.lib.optional (flags.x509) (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))) ++ (if flags.network-bytestring
          then [
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-bytestring" or (errorHandler.buildDepError "network-bytestring"))
          ]
          else [
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
          ])) ++ (if system.isWindows
          then [
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
          ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        buildable = true;
      };
      tests = {
        "doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
          ];
          buildable = false;
        };
        "spec" = {
          depends = (([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
            (hsPkgs."simple-sendfile" or (errorHandler.buildDepError "simple-sendfile"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
            (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ] ++ pkgs.lib.optional (flags.x509) (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))) ++ pkgs.lib.optionals (compiler.isGhc && compiler.version.lt "8") [
            (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ]) ++ (if system.isWindows
            then [
              (hsPkgs."time" or (errorHandler.buildDepError "time"))
              (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
            ]
            else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "parser" = {
          depends = ((([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
            (hsPkgs."simple-sendfile" or (errorHandler.buildDepError "simple-sendfile"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
            (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ] ++ pkgs.lib.optional (flags.x509) (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))) ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"))) ++ pkgs.lib.optional ((system.isLinux || system.isFreebsd || system.isOsx) && flags.allow-sendfilefd) (hsPkgs."unix" or (errorHandler.buildDepError "unix"))) ++ pkgs.lib.optionals (system.isWindows) [
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
          ];
          buildable = true;
        };
        "response" = {
          depends = (([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."streaming-commons" or (errorHandler.buildDepError "streaming-commons"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
            (hsPkgs."vault" or (errorHandler.buildDepError "vault"))
            (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ] ++ pkgs.lib.optional (flags.x509) (hsPkgs."crypton-x509" or (errorHandler.buildDepError "crypton-x509"))) ++ pkgs.lib.optional ((system.isLinux || system.isFreebsd || system.isOsx) && flags.allow-sendfilefd) (hsPkgs."unix" or (errorHandler.buildDepError "unix"))) ++ (if system.isWindows
            then [
              (hsPkgs."time" or (errorHandler.buildDepError "time"))
              (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
            ]
            else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/warp-3.4.16.tar.gz";
      sha256 = "7dd09b9f2f868e4647fe96162f063a99da791a0e57479d1ea74b210ecb8b2f17";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\nname:               warp\nversion:            3.4.16\nlicense:            MIT\nlicense-file:       LICENSE\nmaintainer:         michael@snoyman.com\nauthor:             Michael Snoyman, Kazu Yamamoto, Matt Brown\nstability:          Stable\nhomepage:           https://github.com/yesodweb/wai\nsynopsis:           A fast, light-weight web server for WAI applications.\ndescription:\n    HTTP\\/1.0, HTTP\\/1.1 and HTTP\\/2 are supported.\n    For HTTP\\/2,  Warp supports direct and ALPN (in TLS)\n    but not upgrade.\n    API docs and the README are available at\n    <https://www.stackage.org/package/warp>.\n\ncategory:           Web, Yesod\nbuild-type:         Simple\nextra-source-files:\n    attic/hex\n    ChangeLog.md\n    README.md\n    test/head-response\n    test/inputFile\n\nsource-repository head\n    type:     git\n    location: https://github.com/yesodweb/wai.git\n    subdir:   warp\n\nflag network-bytestring\n    default: False\n\nflag allow-sendfilefd\n    description: Allow use of sendfileFd (not available on GNU/kFreeBSD)\n\nflag include-warp-version\n    description:\n        Exposes the version in Network.Wai.Handler.Warp.warpVersion.\n        This adds a dependency on Paths_warp so application binaries may\n        reference subpaths of GHC. For nix users this may result in binaries\n        with a large transitive runtime dependency closure that includes GHC\n        itself.\n    default:     True\n    manual:      True\n\nflag warp-debug\n    description: print debug output. not suitable for production\n    default:     False\n\nflag x509\n    description:\n        Adds a dependency on the x509 library to enable getting TLS client certificates.\n\nlibrary\n    exposed-modules:\n        Network.Wai.Handler.Warp\n        Network.Wai.Handler.Warp.Internal\n\n    other-modules:\n        Network.Wai.Handler.Warp.Buffer\n        Network.Wai.Handler.Warp.Conduit\n        Network.Wai.Handler.Warp.Counter\n        Network.Wai.Handler.Warp.Date\n        Network.Wai.Handler.Warp.FdCache\n        Network.Wai.Handler.Warp.File\n        Network.Wai.Handler.Warp.FileInfoCache\n        Network.Wai.Handler.Warp.HTTP1\n        Network.Wai.Handler.Warp.HTTP2\n        Network.Wai.Handler.Warp.HTTP2.File\n        Network.Wai.Handler.Warp.HTTP2.PushPromise\n        Network.Wai.Handler.Warp.HTTP2.Request\n        Network.Wai.Handler.Warp.HTTP2.Response\n        Network.Wai.Handler.Warp.HTTP2.Types\n        Network.Wai.Handler.Warp.HashMap\n        Network.Wai.Handler.Warp.Header\n        Network.Wai.Handler.Warp.IO\n        Network.Wai.Handler.Warp.Imports\n        Network.Wai.Handler.Warp.PackInt\n        Network.Wai.Handler.Warp.ReadInt\n        Network.Wai.Handler.Warp.Request\n        Network.Wai.Handler.Warp.RequestHeader\n        Network.Wai.Handler.Warp.Response\n        Network.Wai.Handler.Warp.ResponseHeader\n        Network.Wai.Handler.Warp.Run\n        Network.Wai.Handler.Warp.SendFile\n        Network.Wai.Handler.Warp.Settings\n        Network.Wai.Handler.Warp.ShuttingDown\n        Network.Wai.Handler.Warp.Types\n        Network.Wai.Handler.Warp.Windows\n        Network.Wai.Handler.Warp.WithApplication\n\n    if flag(include-warp-version)\n        other-modules: Paths_warp\n\n    default-language: Haskell2010\n    ghc-options:      -Wall\n    build-depends:\n        base >=4.12 && <5,\n        auto-update >=0.2.2 && <0.3,\n        async >= 2,\n        bsb-http-chunked <0.1,\n        bytestring >=0.9.1.4,\n        case-insensitive >=0.2,\n        containers,\n        hashable,\n        http-date,\n        http-types >=0.12 && <1,\n        http-semantics >=0.4 && <0.5,\n        http2 >=5.4 && <5.5,\n        iproute >=1.3.1,\n        recv >=0.1.2 && <0.2.0,\n        simple-sendfile >=0.2.7 && <0.3,\n        stm >=2.3,\n        streaming-commons >=0.1.10,\n        text,\n        time-manager >=0.2 && <0.5,\n        vault >=0.3,\n        wai >=3.2.5 && <3.3,\n        word8\n\n    if flag(x509)\n        build-depends: crypton-x509\n\n    if impl(ghc <8)\n        build-depends: semigroups\n\n    if flag(network-bytestring)\n        build-depends:\n            network >=2.2.1.5 && <2.2.3,\n            network-bytestring >=0.1.3 && <0.1.4\n\n    else\n        build-depends: network >=2.3\n\n    if flag(warp-debug)\n        cpp-options: -DWARP_DEBUG\n\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\n        cpp-options: -DSENDFILEFD\n\n    if os(windows)\n        cpp-options:   -DWINDOWS\n        build-depends:\n            time,\n            unix-compat >=0.2\n\n    else\n        other-modules: Network.Wai.Handler.Warp.MultiMap\n        build-depends: unix\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\n    if flag(include-warp-version)\n        cpp-options: -DINCLUDE_WARP_VERSION\n\ntest-suite doctest\n    type:             exitcode-stdio-1.0\n    main-is:          doctests.hs\n    buildable:        False\n    hs-source-dirs:   test\n    default-language: Haskell2010\n    ghc-options:      -threaded -Wall\n    build-depends:\n        base >=4.8 && <5,\n        doctest >=0.10.1\n\n    if os(windows)\n        buildable: False\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test .\n    other-modules:\n        BufferSpec\n        ConduitSpec\n        ConnectionSpec\n        ConnectionExceptionSpec\n        EarlyHintsSpec\n        ExceptionSpec\n        FdCacheSpec\n        FileSpec\n        GracefulShutdownSpec\n        HTTP\n        PackIntSpec\n        ReadIntSpec\n        RequestSpec\n        ResponseHeaderSpec\n        ResponseSpec\n        RunSpec\n        SendFileSpec\n        ServerStateSpec\n        WithApplicationSpec\n        Network.Wai.Handler.Warp\n        Network.Wai.Handler.Warp.Internal\n        Network.Wai.Handler.Warp.Buffer\n        Network.Wai.Handler.Warp.Conduit\n        Network.Wai.Handler.Warp.Counter\n        Network.Wai.Handler.Warp.Date\n        Network.Wai.Handler.Warp.FdCache\n        Network.Wai.Handler.Warp.File\n        Network.Wai.Handler.Warp.FileInfoCache\n        Network.Wai.Handler.Warp.HTTP1\n        Network.Wai.Handler.Warp.HTTP2\n        Network.Wai.Handler.Warp.HTTP2.File\n        Network.Wai.Handler.Warp.HTTP2.PushPromise\n        Network.Wai.Handler.Warp.HTTP2.Request\n        Network.Wai.Handler.Warp.HTTP2.Response\n        Network.Wai.Handler.Warp.HTTP2.Types\n        Network.Wai.Handler.Warp.HashMap\n        Network.Wai.Handler.Warp.Header\n        Network.Wai.Handler.Warp.IO\n        Network.Wai.Handler.Warp.Imports\n        Network.Wai.Handler.Warp.PackInt\n        Network.Wai.Handler.Warp.ReadInt\n        Network.Wai.Handler.Warp.Request\n        Network.Wai.Handler.Warp.RequestHeader\n        Network.Wai.Handler.Warp.Response\n        Network.Wai.Handler.Warp.ResponseHeader\n        Network.Wai.Handler.Warp.Run\n        Network.Wai.Handler.Warp.SendFile\n        Network.Wai.Handler.Warp.Settings\n        Network.Wai.Handler.Warp.ShuttingDown\n        Network.Wai.Handler.Warp.Types\n        Network.Wai.Handler.Warp.Windows\n        Network.Wai.Handler.Warp.WithApplication\n\n    if flag(include-warp-version)\n        other-modules: Paths_warp\n\n    default-language:   Haskell2010\n    ghc-options:        -Wall -threaded\n    build-depends:\n        base >=4.8 && <5,\n        QuickCheck,\n        auto-update,\n        async,\n        bsb-http-chunked <0.1,\n        bytestring >=0.9.1.4,\n        case-insensitive >=0.2,\n        containers,\n        directory,\n        hashable,\n        hspec >=1.3,\n        http-client,\n        http-date,\n        http-types >=0.12,\n        http-semantics >=0.4 && <0.5,\n        http2 >=5.4 && <5.5,\n        iproute >=1.3.1,\n        network,\n        process,\n        recv >=0.1.2 && <0.2.0,\n        simple-sendfile >=0.2.4 && <0.3,\n        stm >=2.3,\n        streaming-commons >=0.1.10,\n        text,\n        time-manager,\n        vault,\n        wai >=3.2.5 && <3.3,\n        -- workaround: this should be unnecessary\n        warp,\n        word8\n\n    if flag(x509)\n        build-depends: crypton-x509\n\n    if impl(ghc <8)\n        build-depends:\n            semigroups,\n            transformers\n\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\n        cpp-options: -DSENDFILEFD\n\n    if os(windows)\n        cpp-options:   -DWINDOWS\n        build-depends:\n            time,\n            unix-compat >=0.2\n\n    else\n        other-modules: Network.Wai.Handler.Warp.MultiMap\n        build-depends: unix\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\nbenchmark parser\n    type:             exitcode-stdio-1.0\n    main-is:          Parser.hs\n    hs-source-dirs:   bench .\n    other-modules:\n        Network.Wai.Handler.Warp.Buffer\n        Network.Wai.Handler.Warp.Conduit\n        Network.Wai.Handler.Warp.Counter\n        Network.Wai.Handler.Warp.Date\n        Network.Wai.Handler.Warp.FdCache\n        Network.Wai.Handler.Warp.File\n        Network.Wai.Handler.Warp.FileInfoCache\n        Network.Wai.Handler.Warp.HashMap\n        Network.Wai.Handler.Warp.Header\n        Network.Wai.Handler.Warp.IO\n        Network.Wai.Handler.Warp.Imports\n        Network.Wai.Handler.Warp.MultiMap\n        Network.Wai.Handler.Warp.PackInt\n        Network.Wai.Handler.Warp.ReadInt\n        Network.Wai.Handler.Warp.Request\n        Network.Wai.Handler.Warp.RequestHeader\n        Network.Wai.Handler.Warp.Response\n        Network.Wai.Handler.Warp.ResponseHeader\n        Network.Wai.Handler.Warp.Settings\n        Network.Wai.Handler.Warp.ShuttingDown\n        Network.Wai.Handler.Warp.Types\n\n    if flag(include-warp-version)\n        other-modules: Paths_warp\n\n    default-language: Haskell2010\n    build-depends:\n        base >=4.8 && <5,\n        async,\n        auto-update,\n        bsb-http-chunked,\n        bytestring,\n        case-insensitive,\n        containers,\n        criterion,\n        hashable,\n        http-date,\n        http-types,\n        http2,\n        iproute,\n        network,\n        recv,\n        simple-sendfile,\n        stm,\n        streaming-commons,\n        text,\n        time-manager,\n        vault,\n        wai,\n        word8\n\n    if flag(x509)\n        build-depends: crypton-x509\n\n    if impl(ghc <8)\n        build-depends: semigroups\n\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\n        cpp-options:   -DSENDFILEFD\n        build-depends: unix\n\n    if os(windows)\n        cpp-options:   -DWINDOWS\n        build-depends:\n            time,\n            unix-compat >=0.2\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n\nbenchmark response\n    type:             exitcode-stdio-1.0\n    main-is:          ResponseBench.hs\n    hs-source-dirs:   bench .\n    other-modules:\n        Network.Wai.Handler.Warp.Buffer\n        Network.Wai.Handler.Warp.Conduit\n        Network.Wai.Handler.Warp.Counter\n        Network.Wai.Handler.Warp.Date\n        Network.Wai.Handler.Warp.FdCache\n        Network.Wai.Handler.Warp.File\n        Network.Wai.Handler.Warp.FileInfoCache\n        Network.Wai.Handler.Warp.HashMap\n        Network.Wai.Handler.Warp.Header\n        Network.Wai.Handler.Warp.IO\n        Network.Wai.Handler.Warp.Imports\n        Network.Wai.Handler.Warp.PackInt\n        Network.Wai.Handler.Warp.ReadInt\n        Network.Wai.Handler.Warp.Request\n        Network.Wai.Handler.Warp.RequestHeader\n        Network.Wai.Handler.Warp.Response\n        Network.Wai.Handler.Warp.ResponseHeader\n        Network.Wai.Handler.Warp.Settings\n        Network.Wai.Handler.Warp.ShuttingDown\n        Network.Wai.Handler.Warp.Types\n\n    if flag(include-warp-version)\n        other-modules: Paths_warp\n\n    default-language: Haskell2010\n    ghc-options:      -threaded\n    build-depends:\n        base >=4.8 && <5,\n        array,\n        auto-update,\n        bsb-http-chunked,\n        bytestring,\n        case-insensitive,\n        containers,\n        criterion,\n        hashable,\n        http-date,\n        http-types,\n        network,\n        recv,\n        stm,\n        streaming-commons,\n        text,\n        time-manager,\n        vault,\n        wai,\n        word8\n\n    if flag(x509)\n        build-depends: crypton-x509\n\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\n        cpp-options:   -DSENDFILEFD\n        build-depends: unix\n\n    if os(windows)\n        cpp-options:   -DWINDOWS\n        build-depends:\n            time,\n            unix-compat >=0.2\n    else\n        other-modules: Network.Wai.Handler.Warp.MultiMap\n        build-depends: unix\n\n    if impl(ghc >=8)\n        default-extensions: Strict StrictData\n";
  }