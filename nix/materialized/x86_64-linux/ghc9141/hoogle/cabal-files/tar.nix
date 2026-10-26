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
      identifier = { name = "tar"; version = "0.7.2.0"; };
      license = "BSD-3-Clause";
      copyright = "2007 Bjorn Bringert <bjorn@bringert.net>\n2008-2016 Duncan Coutts <duncan@community.haskell.org>";
      maintainer = "Bodigrim <andrew.lelechenko@gmail.com>";
      author = "Duncan Coutts <duncan@community.haskell.org>\nBjorn Bringert <bjorn@bringert.net>";
      homepage = "";
      url = "";
      synopsis = "Reading, writing and manipulating \".tar\" archive files.";
      description = "This library is for working with \\\"@.tar@\\\" archive files. It\ncan read and write a range of common variations of archive\nformat including V7, POSIX USTAR and GNU formats.\n\nIt provides support for packing and unpacking portable\narchives. This makes it suitable for distribution but not\nbackup because details like file ownership and exact\npermissions are not preserved.\n\nIt also provides features for random access to archive\ncontent using an index.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."tar".components.sublibs.tar-internal or (errorHandler.buildDepError "tar:tar-internal"))
        ];
        buildable = true;
      };
      sublibs = {
        "tar-internal" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."directory-ospath-streaming" or (errorHandler.buildDepError "directory-ospath-streaming"))
            (hsPkgs."file-io" or (errorHandler.buildDepError "file-io"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = true;
        };
      };
      tests = {
        "properties" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."directory-ospath-streaming" or (errorHandler.buildDepError "directory-ospath-streaming"))
            (hsPkgs."file-embed" or (errorHandler.buildDepError "file-embed"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."tar".components.sublibs.tar-internal or (errorHandler.buildDepError "tar:tar-internal"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.0") (hsPkgs."bytestring-handle" or (errorHandler.buildDepError "bytestring-handle"));
          buildable = true;
        };
      };
      benchmarks = {
        "bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."tasty-bench" or (errorHandler.buildDepError "tasty-bench"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/tar-0.7.2.0.tar.gz";
      sha256 = "d84e77b028024eacf4324e805aa2eff4478a6249c7d9f2588c97273f41b88d5e";
    });
  }) // {
    package-description-override = "cabal-version:   2.2\nname:            tar\nversion:         0.7.2.0\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE\nauthor:          Duncan Coutts <duncan@community.haskell.org>\n                 Bjorn Bringert <bjorn@bringert.net>\nmaintainer:      Bodigrim <andrew.lelechenko@gmail.com>\nbug-reports:     https://github.com/haskell/tar/issues\ncopyright:       2007 Bjorn Bringert <bjorn@bringert.net>\n                 2008-2016 Duncan Coutts <duncan@community.haskell.org>\ncategory:        Codec\nsynopsis:        Reading, writing and manipulating \".tar\" archive files.\ndescription:     This library is for working with \\\"@.tar@\\\" archive files. It\n                 can read and write a range of common variations of archive\n                 format including V7, POSIX USTAR and GNU formats.\n                 .\n                 It provides support for packing and unpacking portable\n                 archives. This makes it suitable for distribution but not\n                 backup because details like file ownership and exact\n                 permissions are not preserved.\n                 .\n                 It also provides features for random access to archive\n                 content using an index.\nbuild-type:      Simple\nextra-source-files:\n                 test/data/long-filepath.tar\n                 test/data/long-symlink.tar\n                 test/data/symlink.tar\nextra-doc-files: changelog.md\n                 README.md\ntested-with:     GHC ==9.14.1, GHC==9.12.4, GHC==9.10.3, GHC==9.8.4,\n                 GHC==9.6.7, GHC==9.4.8, GHC==9.2.8, GHC==9.0.2,\n                 GHC==8.10.7, GHC==8.8.4, GHC==8.6.5\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell/tar.git\n\nlibrary\n  default-language: Haskell2010\n  build-depends: tar-internal\n\n  reexported-modules:\n    Codec.Archive.Tar,\n    Codec.Archive.Tar.Entry,\n    Codec.Archive.Tar.Check,\n    Codec.Archive.Tar.Index\n\nlibrary tar-internal\n  default-language: Haskell2010\n  build-depends: base       >= 4.12  && < 5,\n                 array                 < 0.6,\n                 bytestring >= 0.10 && < 0.13,\n                 containers >= 0.2  && < 0.9,\n                 deepseq    >= 1.1  && < 1.6,\n                 directory  >= 1.3.8.0 && < 1.4,\n                 directory-ospath-streaming >= 0.2.1 && < 0.4,\n                 file-io                < 0.3,\n                 filepath   >= 1.4.100 && < 1.6,\n                 os-string  >= 2.0 && < 2.1,\n                 time                  < 1.17,\n                 transformers          < 0.7,\n\n  exposed-modules:\n    Codec.Archive.Tar\n    Codec.Archive.Tar.Entry\n    Codec.Archive.Tar.Check\n    Codec.Archive.Tar.Check.Internal\n    Codec.Archive.Tar.Index\n    Codec.Archive.Tar.LongNames\n    Codec.Archive.Tar.Types\n    Codec.Archive.Tar.Read\n    Codec.Archive.Tar.Write\n    Codec.Archive.Tar.Pack\n    Codec.Archive.Tar.PackAscii\n    Codec.Archive.Tar.Unpack\n    Codec.Archive.Tar.Index.StringTable\n    Codec.Archive.Tar.Index.IntTrie\n    Codec.Archive.Tar.Index.Internal\n    Codec.Archive.Tar.Index.Utils\n\n  other-extensions:\n    BangPatterns\n    CPP\n    GeneralizedNewtypeDeriving\n    PatternGuards\n    ScopedTypeVariables\n\n  ghc-options: -Wall -fno-warn-unused-imports\n\ntest-suite properties\n  type:          exitcode-stdio-1.0\n  default-language: Haskell2010\n  build-depends: base < 5,\n                 array,\n                 bytestring >= 0.10,\n                 containers,\n                 deepseq,\n                 directory >= 1.2,\n                 directory-ospath-streaming,\n                 file-embed,\n                 filepath,\n                 QuickCheck       == 2.*,\n                 tar-internal,\n                 tasty            >= 0.10 && <1.6,\n                 tasty-quickcheck >= 0.8  && <1,\n                 temporary < 1.4,\n                 time\n  if impl(ghc < 9.0)\n    build-depends: bytestring-handle < 0.2\n\n  hs-source-dirs: test\n\n  main-is: Properties.hs\n\n  other-modules:\n    Codec.Archive.Tar.Tests\n    Codec.Archive.Tar.Index.Tests\n    Codec.Archive.Tar.Index.IntTrie.Tests\n    Codec.Archive.Tar.Index.StringTable.Tests\n    Codec.Archive.Tar.Pack.Tests\n    Codec.Archive.Tar.Types.Tests\n    Codec.Archive.Tar.Unpack.Tests\n\n  other-extensions:\n    CPP\n    BangPatterns,\n    ScopedTypeVariables\n\n  ghc-options: -fno-ignore-asserts\n\nbenchmark bench\n  type:          exitcode-stdio-1.0\n  default-language: Haskell2010\n  hs-source-dirs: bench\n  main-is:       Main.hs\n  build-depends: base < 5,\n                 tar,\n                 bytestring >= 0.10,\n                 directory >= 1.2,\n                 temporary < 1.4,\n                 tasty-bench >= 0.4 && < 0.6\n";
  }