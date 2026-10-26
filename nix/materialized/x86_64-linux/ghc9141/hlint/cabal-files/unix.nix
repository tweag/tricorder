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
    flags = { os-string = false; non-portable-tests = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "unix"; version = "2.8.8.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Julian Ospald <hasufell@posteo.de>, Viktor Dukhovni <ietf-dane@dukhovni.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>";
      author = "";
      homepage = "https://github.com/haskell/unix";
      url = "";
      synopsis = "POSIX functionality";
      description = "This package gives you access to the set of operating system\nservices standardised by\n<http://pubs.opengroup.org/onlinepubs/9699919799/ POSIX.1-2008>\n(or the IEEE Portable Operating System Interface for Computing\nEnvironments - IEEE Std. 1003.1).\n\nThe package is not supported under Windows.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
        ] ++ pkgs.lib.optional (system.isWindows) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"))) ++ (if flags.os-string
          then [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
          ]
          else [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          ]);
        buildable = if system.isWindows then false else true;
      };
      tests = {
        "unix-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ (if flags.os-string
            then [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
              (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            ]
            else [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            ]);
          buildable = true;
        };
        "FdReadBuf001" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "ForkProcess01" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Signals002" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Signals004" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Posix004" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Posix009" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Posix014" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "T8108" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "ResourceLimit" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Terminal" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "PutEnv001" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Semaphore001" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "Semaphore002" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "SemaphoreInterrupt" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (system.isJavaScript) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if system.isJavaScript then false else true;
        };
        "T13660" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          ] ++ (if flags.os-string
            then [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
              (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
            ]
            else [
              (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            ]);
          buildable = true;
        };
        "DirEnt" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ] ++ pkgs.lib.optional (!flags.non-portable-tests) (hsPkgs."unbuildable" or (errorHandler.buildDepError "unbuildable"));
          buildable = if !flags.non-portable-tests then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/unix-2.8.8.0.tar.gz";
      sha256 = "a128dea3bfeb731a562f22d376fa606e902154d95321363f7ec1ea6b787a5a3e";
    });
  }) // {
    package-description-override = "cabal-version:  1.12\r\nname:           unix\r\nversion:        2.8.8.0\r\nx-revision: 1\r\n-- NOTE: Don't forget to update ./changelog.md\r\n\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nmaintainer:     Julian Ospald <hasufell@posteo.de>, Viktor Dukhovni <ietf-dane@dukhovni.org>, Andrew Lelechenko <andrew.lelechenko@gmail.com>\r\nhomepage:       https://github.com/haskell/unix\r\nbug-reports:    https://github.com/haskell/unix/issues\r\nsynopsis:       POSIX functionality\r\ncategory:       System\r\nbuild-type:     Configure\r\ntested-with:    GHC==9.12.1,\r\n                GHC==9.10.1,\r\n                GHC==9.8.4,\r\n                GHC==9.6.6,\r\n                GHC==9.4.7,\r\n                GHC==9.2.8,\r\n                GHC==9.0.2,\r\n                GHC==8.10.7,\r\n                GHC==8.8.4,\r\n                GHC==8.6.5\r\ndescription:\r\n    This package gives you access to the set of operating system\r\n    services standardised by\r\n    <http://pubs.opengroup.org/onlinepubs/9699919799/ POSIX.1-2008>\r\n    (or the IEEE Portable Operating System Interface for Computing\r\n    Environments - IEEE Std. 1003.1).\r\n    .\r\n    The package is not supported under Windows.\r\n\r\nextra-source-files:\r\n    changelog.md\r\n    config.guess\r\n    config.sub\r\n    configure\r\n    configure.ac\r\n    include/HsUnix.h\r\n    include/HsUnixConfig.h.in\r\n    install-sh\r\n    unix.buildinfo.in\r\n\r\nextra-tmp-files:\r\n    autom4te.cache\r\n    config.log\r\n    config.status\r\n    include/HsUnixConfig.h\r\n    unix.buildinfo\r\n\r\nflag os-string\r\n  description: Use the new os-string package\r\n  default: False\r\n  manual: False\r\n\r\nflag non-portable-tests\r\n  description: Run tests that may not be portable across all systems, but are guaranteed to succeed in our own CI\r\n  default: False\r\n  manual: True\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/haskell/unix.git\r\n\r\nlibrary\r\n    default-language: Haskell2010\r\n    other-extensions:\r\n        CApiFFI\r\n        CPP\r\n        DeriveDataTypeable\r\n        InterruptibleFFI\r\n        NondecreasingIndentation\r\n        RankNTypes\r\n        RecordWildCards\r\n        Safe\r\n        Trustworthy\r\n\r\n    if os(windows)\r\n        -- This package currently supports neither Cygwin nor MinGW,\r\n        -- therefore os(windows) is effectively not supported.\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    build-depends:\r\n        base        >= 4.12.0.0  && < 4.23,\r\n        bytestring  >= 0.9.2     && < 0.13,\r\n        time        >= 1.9.1     && < 1.17\r\n\r\n    if flag(os-string)\r\n      build-depends: filepath >= 1.5.0.0, os-string >= 2.0.0\r\n    else\r\n      build-depends: filepath >= 1.4.100.0 && < 1.5.0.0\r\n\r\n    exposed-modules:\r\n        System.Posix\r\n        System.Posix.ByteString\r\n        System.Posix.PosixString\r\n\r\n        System.Posix.Error\r\n        System.Posix.Resource\r\n        System.Posix.Time\r\n        System.Posix.Unistd\r\n        System.Posix.Signals\r\n        System.Posix.Signals.Exts\r\n        System.Posix.Semaphore\r\n        System.Posix.SharedMem\r\n\r\n        System.Posix.User\r\n        System.Posix.User.ByteString\r\n\r\n        System.Posix.ByteString.FilePath\r\n        System.Posix.PosixPath.FilePath\r\n\r\n        System.Posix.Directory\r\n        System.Posix.Directory.Internals\r\n        System.Posix.Directory.Fd\r\n        System.Posix.Directory.ByteString\r\n        System.Posix.Directory.PosixPath\r\n\r\n        System.Posix.DynamicLinker.Module\r\n        System.Posix.DynamicLinker.Module.ByteString\r\n        System.Posix.DynamicLinker.Prim\r\n        System.Posix.DynamicLinker.ByteString\r\n        System.Posix.DynamicLinker\r\n\r\n        System.Posix.Files\r\n        System.Posix.Files.ByteString\r\n        System.Posix.Files.PosixString\r\n\r\n        System.Posix.IO\r\n        System.Posix.IO.ByteString\r\n        System.Posix.IO.PosixString\r\n\r\n        System.Posix.Env\r\n        System.Posix.Env.ByteString\r\n        System.Posix.Env.PosixString\r\n\r\n        System.Posix.Fcntl\r\n\r\n        System.Posix.Process\r\n        System.Posix.Process.Internals\r\n        System.Posix.Process.ByteString\r\n        System.Posix.Process.PosixString\r\n\r\n        System.Posix.Temp\r\n        System.Posix.Temp.ByteString\r\n        System.Posix.Temp.PosixString\r\n\r\n        System.Posix.Terminal\r\n        System.Posix.Terminal.ByteString\r\n        System.Posix.Terminal.PosixString\r\n\r\n    other-modules:\r\n        System.Posix.Directory.Common\r\n        System.Posix.DynamicLinker.Common\r\n        System.Posix.Files.Common\r\n        System.Posix.IO.Common\r\n        System.Posix.Process.Common\r\n        System.Posix.Terminal.Common\r\n        System.Posix.User.Common\r\n        System.Posix.Env.Internal\r\n\r\n    ghc-options: -Wall\r\n\r\n    include-dirs: include\r\n    install-includes:\r\n        HsUnix.h\r\n        execvpe.h\r\n\r\n    if !arch(javascript)\r\n      c-sources:\r\n          cbits/HsUnix.c\r\n          cbits/execvpe.c\r\n\r\n    if arch(javascript)\r\n      js-sources:\r\n          jsbits/time.js\r\n\r\ntest-suite unix-tests\r\n    hs-source-dirs: tests\r\n    main-is: Test.hs\r\n    other-modules:\r\n        FileStatus\r\n        FileExtendedStatus\r\n        FileStatusByteString\r\n        Signals001\r\n        ReadDirStream\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, bytestring, tasty, tasty-hunit, tasty-quickcheck, unix\r\n    if flag(os-string)\r\n      build-depends: filepath >= 1.5.0.0, os-string >= 2.0.0\r\n    else\r\n      build-depends: filepath >= 1.4.100.0 && < 1.5.0.0\r\n    ghc-options: -Wall -with-rtsopts=-V0\r\n\r\ntest-suite FdReadBuf001\r\n    -- JS: missing \"pipe\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: FdReadBuf001.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall -threaded\r\n\r\ntest-suite ForkProcess01\r\n    -- JS: missing \"forkProcess\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: ForkProcess01.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite Signals002\r\n    -- JS: missing \"raise\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Signals002.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite Signals004\r\n    -- JS: missing \"raise\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Signals004.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite Posix004\r\n    -- JS: missing \"forkProcess\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Posix004.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite Posix009\r\n    -- JS: missing \"rtsTimerSignal\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Posix009.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall -with-rtsopts=-V0\r\n\r\ntest-suite Posix014\r\n    -- JS: missing \"pipe\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Posix014.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite T8108\r\n    -- JS: missing \"sysconf\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: T8108.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite ResourceLimit\r\n    -- JS: missing \"setrlimit\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: ResourceLimit.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix, tasty-hunit\r\n    ghc-options: -Wall\r\n\r\ntest-suite Terminal\r\n    -- JS: missing \"openpty\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Terminal.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix, tasty-hunit\r\n    ghc-options: -Wall\r\n\r\ntest-suite PutEnv001\r\n    -- JS: missing \"performGC\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: PutEnv001.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix, tasty, tasty-hunit\r\n    ghc-options: -Wall -with-rtsopts=-V0 -O0\r\n\r\ntest-suite Semaphore001\r\n    -- JS: missing \"sem_open\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Semaphore001.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n\r\ntest-suite Semaphore002\r\n    -- JS: missing \"sem_open\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: Semaphore002.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall -threaded\r\n\r\ntest-suite SemaphoreInterrupt\r\n    -- JS: missing \"sem_open\"\r\n    if arch(javascript)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n    hs-source-dirs: tests\r\n    main-is: SemaphoreInterrupt.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall -threaded\r\n\r\ntest-suite T13660\r\n    hs-source-dirs: tests\r\n    main-is: T13660.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix, bytestring\r\n    if flag(os-string)\r\n      build-depends: filepath >= 1.5.0.0, os-string >= 2.0.0\r\n    else\r\n      build-depends: filepath >= 1.4.100.0 && < 1.5.0.0\r\n    ghc-options: -Wall\r\n\r\ntest-suite DirEnt\r\n    hs-source-dirs: tests\r\n    main-is: DirEnt.hs\r\n    type: exitcode-stdio-1.0\r\n    default-language: Haskell2010\r\n    build-depends: base, unix\r\n    ghc-options: -Wall\r\n    if !flag(non-portable-tests)\r\n        build-depends: unbuildable<0\r\n        buildable: False\r\n\r\n";
  }