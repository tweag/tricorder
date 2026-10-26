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
    flags = { mmaptest = false; };
    package = {
      specVersion = "1.6";
      identifier = { name = "mmap"; version = "0.5.9"; };
      license = "BSD-3-Clause";
      copyright = "2008-2012, Gracjan Polak";
      maintainer = "Gracjan Polak <gracjanpolak@gmail.com>";
      author = "Gracjan Polak <gracjanpolak@gmail.com>";
      homepage = "";
      url = "";
      synopsis = "Memory mapped files for POSIX and Windows";
      description = "This library provides a wrapper to mmap(2) or MapViewOfFile,\nallowing files or devices to be lazily loaded into memory as\nstrict or lazy ByteStrings, ForeignPtrs or plain Ptrs, using\nthe virtual memory subsystem to do on-demand loading.\nModifications are also supported.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
        ];
        buildable = true;
      };
      exes = {
        "mmaptest" = {
          depends = pkgs.lib.optionals (flags.mmaptest) [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."HUnit" or (errorHandler.buildDepError "HUnit"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          ] ++ pkgs.lib.optional (system.isWindows) (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"));
          buildable = if flags.mmaptest then true else false;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/mmap-0.5.9.tar.gz";
      sha256 = "58fcbb04e1cb8e7c36c05823b02dce2faaa989c53d745a7f36192de2fc98b5f8";
    });
  }) // {
    package-description-override = "Name: mmap\nVersion: 0.5.9\nStability: stable\nLicense: BSD3\nLicense-File: LICENSE\nCopyright: 2008-2012, Gracjan Polak\nAuthor: Gracjan Polak <gracjanpolak@gmail.com>\nMaintainer: Gracjan Polak <gracjanpolak@gmail.com>\nSynopsis: Memory mapped files for POSIX and Windows\nDescription:\n    This library provides a wrapper to mmap(2) or MapViewOfFile,\n    allowing files or devices to be lazily loaded into memory as\n    strict or lazy ByteStrings, ForeignPtrs or plain Ptrs, using\n    the virtual memory subsystem to do on-demand loading.\n    Modifications are also supported.\nCabal-version: >= 1.6\nCategory: System\nBuild-type: Simple\nExtra-Source-Files: cbits/HsMmap.h\n\nFlag mmaptest\n  Description: Generate mmaptest executable\n  Default: False\n\nSource-repository head\n  Type:     darcs\n  Location: http://code.haskell.org/mmap\n\nLibrary\n  Build-depends: base<5, bytestring\n  Extensions: ForeignFunctionInterface\n  Exposed-modules: System.IO.MMap\n  Hs-source-dirs: .\n  Include-dirs: cbits\n  GHC-options: -Wall\n  if os(mingw32)\n      C-sources: cbits/win32.c\n  else\n      C-sources: cbits/posix.c\n\nExecutable mmaptest\n  Main-is: tests/mmaptest.hs\n  if flag(mmaptest)\n      Buildable: True\n      Build-depends: base<5, bytestring, HUnit, directory\n  else\n      Buildable: False\n  Extensions: ForeignFunctionInterface, ScopedTypeVariables, CPP\n  Hs-source-dirs: .\n  CC-options: -Wall -D_DEBUG\n  Include-dirs: cbits\n  if os(mingw32)\n      cpp-options: -DWINDOWS\n      C-sources: cbits/win32.c\n      Build-depends: Win32\n  else\n      C-sources: cbits/posix.c\n";
  }