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
    flags = { threaded = true; gpl = true; ghc-lib = true; hsyaml = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "hlint"; version = "3.10"; };
      license = "BSD-3-Clause";
      copyright = "Neil Mitchell 2006-2025";
      maintainer = "Neil Mitchell <ndmitchell@gmail.com>";
      author = "Neil Mitchell <ndmitchell@gmail.com>";
      homepage = "https://github.com/ndmitchell/hlint#readme";
      url = "";
      synopsis = "Source code suggestions";
      description = "HLint gives suggestions on how to improve your source code.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."file-embed" or (errorHandler.buildDepError "file-embed"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."cpphs" or (errorHandler.buildDepError "cpphs"))
          (hsPkgs."cmdargs" or (errorHandler.buildDepError "cmdargs"))
          (hsPkgs."uniplate" or (errorHandler.buildDepError "uniplate"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."refact" or (errorHandler.buildDepError "refact"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."deriving-aeson" or (errorHandler.buildDepError "deriving-aeson"))
          (hsPkgs."filepattern" or (errorHandler.buildDepError "filepattern"))
          (hsPkgs."ghc-lib-parser-ex" or (errorHandler.buildDepError "ghc-lib-parser-ex"))
        ] ++ (if !flags.ghc-lib && (compiler.isGhc && compiler.version.ge "9.12.1") && (compiler.isGhc && compiler.version.lt "9.13.0")
          then [
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
          ]
          else [
            (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
          ])) ++ pkgs.lib.optional (flags.gpl) (hsPkgs."hscolour" or (errorHandler.buildDepError "hscolour"))) ++ (if flags.hsyaml
          then [
            (hsPkgs."HsYAML" or (errorHandler.buildDepError "HsYAML"))
            (hsPkgs."HsYAML-aeson" or (errorHandler.buildDepError "HsYAML-aeson"))
          ]
          else [ (hsPkgs."yaml" or (errorHandler.buildDepError "yaml")) ]);
        buildable = true;
      };
      exes = {
        "hlint" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hlint" or (errorHandler.buildDepError "hlint"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hlint-3.10.tar.gz";
      sha256 = "d99672337c06b455884ac14418d562701143141d0d7e46af476817c2ae3efe37";
    });
  }) // {
    package-description-override = "cabal-version:      1.18\nbuild-type:         Simple\nname:               hlint\nversion:            3.10\nlicense:            BSD3\nlicense-file:       LICENSE\ncategory:           Development\nauthor:             Neil Mitchell <ndmitchell@gmail.com>\nmaintainer:         Neil Mitchell <ndmitchell@gmail.com>\ncopyright:          Neil Mitchell 2006-2025\nsynopsis:           Source code suggestions\ndescription:\n    HLint gives suggestions on how to improve your source code.\nhomepage:           https://github.com/ndmitchell/hlint#readme\nbug-reports:        https://github.com/ndmitchell/hlint/issues\ndata-dir:           data\ndata-files:\n    hlint.yaml\n    default.yaml\n    Test.hs\n    report_template.html\n    hs-lint.el\n    hlint.1\n    hlint.ghci\n    HLint_QuickCheck.hs\n    HLint_TypeCheck.hs\nextra-source-files:\n    .hlint.yaml\n    data/*.hs\n    data/*.yaml\n    tests/*.test\n    -- These are needed because of haskell/cabal#7862\n    data/default.yaml\n    data/hlint.yaml\n    data/report_template.html\nextra-doc-files:\n    README.md\n    CHANGES.txt\ntested-with:        GHC==9.12, GHC==9.10, GHC==9.8\n\nsource-repository head\n    type:     git\n    location: https://github.com/ndmitchell/hlint.git\n\nflag threaded\n    default: True\n    manual: True\n    description: Build with support for multithreaded execution\n\nflag gpl\n    default: True\n    manual: True\n    description: Use GPL libraries, specifically hscolour\n\nflag ghc-lib\n  default: True\n  manual: True\n  description: Force dependency on ghc-lib-parser even if GHC API in the ghc package is supported\n\nflag hsyaml\n  default: False\n  manual: True\n  description: Use HsYAML instead of yaml\n\nlibrary\n    default-language:   Haskell2010\n    build-depends:\n        base == 4.*, process, filepath, directory, containers,\n        unordered-containers, vector, text, bytestring,\n        transformers,\n        file-embed,\n        utf8-string,\n        data-default >= 0.3,\n        cpphs >= 1.20.1,\n        cmdargs >= 0.10.22,\n        uniplate >= 1.5,\n        ansi-terminal >= 0.8.1,\n        extra >= 1.7.3,\n        refact >= 0.3,\n        aeson >= 1.3,\n        deriving-aeson >= 0.2,\n        filepattern >= 0.1.1\n\n    if !flag(ghc-lib) && impl(ghc >= 9.12.1) && impl(ghc < 9.13.0)\n      build-depends:\n        ghc == 9.12.*,\n        ghc-boot-th,\n        ghc-boot\n    else\n      build-depends:\n          ghc-lib-parser == 9.12.*\n    build-depends:\n        ghc-lib-parser-ex >= 9.12.0.0 && < 9.13.0\n\n    if flag(gpl)\n        build-depends: hscolour >= 1.21\n    else\n        cpp-options: -DGPL_SCARES_ME\n\n    if flag(hsyaml)\n        build-depends:\n          HsYAML >= 0.2,\n          HsYAML-aeson >= 0.2\n        cpp-options: -DHS_YAML\n    else\n        build-depends: yaml >= 0.5.0\n\n    hs-source-dirs:     src\n    exposed-modules:\n        Language.Haskell.HLint\n    other-modules:\n        Paths_hlint\n        Apply\n        CmdLine\n        Extension\n        Fixity\n        HLint\n        HsColour\n        Idea\n        Report\n        Util\n        Parallel\n        Refact\n        Timing\n        CC\n        EmbedData\n        SARIF\n        Summary\n        Config.Compute\n        Config.Haskell\n        Config.Read\n        Config.Type\n        Config.Yaml\n\n        GHC.All\n        GHC.Util\n        GHC.Util.ApiAnnotation\n        GHC.Util.View\n        GHC.Util.Brackets\n        GHC.Util.DynFlags\n        GHC.Util.FreeVars\n        GHC.Util.HsDecl\n        GHC.Util.HsExpr\n        GHC.Util.SrcLoc\n        GHC.Util.Scope\n        GHC.Util.Unify\n\n        Hint.All\n        Hint.Bracket\n        Hint.Comment\n        Hint.Duplicate\n        Hint.Export\n        Hint.Extensions\n        Hint.Fixities\n        Hint.Import\n        Hint.Lambda\n        Hint.List\n        Hint.ListRec\n        Hint.Match\n        Hint.Monad\n        Hint.Naming\n        Hint.Negation\n        Hint.NewType\n        Hint.Pattern\n        Hint.Pragma\n        Hint.Restrict\n        Hint.Smell\n        Hint.Type\n        Hint.Unsafe\n        Hint.NumLiteral\n        Test.All\n        Test.Annotations\n        Test.InputOutput\n        Test.Util\n    ghc-options: -Wunused-binds -Wunused-imports -Worphans -Wprepositive-qualified-module\n\n\nexecutable hlint\n    default-language:   Haskell2010\n    build-depends:      base, hlint\n    main-is:            src/Main.hs\n\n    -- See https://github.com/ndmitchell/hlint/pull/1169 for benchmarks\n    -- that indicate -A32 is a good idea\n    ghc-options:        -rtsopts -with-rtsopts=-A32m\n    if flag(threaded)\n        ghc-options:    -threaded\n";
  }