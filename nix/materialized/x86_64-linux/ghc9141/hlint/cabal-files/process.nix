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
    flags = { os-string = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "process"; version = "1.6.30.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "libraries@haskell.org";
      author = "";
      homepage = "";
      url = "";
      synopsis = "Process libraries";
      description = "This package contains libraries for dealing with system processes.\n\nThe typed-process package is a more recent take on a process API,\nwhich uses this package internally. It features better binary\nsupport, easier concurrency, and a more composable API. You can\nread more about it at\n<https://github.com/fpco/typed-process/#readme>.";
      buildType = "Configure";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [
            (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
          ])) ++ (if flags.os-string
          then [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."os-string" or (errorHandler.buildDepError "os-string"))
          ]
          else [
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          ]);
        libs = pkgs.lib.optionals (system.isWindows) [
          (pkgs."kernel32" or (errorHandler.sysDepError "kernel32"))
          (pkgs."ole32" or (errorHandler.sysDepError "ole32"))
          (pkgs."rpcrt4" or (errorHandler.sysDepError "rpcrt4"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/process-1.6.30.0.tar.gz";
      sha256 = "accf821b45b016c284ee2634ef8243ce4c6a6db1a8610092af32d1b4e71b0be2";
    });
  }) // {
    package-description-override = "cabal-version: 2.4\nname:          process\nversion:       1.6.30.0\n-- NOTE: Don't forget to update ./changelog.md\nlicense:       BSD-3-Clause\nlicense-file:  LICENSE\nmaintainer:    libraries@haskell.org\nbug-reports:   https://github.com/haskell/process/issues\nsynopsis:      Process libraries\ncategory:      System\nbuild-type:    Configure\ndescription:\n    This package contains libraries for dealing with system processes.\n    .\n    The typed-process package is a more recent take on a process API,\n    which uses this package internally. It features better binary\n    support, easier concurrency, and a more composable API. You can\n    read more about it at\n    <https://github.com/fpco/typed-process/#readme>.\n\nextra-doc-files:\n    changelog.md\n\nextra-source-files:\n    aclocal.m4\n    configure\n    configure.ac\n    include/HsProcessConfig.h.in\n    process.buildinfo\n    exes/echo.bat\n    exes/subdir/echo.bat\n    cbits/posix/common.h\n\nextra-tmp-files:\n    autom4te.cache\n    config.log\n    config.status\n    include/HsProcessConfig.h\n\nsource-repository head\n    type:     git\n    location: https://github.com/haskell/process.git\n\nflag os-string\n    description: Use the new os-string package\n    default: False\n    manual: False\n\nlibrary\n    default-language: Haskell2010\n    other-extensions:\n        BangPatterns\n        CPP\n        InterruptibleFFI\n        RecordWildCards\n        Trustworthy\n        Safe\n\n    exposed-modules:\n        System.Cmd\n        System.Process\n        System.Process.CommunicationHandle\n        System.Process.CommunicationHandle.Internal\n        System.Process.Environment.OsString\n        System.Process.Internals\n    other-modules: System.Process.Common\n    if os(windows)\n        c-sources:\n            cbits/win32/runProcess.c\n        other-modules: System.Process.Windows\n        build-depends: Win32 >= 2.14.1.0 && < 2.15\n        -- ole32 and rpcrt4 are needed to create GUIDs for unique named pipes\n        -- for process.\n        extra-libraries: kernel32, ole32, rpcrt4\n        cpp-options: -DWINDOWS\n    else\n        build-depends: unix >= 2.8.0.0 && < 2.9\n        if arch(javascript)\n            js-sources:\n                jsbits/process.js\n            other-modules: System.Process.JavaScript\n        else\n            c-sources:\n                cbits/posix/runProcess.c\n                cbits/posix/fork_exec.c\n                cbits/posix/posix_spawn.c\n                cbits/posix/find_executable.c\n            other-modules: System.Process.Posix\n\n    -- On macOS, posix_spawn_file_actions_addchdir is available from macOS >= 26.\n    -- We weakly reference this symbol when we are build on such a platform.\n    -- However, weak references on MachO are hints to the dynamic loader, not the\n    -- static linker, which will still expect the symbol to be defined somewhere.\n    -- This means linking fails when we try to link an executable depending on\n    -- process on a toolchain which doesn't have this symbol against a process\n    -- library build on a toolchain with the symbol.\n    -- See https://github.com/haskell/process/issues/376\n    -- Hence: instruct the linker to explicilty allow undefined references to\n    -- the symbol when linking against process on darwin\n    if os(darwin)\n        ld-options: -Wl,-U,_posix_spawn_file_actions_addchdir\n\n    include-dirs: include\n    install-includes:\n        runProcess.h\n        processFlags.h\n\n    ghc-options: -Wall\n\n    build-depends: base      >= 4.12.0.0 && < 4.24,\n                   directory >= 1.1 && < 1.4,\n                   deepseq   >= 1.1 && < 1.6\n\n    if flag(os-string)\n        build-depends: filepath >= 1.5.0.0 && < 1.6,\n                       os-string >= 2.0.0 && < 2.1\n    else\n        build-depends: filepath >= 1.4.100.0 && < 1.5.0.0\n";
  }