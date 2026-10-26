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
    flags = { devel = false; h2spec = false; };
    package = {
      specVersion = "2.0";
      identifier = { name = "http2"; version = "5.4.9"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Kazu Yamamoto <kazu@iij.ad.jp>";
      author = "Kazu Yamamoto <kazu@iij.ad.jp>";
      homepage = "https://github.com/kazu-yamamoto/http2";
      url = "";
      synopsis = "HTTP/2 library";
      description = "HTTP/2 library including frames, HPACK, client and server.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."async" or (errorHandler.buildDepError "async"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."iproute" or (errorHandler.buildDepError "iproute"))
          (hsPkgs."network" or (errorHandler.buildDepError "network"))
          (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
          (hsPkgs."network-control" or (errorHandler.buildDepError "network-control"))
          (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          (hsPkgs."time-manager" or (errorHandler.buildDepError "time-manager"))
          (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
        ];
        buildable = true;
      };
      exes = {
        "h2c-client" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."unix-time" or (errorHandler.buildDepError "unix-time"))
          ];
          buildable = if flags.devel then true else false;
        };
        "h2c-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-encode" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-debug" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "hpack-stat" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
            (hsPkgs."word8" or (errorHandler.buildDepError "word8"))
          ];
          buildable = if flags.devel then true else false;
        };
        "frame-encode" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = if flags.devel then true else false;
        };
      };
      tests = {
        "spec" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."crypton" or (errorHandler.buildDepError "crypton"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-semantics" or (errorHandler.buildDepError "http-semantics"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network" or (errorHandler.buildDepError "network"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "spec2" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-run" or (errorHandler.buildDepError "network-run"))
            (hsPkgs."typed-process" or (errorHandler.buildDepError "typed-process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = if flags.h2spec then true else false;
        };
        "hpack" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
        "frame" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."Glob" or (errorHandler.buildDepError "Glob"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
            (hsPkgs."base16-bytestring" or (errorHandler.buildDepError "base16-bytestring"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.hspec-discover.components.exes.hspec-discover or (pkgs.pkgsBuildBuild.hspec-discover or (errorHandler.buildToolDepError "hspec-discover:hspec-discover")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "header-compression" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."case-insensitive" or (errorHandler.buildDepError "case-insensitive"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."criterion" or (errorHandler.buildDepError "criterion"))
            (hsPkgs."http2" or (errorHandler.buildDepError "http2"))
            (hsPkgs."network-byte-order" or (errorHandler.buildDepError "network-byte-order"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/http2-5.4.9.tar.gz";
      sha256 = "8d108dbcbb60df0718e2d6d6c7fedc8ba035f580d373f560caa5dbf3c3c77fef";
    });
  }) // {
    package-description-override = "cabal-version:      2.0\nname:               http2\nversion:            5.4.9\nlicense:            BSD3\nlicense-file:       LICENSE\nmaintainer:         Kazu Yamamoto <kazu@iij.ad.jp>\nauthor:             Kazu Yamamoto <kazu@iij.ad.jp>\nhomepage:           https://github.com/kazu-yamamoto/http2\nsynopsis:           HTTP/2 library\ndescription:\n    HTTP/2 library including frames, HPACK, client and server.\n\ncategory:           Network\nbuild-type:         Simple\nextra-source-files:\n    ChangeLog.md\n    test/inputFile\n    test-hpack/hpack-test-case/go-hpack/*.json\n    test-hpack/hpack-test-case/haskell-http2-linear/*.json\n    test-hpack/hpack-test-case/haskell-http2-linear-huffman/*.json\n    test-hpack/hpack-test-case/haskell-http2-naive/*.json\n    test-hpack/hpack-test-case/haskell-http2-naive-huffman/*.json\n    test-hpack/hpack-test-case/haskell-http2-static/*.json\n    test-hpack/hpack-test-case/haskell-http2-static-huffman/*.json\n    test-hpack/hpack-test-case/nghttp2/*.json\n    test-hpack/hpack-test-case/nghttp2-16384-4096/*.json\n    test-hpack/hpack-test-case/nghttp2-change-table-size/*.json\n    test-hpack/hpack-test-case/node-http2-hpack/*.json\n    test-frame/http2-frame-test-case/continuation/*.json\n    test-frame/http2-frame-test-case/data/*.json\n    test-frame/http2-frame-test-case/error/*.json\n    test-frame/http2-frame-test-case/goaway/*.json\n    test-frame/http2-frame-test-case/headers/*.json\n    test-frame/http2-frame-test-case/ping/*.json\n    test-frame/http2-frame-test-case/priority/*.json\n    test-frame/http2-frame-test-case/push_promise/*.json\n    test-frame/http2-frame-test-case/rst_stream/*.json\n    test-frame/http2-frame-test-case/settings/*.json\n    test-frame/http2-frame-test-case/window_update/*.json\n    bench-hpack/headers.hs\n\nsource-repository head\n    type:     git\n    location: https://github.com/kazu-yamamoto/http2\n\nflag devel\n    description: Development commands\n    default:     False\n\nflag h2spec\n    description: Development commands\n    default:     False\n\nlibrary\n    exposed-modules:\n        Network.HPACK\n        Network.HPACK.Internal\n        Network.HPACK.Table\n        Network.HPACK.Token\n        Network.HTTP2.Client\n        Network.HTTP2.Client.Internal\n        Network.HTTP2.Frame\n        Network.HTTP2.Server\n        Network.HTTP2.Server.Internal\n\n    other-modules:\n        Imports\n        Network.HPACK.Builder\n        Network.HTTP2.Client.Run\n        Network.HPACK.HeaderBlock\n        Network.HPACK.HeaderBlock.Decode\n        Network.HPACK.HeaderBlock.Encode\n        Network.HPACK.HeaderBlock.Integer\n        Network.HPACK.Huffman\n        Network.HPACK.Huffman.Bit\n        Network.HPACK.Huffman.ByteString\n        Network.HPACK.Huffman.Decode\n        Network.HPACK.Huffman.Encode\n        Network.HPACK.Huffman.Params\n        Network.HPACK.Huffman.Table\n        Network.HPACK.Huffman.Tree\n        Network.HPACK.Table.Dynamic\n        Network.HPACK.Table.Entry\n        Network.HPACK.Table.RevIndex\n        Network.HPACK.Table.Static\n        Network.HPACK.Types\n        Network.HTTP2.H2\n        Network.HTTP2.H2.Config\n        Network.HTTP2.H2.Context\n        Network.HTTP2.H2.EncodeFrame\n        Network.HTTP2.H2.HPACK\n        Network.HTTP2.H2.OutBodyIface\n        Network.HTTP2.H2.Queue\n        Network.HTTP2.H2.Receiver\n        Network.HTTP2.H2.Sender\n        Network.HTTP2.H2.Settings\n        Network.HTTP2.H2.Stream\n        Network.HTTP2.H2.StreamTable\n        Network.HTTP2.H2.Sync\n        Network.HTTP2.H2.Types\n        Network.HTTP2.H2.Window\n        Network.HTTP2.Frame.Decode\n        Network.HTTP2.Frame.Encode\n        Network.HTTP2.Frame.Types\n        Network.HTTP2.Server.Run\n        Network.HTTP2.Server.Worker\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        array >=0.5 && <0.6,\n        async >=2.2 && <2.3,\n        bytestring >=0.10,\n        case-insensitive >=1.2 && <1.3,\n        containers >=0.6,\n        http-semantics >= 0.4 && <0.5,\n        http-types >=0.12 && <0.13,\n        iproute >= 1.7 && < 1.8,\n        network >=3.1,\n        network-byte-order >=0.1.7 && <0.2,\n        network-control >=0.1 && <0.2,\n        stm >=2.5 && <2.6,\n        time-manager >=0.3.0 && <0.5,\n        unix-time >=0.4.11 && <0.6,\n        utf8-string >=1.0 && <1.1\n\nexecutable h2c-client\n    main-is:            h2c-client.hs\n    hs-source-dirs:     util\n    default-language:   Haskell2010\n    other-modules:      Client Monitor\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded -rtsopts\n    build-depends:\n        base >=4.9 && <5,\n        async,\n        bytestring,\n        http-types,\n        http2,\n        network,\n        network-run >= 0.6 && <0.7,\n        unix-time\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable h2c-server\n    main-is:            h2c-server.hs\n    hs-source-dirs:     util\n    other-modules:      Server Monitor\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded\n    build-depends:\n        base >=4.9 && <5,\n        bytestring,\n        crypton,\n        http2,\n        http-types,\n        network-run\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable hpack-encode\n    main-is:            hpack-encode.hs\n    hs-source-dirs:     test-hpack\n    other-modules:\n        HPACKEncode\n        JSON\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        aeson >=2,\n        aeson-pretty,\n        array,\n        base16-bytestring >=1.0,\n        bytestring,\n        containers,\n        http2,\n        network-byte-order,\n        text,\n        unordered-containers,\n        vector,\n        word8\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable hpack-debug\n    main-is:            hpack-debug.hs\n    hs-source-dirs:     test-hpack\n    other-modules:\n        HPACKDecode\n        JSON\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        aeson >=2,\n        array,\n        base16-bytestring >=1.0,\n        bytestring,\n        containers,\n        http2,\n        network-byte-order,\n        text,\n        unordered-containers,\n        vector,\n        word8\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable hpack-stat\n    main-is:            hpack-stat.hs\n    hs-source-dirs:     test-hpack\n    other-modules:      JSON\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        aeson >=2,\n        aeson-pretty,\n        array,\n        bytestring,\n        containers,\n        directory,\n        filepath,\n        http2,\n        network-byte-order,\n        text,\n        unordered-containers,\n        vector,\n        word8\n\n    if flag(devel)\n\n    else\n        buildable: False\n\nexecutable frame-encode\n    main-is:            frame-encode.hs\n    hs-source-dirs:     test-frame\n    other-modules:\n        Case\n        JSON\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        aeson >=2,\n        aeson-pretty,\n        base16-bytestring >=1.0,\n        bytestring,\n        http2,\n        text,\n        unordered-containers\n\n    if flag(devel)\n\n    else\n        buildable: False\n\ntest-suite spec\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test\n    other-modules:\n        HPACK.DecodeSpec\n        HPACK.EncodeSpec\n        HPACK.HeaderBlock\n        HPACK.HuffmanSpec\n        HPACK.IntegerSpec\n        HTTP2.ClientSpec\n        HTTP2.FrameSpec\n        HTTP2.ServerSpec\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded\n    build-depends:\n        base >=4.9 && <5,\n        async,\n        base16-bytestring >=1.0,\n        bytestring,\n        crypton,\n        hspec >=1.3,\n        http-semantics,\n        http-types,\n        http2,\n        network,\n        network-byte-order,\n        network-run >= 0.6 && <0.7,\n        random,\n        typed-process\n\ntest-suite spec2\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test2\n    other-modules:      ServerSpec\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall -threaded\n    build-depends:\n        base >=4.9 && <5,\n        bytestring,\n        hspec >=1.3,\n        http-types,\n        http2,\n        network-run >= 0.6 && <0.7,\n        typed-process\n\n    if flag(h2spec)\n\n    else\n        buildable: False\n\ntest-suite hpack\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test-hpack\n    other-modules:\n        HPACKDecode\n        HPACKSpec\n        JSON\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        aeson >=2,\n        base16-bytestring >=1.0,\n        bytestring,\n        directory,\n        filepath,\n        hspec >=1.3,\n        http2,\n        text,\n        unordered-containers,\n        vector\n\ntest-suite frame\n    type:               exitcode-stdio-1.0\n    main-is:            Spec.hs\n    build-tool-depends: hspec-discover:hspec-discover\n    hs-source-dirs:     test-frame\n    other-modules:\n        Case\n        FrameSpec\n        JSON\n\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base >=4.9 && <5,\n        Glob >=0.9,\n        aeson >=2,\n        aeson-pretty,\n        base16-bytestring >=1.0,\n        bytestring,\n        directory,\n        filepath,\n        hspec >=1.3,\n        http2,\n        network-byte-order,\n        text,\n        unordered-containers\n\nbenchmark header-compression\n    type:               exitcode-stdio-1.0\n    main-is:            Main.hs\n    hs-source-dirs:     bench-hpack\n    default-language:   Haskell2010\n    default-extensions: Strict StrictData\n    ghc-options:        -Wall\n    build-depends:\n        base,\n        array,\n        bytestring,\n        case-insensitive,\n        containers,\n        criterion,\n        http2,\n        network-byte-order,\n        stm\n";
  }