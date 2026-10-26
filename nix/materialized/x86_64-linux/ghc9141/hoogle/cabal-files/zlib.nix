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
      non-blocking-ffi = true;
      pkg-config = true;
      bundled-c-zlib = false;
    };
    package = {
      specVersion = "1.10";
      identifier = { name = "zlib"; version = "0.7.1.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2006-2016 Duncan Coutts";
      maintainer = "Duncan Coutts <duncan@community.haskell.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>, Emily Pillmore <emilypi@cohomolo.gy>, Herbert Valerio Riedel <hvr@gnu.org>";
      author = "Duncan Coutts <duncan@community.haskell.org>";
      homepage = "";
      url = "";
      synopsis = "Compression and decompression in the gzip and zlib formats";
      description = "This package provides a pure interface for compressing and\ndecompressing streams of data represented as lazy\n'ByteString's. It uses the\n<https://en.wikipedia.org/wiki/Zlib zlib C library>\nso it has high performance. It supports the \\\"zlib\\\",\n\\\"gzip\\\" and \\\"raw\\\" compression formats.\n\nIt provides a convenient high level API suitable for most\ntasks and for the few cases where more control is needed it\nprovides access to the full zlib feature set.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ] ++ pkgs.lib.optional (flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows) (hsPkgs."zlib-clib" or (errorHandler.buildDepError "zlib-clib"));
        libs = pkgs.lib.optionals (!(flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows)) (pkgs.lib.optional (!flags.pkg-config) (pkgs."z" or (errorHandler.sysDepError "z")));
        pkgconfig = pkgs.lib.optionals (!(flags.bundled-c-zlib || compiler.isGhcjs && true || system.isGhcjs || system.isWasm32 || !flags.pkg-config && system.isWindows)) (pkgs.lib.optional (flags.pkg-config) (pkgconfPkgs."zlib" or (errorHandler.pkgConfDepError "zlib")));
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ] ++ pkgs.lib.optional (system.isWindows && (compiler.isGhc && compiler.version.lt "8.4")) (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")));
        buildable = true;
      };
      tests = {
        "tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/zlib-0.7.1.1.tar.gz";
      sha256 = "bf95ab01ed924be800addea195fba5ca97ec69f378368f6ff466bdc29666c1c1";
    });
  }) // {
    package-description-override = "cabal-version:   >= 1.10\r\nname:            zlib\r\nversion:         0.7.1.1\r\nx-revision: 1\r\n\r\ncopyright:       (c) 2006-2016 Duncan Coutts\r\nlicense:         BSD3\r\nlicense-file:    LICENSE\r\nauthor:          Duncan Coutts <duncan@community.haskell.org>\r\nmaintainer:      Duncan Coutts <duncan@community.haskell.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>, Emily Pillmore <emilypi@cohomolo.gy>, Herbert Valerio Riedel <hvr@gnu.org>\r\nbug-reports:     https://github.com/haskell/zlib/issues\r\ncategory:        Codec\r\nsynopsis:        Compression and decompression in the gzip and zlib formats\r\ndescription:     This package provides a pure interface for compressing and\r\n                 decompressing streams of data represented as lazy\r\n                 'ByteString's. It uses the\r\n                 <https://en.wikipedia.org/wiki/Zlib zlib C library>\r\n                 so it has high performance. It supports the \\\"zlib\\\",\r\n                 \\\"gzip\\\" and \\\"raw\\\" compression formats.\r\n                 .\r\n                 It provides a convenient high level API suitable for most\r\n                 tasks and for the few cases where more control is needed it\r\n                 provides access to the full zlib feature set.\r\nbuild-type:      Simple\r\n\r\ntested-with:     GHC == 8.0.2\r\n               , GHC == 8.2.2\r\n               , GHC == 8.4.4\r\n               , GHC == 8.6.5\r\n               , GHC == 8.8.4\r\n               , GHC == 8.10.7\r\n               , GHC == 9.0.2\r\n               , GHC == 9.2.8\r\n               , GHC == 9.4.8\r\n               , GHC == 9.6.7\r\n               , GHC == 9.8.4\r\n               , GHC == 9.10.2\r\n               , GHC == 9.12.2\r\n               , GHC == 9.14.1\r\n\r\nextra-source-files: changelog.md\r\n                    README.md\r\n                    -- extra headers\r\n                    cbits-extra/hs-zlib.h\r\n                    -- test data files\r\n                    test/data/bad-crc.gz test/data/custom-dict.zlib\r\n                    test/data/custom-dict.zlib-dict test/data/hello.gz\r\n                    test/data/not-gzip test/data/two-files.gz\r\n                    -- demo programs:\r\n                    examples/gzip.hs examples/gunzip.hs\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/haskell/zlib.git\r\n\r\nflag non-blocking-ffi\r\n  default:     True\r\n  manual:      True\r\n  description: The (de)compression calls can sometimes take a long time, which\r\n               prevents other Haskell threads running. Enabling this flag\r\n               avoids this unfairness, but with greater overall cost.\r\n\r\nflag pkg-config\r\n  default:     True\r\n  manual:      False\r\n  description: Use @pkg-config@ executable to locate foreign @zlib@ library.\r\n\r\nflag bundled-c-zlib\r\n  default:     False\r\n  manual:      True\r\n  description: Use @zlib-clib@ package with C sources instead of a system library.\r\n               C sources are used for GHCJS and WASM unconditionally\r\n               and on Windows unless @pkg-config@ flag is on.\r\n\r\nlibrary\r\n  exposed-modules: Codec.Compression.GZip,\r\n                   Codec.Compression.Zlib,\r\n                   Codec.Compression.Zlib.Raw,\r\n                   Codec.Compression.Zlib.Internal\r\n  other-modules:   Codec.Compression.Zlib.Stream,\r\n                   Codec.Compression.Zlib.ByteStringCompat\r\n\r\n  default-language: Haskell2010\r\n\r\n  other-extensions: CPP, ForeignFunctionInterface, RankNTypes, BangPatterns\r\n  other-extensions: DeriveGeneric\r\n  other-extensions: CApiFFI\r\n\r\n  build-depends:   base >= 4.9 && < 4.24,\r\n                   bytestring >= 0.9 && < 0.13\r\n\r\n  build-tools:     hsc2hs >= 0.67 && < 0.69\r\n  if os(windows) && impl(ghc < 8.4)\r\n    build-tools:     hsc2hs < 0.68.5\r\n    -- GHC 7 ships hsc2hs-0.67\r\n\r\n  include-dirs:    cbits-extra\r\n  c-sources:       cbits-extra/hs-zlib.c\r\n  ghc-options:     -Wall -fwarn-tabs\r\n  if flag(non-blocking-ffi)\r\n    cpp-options:   -DNON_BLOCKING_FFI\r\n\r\n  -- Cross-platform builds (such as JS and WASM) must have access\r\n  -- to C sources, so using zlib-clib unconditionally.\r\n  --\r\n  -- On Windows, zlib is shipped as part of GHC's mingw/lib directory,\r\n  -- which GHC always includes in its linker search path. However,\r\n  -- there is no guarantee that zlib1.dll (the corresponding shared library)\r\n  -- will be available on the user's PATH at runtime, making it risky to depend upon\r\n  -- (see https://github.com/haskell/zlib/issues/65 for what can go wrong).\r\n  -- Thus, we resort to zlib-clib unless pkg-config is available.\r\n  if flag(bundled-c-zlib) || impl(ghcjs) || os(ghcjs) || arch(wasm32) || (!flag(pkg-config) && os(windows))\r\n    build-depends: zlib-clib < 2\r\n  else\r\n    if flag(pkg-config)\r\n      -- NB: pkg-config is available on windows as well when using msys2\r\n      pkgconfig-depends: zlib\r\n    else\r\n      extra-libraries: z\r\n\r\ntest-suite tests\r\n  type: exitcode-stdio-1.0\r\n  main-is:         Test.hs\r\n  other-modules:   Utils,\r\n                   Test.Codec.Compression.Zlib.Internal,\r\n                   Test.Codec.Compression.Zlib.Stream\r\n  hs-source-dirs:  test\r\n  default-language: Haskell2010\r\n  build-depends:   base, bytestring, zlib,\r\n                   QuickCheck       == 2.*,\r\n                   tasty            >= 0.8 && < 1.6,\r\n                   tasty-quickcheck >= 0.8 && < 1\r\n  ghc-options:     -Wall\r\n\r\n  if impl(ghc >= 9.4)\r\n    ghc-options:   \"-with-rtsopts=-M1G\"\r\n";
  }