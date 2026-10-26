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
      identifier = { name = "warp"; version = "3.4.12"; };
      license = "MIT";
      copyright = "";
      maintainer = "michael@snoyman.com";
      author = "Michael Snoyman, Kazu Yamamoto, Matt Brown";
      homepage = "http://github.com/yesodweb/wai";
      url = "";
      synopsis = "A fast, light-weight web server for WAI applications.";
      description = "HTTP\\/1.0, HTTP\\/1.1 and HTTP\\/2 are supported.\nFor HTTP\\/2,  Warp supports direct and ALPN (in TLS)\nbut not upgrade.\nAPI docs and the README are available at\n<http://www.stackage.org/package/warp>.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
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
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bsb-http-chunked" or (errorHandler.buildDepError "bsb-http-chunked"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-client" or (errorHandler.buildDepError "http-client"))
            (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
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
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."auto-update" or (errorHandler.buildDepError "auto-update"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."http-date" or (errorHandler.buildDepError "http-date"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."recv" or (errorHandler.buildDepError "recv"))
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
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/warp-3.4.12.tar.gz";
      sha256 = "03cd90d35b72c2a6f607dd5f1e2344da525f9eefc848acb5414c585923517082";
    });
  }) // {
    package-description-override = "cabal-version:      >=1.10\r\nname:               warp\r\nversion:            3.4.12\r\nx-revision: 1\r\nlicense:            MIT\r\nlicense-file:       LICENSE\r\nmaintainer:         michael@snoyman.com\r\nauthor:             Michael Snoyman, Kazu Yamamoto, Matt Brown\r\nstability:          Stable\r\nhomepage:           http://github.com/yesodweb/wai\r\nsynopsis:           A fast, light-weight web server for WAI applications.\r\ndescription:\r\n    HTTP\\/1.0, HTTP\\/1.1 and HTTP\\/2 are supported.\r\n    For HTTP\\/2,  Warp supports direct and ALPN (in TLS)\r\n    but not upgrade.\r\n    API docs and the README are available at\r\n    <http://www.stackage.org/package/warp>.\r\n\r\ncategory:           Web, Yesod\r\nbuild-type:         Simple\r\nextra-source-files:\r\n    attic/hex\r\n    ChangeLog.md\r\n    README.md\r\n    test/head-response\r\n    test/inputFile\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: git://github.com/yesodweb/wai.git\r\n\r\nflag network-bytestring\r\n    default: False\r\n\r\nflag allow-sendfilefd\r\n    description: Allow use of sendfileFd (not available on GNU/kFreeBSD)\r\n\r\nflag include-warp-version\r\n    description:\r\n        Exposes the version in Network.Wai.Handler.Warp.warpVersion.\r\n        This adds a dependency on Paths_warp so application binaries may\r\n        reference subpaths of GHC. For nix users this may result in binaries\r\n        with a large transitive runtime dependency closure that includes GHC\r\n        itself.\r\n    default:     True\r\n    manual:      True\r\n\r\nflag warp-debug\r\n    description: print debug output. not suitable for production\r\n    default:     False\r\n\r\nflag x509\r\n    description:\r\n        Adds a dependency on the x509 library to enable getting TLS client certificates.\r\n\r\nlibrary\r\n    exposed-modules:\r\n        Network.Wai.Handler.Warp\r\n        Network.Wai.Handler.Warp.Internal\r\n\r\n    other-modules:\r\n        Network.Wai.Handler.Warp.Buffer\r\n        Network.Wai.Handler.Warp.Conduit\r\n        Network.Wai.Handler.Warp.Counter\r\n        Network.Wai.Handler.Warp.Date\r\n        Network.Wai.Handler.Warp.FdCache\r\n        Network.Wai.Handler.Warp.File\r\n        Network.Wai.Handler.Warp.FileInfoCache\r\n        Network.Wai.Handler.Warp.HTTP1\r\n        Network.Wai.Handler.Warp.HTTP2\r\n        Network.Wai.Handler.Warp.HTTP2.File\r\n        Network.Wai.Handler.Warp.HTTP2.PushPromise\r\n        Network.Wai.Handler.Warp.HTTP2.Request\r\n        Network.Wai.Handler.Warp.HTTP2.Response\r\n        Network.Wai.Handler.Warp.HTTP2.Types\r\n        Network.Wai.Handler.Warp.HashMap\r\n        Network.Wai.Handler.Warp.Header\r\n        Network.Wai.Handler.Warp.IO\r\n        Network.Wai.Handler.Warp.Imports\r\n        Network.Wai.Handler.Warp.PackInt\r\n        Network.Wai.Handler.Warp.ReadInt\r\n        Network.Wai.Handler.Warp.Request\r\n        Network.Wai.Handler.Warp.RequestHeader\r\n        Network.Wai.Handler.Warp.Response\r\n        Network.Wai.Handler.Warp.ResponseHeader\r\n        Network.Wai.Handler.Warp.Run\r\n        Network.Wai.Handler.Warp.SendFile\r\n        Network.Wai.Handler.Warp.Settings\r\n        Network.Wai.Handler.Warp.Types\r\n        Network.Wai.Handler.Warp.Windows\r\n        Network.Wai.Handler.Warp.WithApplication\r\n\r\n    if flag(include-warp-version)\r\n        other-modules: Paths_warp\r\n\r\n    default-language: Haskell2010\r\n    ghc-options:      -Wall\r\n    build-depends:\r\n        base >=4.12 && <5,\r\n        array,\r\n        auto-update >=0.2.2 && <0.3,\r\n        async >= 2,\r\n        bsb-http-chunked <0.1,\r\n        bytestring >=0.9.1.4,\r\n        case-insensitive >=0.2,\r\n        containers,\r\n        ghc-prim,\r\n        hashable,\r\n        http-date,\r\n        http-types >=0.12,\r\n        http2 >=5.4 && <5.5,\r\n        iproute >=1.3.1,\r\n        recv >=0.1.0 && <0.2.0,\r\n        simple-sendfile >=0.2.7 && <0.3,\r\n        stm >=2.3,\r\n        streaming-commons >=0.1.10,\r\n        text,\r\n        time-manager >=0.2 && <0.3 || >=0.3.1 && <0.4,\r\n        vault >=0.3,\r\n        wai >=3.2.4 && <3.3,\r\n        word8\r\n\r\n    if flag(x509)\r\n        build-depends: crypton-x509\r\n\r\n    if impl(ghc <8)\r\n        build-depends: semigroups\r\n\r\n    if flag(network-bytestring)\r\n        build-depends:\r\n            network >=2.2.1.5 && <2.2.3,\r\n            network-bytestring >=0.1.3 && <0.1.4\r\n\r\n    else\r\n        build-depends: network >=2.3\r\n\r\n    if flag(warp-debug)\r\n        cpp-options: -DWARP_DEBUG\r\n\r\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\r\n        cpp-options: -DSENDFILEFD\r\n\r\n    if os(windows)\r\n        cpp-options:   -DWINDOWS\r\n        build-depends:\r\n            time,\r\n            unix-compat >=0.2\r\n\r\n    else\r\n        other-modules: Network.Wai.Handler.Warp.MultiMap\r\n        build-depends: unix\r\n\r\n    if impl(ghc >=8)\r\n        default-extensions: Strict StrictData\r\n\r\n    if flag(include-warp-version)\r\n        cpp-options: -DINCLUDE_WARP_VERSION\r\n\r\ntest-suite doctest\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          doctests.hs\r\n    buildable:        False\r\n    hs-source-dirs:   test\r\n    default-language: Haskell2010\r\n    ghc-options:      -threaded -Wall\r\n    build-depends:\r\n        base >=4.8 && <5,\r\n        doctest >=0.10.1\r\n\r\n    if os(windows)\r\n        buildable: False\r\n\r\n    if impl(ghc >=8)\r\n        default-extensions: Strict StrictData\r\n\r\ntest-suite spec\r\n    type:               exitcode-stdio-1.0\r\n    main-is:            Spec.hs\r\n    build-tool-depends: hspec-discover:hspec-discover\r\n    hs-source-dirs:     test .\r\n    other-modules:\r\n        ConduitSpec\r\n        ConnectionSpec\r\n        ExceptionSpec\r\n        FdCacheSpec\r\n        FileSpec\r\n        HTTP\r\n        PackIntSpec\r\n        ReadIntSpec\r\n        RequestSpec\r\n        ResponseHeaderSpec\r\n        ResponseSpec\r\n        RunSpec\r\n        SendFileSpec\r\n        WithApplicationSpec\r\n        Network.Wai.Handler.Warp\r\n        Network.Wai.Handler.Warp.Internal\r\n        Network.Wai.Handler.Warp.Buffer\r\n        Network.Wai.Handler.Warp.Conduit\r\n        Network.Wai.Handler.Warp.Counter\r\n        Network.Wai.Handler.Warp.Date\r\n        Network.Wai.Handler.Warp.FdCache\r\n        Network.Wai.Handler.Warp.File\r\n        Network.Wai.Handler.Warp.FileInfoCache\r\n        Network.Wai.Handler.Warp.HTTP1\r\n        Network.Wai.Handler.Warp.HTTP2\r\n        Network.Wai.Handler.Warp.HTTP2.File\r\n        Network.Wai.Handler.Warp.HTTP2.PushPromise\r\n        Network.Wai.Handler.Warp.HTTP2.Request\r\n        Network.Wai.Handler.Warp.HTTP2.Response\r\n        Network.Wai.Handler.Warp.HTTP2.Types\r\n        Network.Wai.Handler.Warp.HashMap\r\n        Network.Wai.Handler.Warp.Header\r\n        Network.Wai.Handler.Warp.IO\r\n        Network.Wai.Handler.Warp.Imports\r\n        Network.Wai.Handler.Warp.PackInt\r\n        Network.Wai.Handler.Warp.ReadInt\r\n        Network.Wai.Handler.Warp.Request\r\n        Network.Wai.Handler.Warp.RequestHeader\r\n        Network.Wai.Handler.Warp.Response\r\n        Network.Wai.Handler.Warp.ResponseHeader\r\n        Network.Wai.Handler.Warp.Run\r\n        Network.Wai.Handler.Warp.SendFile\r\n        Network.Wai.Handler.Warp.Settings\r\n        Network.Wai.Handler.Warp.Types\r\n        Network.Wai.Handler.Warp.Windows\r\n        Network.Wai.Handler.Warp.WithApplication\r\n\r\n    if flag(include-warp-version)\r\n        other-modules: Paths_warp\r\n\r\n    default-language:   Haskell2010\r\n    ghc-options:        -Wall -threaded\r\n    build-depends:\r\n        base >=4.8 && <5,\r\n        QuickCheck,\r\n        array,\r\n        auto-update,\r\n        async,\r\n        bsb-http-chunked <0.1,\r\n        bytestring >=0.9.1.4,\r\n        case-insensitive >=0.2,\r\n        containers,\r\n        directory,\r\n        ghc-prim,\r\n        hashable,\r\n        hspec >=1.3,\r\n        http-client,\r\n        http-date,\r\n        http-types >=0.12,\r\n        http2 >=5.4 && <5.5,\r\n        iproute >=1.3.1,\r\n        network,\r\n        process,\r\n        recv >=0.1.0 && <0.2.0,\r\n        simple-sendfile >=0.2.4 && <0.3,\r\n        stm >=2.3,\r\n        streaming-commons >=0.1.10,\r\n        text,\r\n        time-manager,\r\n        vault,\r\n        wai >=3.2.2.1 && <3.3,\r\n        word8\r\n\r\n    if flag(x509)\r\n        build-depends: crypton-x509\r\n\r\n    if impl(ghc <8)\r\n        build-depends:\r\n            semigroups,\r\n            transformers\r\n\r\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\r\n        cpp-options: -DSENDFILEFD\r\n\r\n    if os(windows)\r\n        cpp-options:   -DWINDOWS\r\n        build-depends:\r\n            time,\r\n            unix-compat >=0.2\r\n\r\n    else\r\n        other-modules: Network.Wai.Handler.Warp.MultiMap\r\n        build-depends: unix\r\n\r\n    if impl(ghc >=8)\r\n        default-extensions: Strict StrictData\r\n\r\nbenchmark parser\r\n    type:             exitcode-stdio-1.0\r\n    main-is:          Parser.hs\r\n    hs-source-dirs:   bench .\r\n    other-modules:\r\n        Network.Wai.Handler.Warp.Conduit\r\n        Network.Wai.Handler.Warp.Counter\r\n        Network.Wai.Handler.Warp.Date\r\n        Network.Wai.Handler.Warp.FdCache\r\n        Network.Wai.Handler.Warp.FileInfoCache\r\n        Network.Wai.Handler.Warp.HashMap\r\n        Network.Wai.Handler.Warp.Header\r\n        Network.Wai.Handler.Warp.Imports\r\n        Network.Wai.Handler.Warp.MultiMap\r\n        Network.Wai.Handler.Warp.ReadInt\r\n        Network.Wai.Handler.Warp.Request\r\n        Network.Wai.Handler.Warp.RequestHeader\r\n        Network.Wai.Handler.Warp.Settings\r\n        Network.Wai.Handler.Warp.Types\r\n\r\n    if flag(include-warp-version)\r\n        other-modules: Paths_warp\r\n\r\n    default-language: Haskell2010\r\n    build-depends:\r\n        base >=4.8 && <5,\r\n        array,\r\n        auto-update,\r\n        bytestring,\r\n        case-insensitive,\r\n        containers,\r\n        criterion,\r\n        ghc-prim,\r\n        hashable,\r\n        http-date,\r\n        http-types,\r\n        network,\r\n        network,\r\n        recv,\r\n        stm,\r\n        streaming-commons,\r\n        text,\r\n        time-manager,\r\n        vault,\r\n        wai,\r\n        word8\r\n\r\n    if flag(x509)\r\n        build-depends: crypton-x509\r\n\r\n    if impl(ghc <8)\r\n        build-depends: semigroups\r\n\r\n    if (((os(linux) || os(freebsd)) || os(osx)) && flag(allow-sendfilefd))\r\n        cpp-options:   -DSENDFILEFD\r\n        build-depends: unix\r\n\r\n    if os(windows)\r\n        cpp-options:   -DWINDOWS\r\n        build-depends:\r\n            time,\r\n            unix-compat >=0.2\r\n\r\n    if impl(ghc >=8)\r\n        default-extensions: Strict StrictData\r\n";
  }