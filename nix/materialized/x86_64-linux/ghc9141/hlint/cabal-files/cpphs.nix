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
      identifier = { name = "cpphs"; version = "1.20.10"; };
      license = "LicenseRef-LGPL";
      copyright = "2004-2017, Malcolm Wallace";
      maintainer = "Andreas Abel";
      author = "Malcolm Wallace <Malcolm.Wallace@me.com>";
      homepage = "";
      url = "";
      synopsis = "A liberalised re-implementation of cpp, the C pre-processor.";
      description = "Cpphs is a re-implementation of the C pre-processor that is both\nmore compatible with Haskell, and itself written in Haskell so\nthat it can be distributed with compilers.\n\nThis version of the C pre-processor is pretty-much\nfeature-complete and compatible with traditional (K&R)\npre-processors.  Additional features include: a plain-text mode;\nan option to unlit literate code files; and an option to turn\noff macro-expansion.\n\nOld homepage: <https://archives.haskell.org/projects.haskell.org/cpphs/>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."polyparse" or (errorHandler.buildDepError "polyparse"))
        ];
        buildable = true;
      };
      exes = {
        "cpphs" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
            (hsPkgs."polyparse" or (errorHandler.buildDepError "polyparse"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/cpphs-1.20.10.tar.gz";
      sha256 = "7fa78ae9a2a1d1c69179238e8849340ad26be6496b763a489bf2e0eb5b7c4c19";
    });
  }) // {
    package-description-override = "Cabal-Version: 1.18\nName: cpphs\nVersion: 1.20.10\nCopyright: 2004-2017, Malcolm Wallace\nLicense: LGPL\nLicense-File: LICENCE-LGPL\nAuthor: Malcolm Wallace <Malcolm.Wallace@me.com>\nMaintainer: Andreas Abel\n-- homepage:\nbug-reports: https://github.com/haskell-pkg-janitors/cpphs/issues\nSynopsis: A liberalised re-implementation of cpp, the C pre-processor.\nDescription:\n    Cpphs is a re-implementation of the C pre-processor that is both\n    more compatible with Haskell, and itself written in Haskell so\n    that it can be distributed with compilers.\n    .\n    This version of the C pre-processor is pretty-much\n    feature-complete and compatible with traditional (K&R)\n    pre-processors.  Additional features include: a plain-text mode;\n    an option to unlit literate code files; and an option to turn\n    off macro-expansion.\n    .\n    Old homepage: <https://archives.haskell.org/projects.haskell.org/cpphs/>\nCategory: Development\nBuild-type: Simple\n\nExtra-Doc-Files:\n  README.md\n  LICENCE-GPL\n  LICENCE-commercial\n  CHANGELOG.md\n  docs/cpphs.1\n  docs/index.html\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.2\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nSource-Repository head\n    Type:     git\n    Location: https://github.com/haskell-pkg-janitors/cpphs.git\n\nLibrary\n    Hs-Source-Dirs: . new\n\n    Build-Depends:\n      -- GHC-shipped libraries\n        base      >= 4.9  && < 5\n      , directory            < 1.4\n      , time      >= 1.5  && < 2\n      -- Other libraries\n      , polyparse >= 1.13 && < 1.14\n\n    Exposed-Modules:\n        Language.Preprocessor.Cpphs\n        Language.Preprocessor.Unlit\n    Other-Modules:\n        Language.Preprocessor.Cpphs.CppIfdef\n        Language.Preprocessor.Cpphs.HashDefine\n        Language.Preprocessor.Cpphs.MacroPass\n        Language.Preprocessor.Cpphs.Options\n        Language.Preprocessor.Cpphs.Position\n        Language.Preprocessor.Cpphs.ReadFirst\n        Language.Preprocessor.Cpphs.RunCpphs\n        Language.Preprocessor.Cpphs.SymTab\n        Language.Preprocessor.Cpphs.Tokenise\n        TimeCompat\n\n    default-language: Haskell2010\n\nExecutable cpphs\n    Hs-Source-Dirs: . new\n    Main-Is: cpphs.hs\n\n    Build-Depends:\n      -- GHC-shipped libraries\n        base      >= 4.9  && < 5\n      , directory            < 1.4\n      , time      >= 1.5  && < 2\n      -- Other libraries\n      , polyparse >= 1.13 && < 1.14\n\n    Other-Modules:\n        Language.Preprocessor.Cpphs\n        Language.Preprocessor.Unlit\n        Language.Preprocessor.Cpphs.CppIfdef\n        Language.Preprocessor.Cpphs.HashDefine\n        Language.Preprocessor.Cpphs.MacroPass\n        Language.Preprocessor.Cpphs.Options\n        Language.Preprocessor.Cpphs.Position\n        Language.Preprocessor.Cpphs.ReadFirst\n        Language.Preprocessor.Cpphs.RunCpphs\n        Language.Preprocessor.Cpphs.SymTab\n        Language.Preprocessor.Cpphs.Tokenise\n        TimeCompat\n\n    default-language: Haskell2010\n";
  }