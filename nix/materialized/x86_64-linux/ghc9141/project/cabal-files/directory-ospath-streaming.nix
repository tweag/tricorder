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
    flags = { os-string = true; };
    package = {
      specVersion = "3.0";
      identifier = { name = "directory-ospath-streaming"; version = "0.3"; };
      license = "Apache-2.0";
      copyright = "(c) Sergey Vinokurov 2023";
      maintainer = "Sergey Vinokurov <serg.foo@gmail.com>";
      author = "Sergey Vinokurov";
      homepage = "https://github.com/sergv/directory-ospath-streaming";
      url = "";
      synopsis = "Stream directory entries in constant memory in vanilla IO";
      description = "Reading of directory contents in constant memory, i.e. in an iterative\nfashion without storing all directory elements in memory. From another\nperspective, this reading interface allows stopping at any point\nwithout loading every directory element.\n\nAlso defines general-purpose recursive directory traversals.\n\nBoth Windows and Unix systems are supported.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."atomic-counter" or (errorHandler.buildDepError "atomic-counter"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ (if flags.os-string
          then [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
          ]
          else [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          ])) ++ (if system.isWindows
          then [
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
          ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        buildable = true;
      };
      tests = {
        "test" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory-ospath-streaming" or (errorHandler.buildDepError "directory-ospath-streaming"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ] ++ (if flags.os-string
            then [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
              (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            ]
            else [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            ])) ++ pkgs.lib.optionals (!system.isWindows) [
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/directory-ospath-streaming-0.3.tar.gz";
      sha256 = "7e86ee4f4d17c98f4943ea3e224448563870123e19a5d0d2ab4b874ef5f10f42";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\r\n\r\n-- Created : 27 April 2023\r\n\r\nname:\r\n  directory-ospath-streaming\r\nversion:\r\n  0.3\r\nx-revision: 1\r\nsynopsis:\r\n  Stream directory entries in constant memory in vanilla IO\r\ndescription:\r\n  Reading of directory contents in constant memory, i.e. in an iterative\r\n  fashion without storing all directory elements in memory. From another\r\n  perspective, this reading interface allows stopping at any point\r\n  without loading every directory element.\r\n\r\n  Also defines general-purpose recursive directory traversals.\r\n\r\n  Both Windows and Unix systems are supported.\r\ncopyright:\r\n  (c) Sergey Vinokurov 2023\r\nlicense:\r\n  Apache-2.0\r\nlicense-file:\r\n  LICENSE\r\nauthor:\r\n  Sergey Vinokurov\r\nmaintainer:\r\n  Sergey Vinokurov <serg.foo@gmail.com>\r\ncategory:\r\n  File, Streaming\r\n\r\ntested-with:\r\n  , GHC == 8.6\r\n  , GHC == 8.8\r\n  , GHC == 8.10\r\n  , GHC == 9.2\r\n  , GHC == 9.4\r\n  , GHC == 9.6\r\n  , GHC == 9.8\r\n  , GHC == 9.10\r\n  , GHC == 9.12\r\n\r\nbuild-type:\r\n  Simple\r\n\r\nextra-source-files:\r\n  test/filesystem/*.txt\r\n  test/filesystem/bin/*.txt\r\n\r\nextra-doc-files:\r\n  Changelog.md\r\n  Readme.md\r\n\r\nhomepage:\r\n  https://github.com/sergv/directory-ospath-streaming\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/sergv/directory-ospath-streaming.git\r\n\r\n-- Cabal will pick this flag up automatically during solving. Default to true\r\n-- since that’s what should be picked up for all future filepath versions starting at 1.5.\r\nflag os-string\r\n  description:\r\n    Depend on os-string package, needed for filepath >= 1.5\r\n  default:\r\n    True\r\n  manual:\r\n    False\r\n\r\ncommon ghc-options\r\n  default-language: Haskell2010\r\n\r\n  ghc-options:\r\n    -Weverything\r\n    -Wno-all-missed-specialisations\r\n    -Wno-implicit-prelude\r\n    -Wno-missed-specialisations\r\n    -Wno-missing-import-lists\r\n    -Wno-missing-local-signatures\r\n    -Wno-safe\r\n    -Wno-unsafe\r\n\r\n  if impl(ghc >= 8.8)\r\n    ghc-options:\r\n      -Wno-missing-deriving-strategies\r\n\r\n  if impl(ghc >= 8.10)\r\n    ghc-options:\r\n      -Wno-missing-safe-haskell-mode\r\n      -Wno-prepositive-qualified-module\r\n\r\n  if impl(ghc >= 9.2)\r\n    ghc-options:\r\n      -Wno-missing-kind-signatures\r\n\r\n  if impl(ghc >= 9.8)\r\n    ghc-options:\r\n      -Wno-missing-role-annotations\r\n      -Wno-missing-poly-kind-signatures\r\n\r\ncommon depends-on-filepath\r\n  if flag(os-string)\r\n    build-depends:\r\n      , filepath >= 1.5\r\n      , os-string >= 2.0\r\n  else\r\n    build-depends:\r\n      , filepath >= 1.4.100 && < 1.5\r\n\r\nlibrary\r\n  import: ghc-options, depends-on-filepath\r\n  exposed-modules:\r\n    System.Directory.OsPath.Streaming\r\n    System.Directory.OsPath.Streaming.Internal\r\n    System.Directory.OsPath.Streaming.Internal.Raw\r\n    System.Directory.OsPath.Types\r\n  other-modules:\r\n    System.Directory.OsPath.Contents\r\n    System.Directory.OsPath.FileType\r\n    System.Directory.OsPath.Utils\r\n  hs-source-dirs:\r\n    src\r\n  build-depends:\r\n    , atomic-counter >= 0.1.2\r\n    , base >= 4.12 && < 5\r\n    , deepseq >= 1.4\r\n\r\n  if os(windows)\r\n    build-depends:\r\n      , directory >= 1.3.8\r\n      , Win32 >= 2.13.3\r\n  else\r\n    build-depends:\r\n      -- Cannot use lower version because it doesn’t support OsStrings\r\n      , unix >= 2.8\r\n\r\ntest-suite test\r\n  import: ghc-options, depends-on-filepath\r\n  type:\r\n    exitcode-stdio-1.0\r\n  main-is:\r\n    test/TestMain.hs\r\n  hs-source-dirs:\r\n    .\r\n    test\r\n  build-depends:\r\n    , base >= 4.12\r\n    , directory-ospath-streaming\r\n    , tasty\r\n    , tasty-hunit\r\n  if !os(windows)\r\n    build-depends:\r\n      , directory\r\n      , random\r\n      , unix >= 2.8\r\n  ghc-options:\r\n    -rtsopts\r\n    -main-is TestMain\r\n";
  }