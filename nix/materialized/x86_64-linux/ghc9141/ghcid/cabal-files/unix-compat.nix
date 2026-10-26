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
      specVersion = "1.18";
      identifier = { name = "unix-compat"; version = "0.7.4.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "https://github.com/haskell-pkg-janitors";
      author = "Björn Bringert, Duncan Coutts, Jacob Stanley, Bryan O'Sullivan";
      homepage = "https://github.com/haskell-pkg-janitors/unix-compat";
      url = "";
      synopsis = "Portable POSIX-compatibility layer.";
      description = "This package provides portable implementations of parts\nof the unix package. This package re-exports the unix\npackage when available. When it isn't available,\nportable implementations are used.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ (if system.isWindows
          then [
            (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ]
          else [ (hsPkgs."unix" or (errorHandler.buildDepError "unix")) ]);
        libs = pkgs.lib.optional (system.isWindows) (pkgs."msvcrt" or (errorHandler.sysDepError "msvcrt"));
        buildable = true;
      };
      tests = {
        "unix-compat-testsuite" = {
          depends = [
            (hsPkgs."unix-compat" or (errorHandler.buildDepError "unix-compat"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."monad-parallel" or (errorHandler.buildDepError "monad-parallel"))
            (hsPkgs."hspec" or (errorHandler.buildDepError "hspec"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/unix-compat-0.7.4.1.tar.gz";
      sha256 = "3f9611624a100c75e672d900e63fe7a0e595615a34e6605662edaff151e44054";
    });
  }) // {
    package-description-override = "cabal-version:  1.18\nname:           unix-compat\nversion:        0.7.4.1\nsynopsis:       Portable POSIX-compatibility layer.\ndescription:    This package provides portable implementations of parts\n                of the unix package. This package re-exports the unix\n                package when available. When it isn't available,\n                portable implementations are used.\n\nhomepage:       https://github.com/haskell-pkg-janitors/unix-compat\nlicense:        BSD3\nlicense-file:   LICENSE\nauthor:         Björn Bringert, Duncan Coutts, Jacob Stanley, Bryan O'Sullivan\nmaintainer:     https://github.com/haskell-pkg-janitors\ncategory:       System\nbuild-type:     Simple\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nextra-doc-files:\n  CHANGELOG.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-pkg-janitors/unix-compat.git\n\nLibrary\n  hs-source-dirs: src\n\n  exposed-modules:\n    System.PosixCompat\n    System.PosixCompat.Extensions\n    System.PosixCompat.Files\n    System.PosixCompat.Process\n    System.PosixCompat.Temp\n    System.PosixCompat.Time\n    System.PosixCompat.Types\n    System.PosixCompat.Unistd\n\n  build-depends: base >= 4.9 && < 5\n\n  if os(windows)\n    c-sources:\n      cbits/HsUname.c\n      cbits/mktemp.c\n\n    extra-libraries: msvcrt\n    build-depends: Win32     >= 2.5.0.0  && < 3\n    build-depends: directory >= 1.3.1    && < 1.4\n    build-depends: filepath  >= 1.4.1.0  && < 1.6\n    build-depends: time      >= 1.6.0.1  && < 2\n\n    other-modules:\n      System.PosixCompat.Internal.Time\n\n  else\n    build-depends: unix      >= 2.7.2.0  && < 2.9\n    if arch(wasm32)\n      c-sources: cbits/mktemp.c\n    else\n      include-dirs: include\n      includes: HsUnixCompat.h\n      install-includes: HsUnixCompat.h\n      c-sources: cbits/HsUnixCompat.c\n    if os(solaris)\n      cc-options: -DSOLARIS\n\n  default-language: Haskell2010\n  ghc-options:\n    -Wall\n    -Wcompat\n\nTest-Suite unix-compat-testsuite\n  type: exitcode-stdio-1.0\n  hs-source-dirs: tests\n  main-is: main.hs\n\n  other-modules:\n     MkstempSpec\n     LinksSpec\n     ProcessSpec\n\n  build-depends:\n      unix-compat\n    , base\n    , monad-parallel\n    , hspec >= 2.5.5\n    , HUnit\n    , directory >= 1.3.1.0\n        -- directory-1.3.1.0 adds createFileLink\n    , temporary\n\n  default-language: Haskell2010\n  ghc-options:\n    -Wall\n    -Wcompat\n";
  }