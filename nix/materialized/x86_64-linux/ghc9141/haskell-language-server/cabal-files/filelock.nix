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
      identifier = { name = "filelock"; version = "0.1.1.9"; };
      license = "CC0-1.0";
      copyright = "";
      maintainer = "Andreas Abel";
      author = "Takano Akio";
      homepage = "https://github.com/haskell-pkg-janitors/filelock";
      url = "";
      synopsis = "Portable interface to file locking (flock / LockFileEx)";
      description = "This package provides an interface to Windows and Unix\nfile locking functionalities.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
      tests = {
        "test" = {
          depends = [
            (hsPkgs."filelock" or (errorHandler.buildDepError "filelock"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ];
          buildable = true;
        };
        "interrupt" = {
          depends = [
            (hsPkgs."filelock" or (errorHandler.buildDepError "filelock"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
          ];
          buildable = if system.isWindows then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/filelock-0.1.1.9.tar.gz";
      sha256 = "243248730399e383a10c276c476db8c735591716e0f6f34ca6120cb3a255eae7";
    });
  }) // {
    package-description-override = "cabal-version:       2.2\nname:                filelock\nversion:             0.1.1.9\nsynopsis:            Portable interface to file locking (flock / LockFileEx)\ndescription:         This package provides an interface to Windows and Unix\n                     file locking functionalities.\nhomepage:            https://github.com/haskell-pkg-janitors/filelock\nlicense:             CC0-1.0\nlicense-file:        LICENSE\nauthor:              Takano Akio\nmaintainer:          Andreas Abel\ncategory:            System\nbuild-type:          Simple\n\nextra-doc-files:\n  CHANGELOG.md\nextra-source-files:\n  tests/lock.log.expected\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n\nlibrary\n  hs-source-dirs:      .\n  exposed-modules:     System.FileLock\n  other-modules:       System.FileLock.Internal.Flock\n                       System.FileLock.Internal.LockFileEx\n  default-language:    Haskell2010\n\n  build-depends:       base >=4.11.0.0 && <5\n  build-tool-depends:  hsc2hs:hsc2hs\n\n  ghc-options:        -Wall\n  if os(windows)\n    cpp-options:      -DUSE_LOCKFILEEX\n    build-depends:    Win32\n  else\n    cpp-options:      -DUSE_FLOCK\n    build-depends:    unix\n\ntest-suite test\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     tests\n  main-is:            test.hs\n  build-depends:      filelock, process >= 1.2.1.0, async >= 2.0.0.0, base\n  ghc-options:        -threaded\n  default-language:   Haskell2010\n\ntest-suite interrupt\n  type:               exitcode-stdio-1.0\n  hs-source-dirs:     tests\n  main-is:            interrupt.hs\n  build-depends:      filelock, base\n  ghc-options:        -threaded\n  default-language:   Haskell2010\n  if os(windows)\n    buildable:        False\n\nsource-repository head\n  type: git\n  location: https://github.com/haskell-pkg-janitors/filelock.git\n";
  }