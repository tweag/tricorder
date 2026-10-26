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
      identifier = { name = "hoogle"; version = "5.0.19.0"; };
      license = "BSD-3-Clause";
      copyright = "Neil Mitchell 2004-2026";
      maintainer = "Neil Mitchell <ndmitchell@gmail.com>";
      author = "Neil Mitchell <ndmitchell@gmail.com>";
      homepage = "https://hoogle.haskell.org/";
      url = "";
      synopsis = "Haskell API Search";
      description = "Hoogle is a Haskell API search engine, which allows you to\nsearch many standard Haskell libraries by either function name,\nor by approximate type signature.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."ansi-terminal" or (errorHandler.buildDepError "ansi-terminal"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."blaze-html" or (errorHandler.buildDepError "blaze-html"))
          (hsPkgs."blaze-markup" or (errorHandler.buildDepError "blaze-markup"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
          (hsPkgs."cmdargs" or (errorHandler.buildDepError "cmdargs"))
          (hsPkgs."conduit" or (errorHandler.buildDepError "conduit"))
          (hsPkgs."conduit-extra" or (errorHandler.buildDepError "conduit-extra"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."crypton-connection" or (errorHandler.buildDepError "crypton-connection"))
          (hsPkgs."data-default-class" or (errorHandler.buildDepError "data-default-class"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
          (hsPkgs."hackage-revdeps" or (errorHandler.buildDepError "hackage-revdeps"))
          (hsPkgs."old-locale" or (errorHandler.buildDepError "old-locale"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."haskell-src-exts" or (errorHandler.buildDepError "haskell-src-exts"))
          (hsPkgs."http-conduit" or (errorHandler.buildDepError "http-conduit"))
          (hsPkgs."http-types" or (errorHandler.buildDepError "http-types"))
          (hsPkgs."js-flot" or (errorHandler.buildDepError "js-flot"))
          (hsPkgs."js-jquery" or (errorHandler.buildDepError "js-jquery"))
          (hsPkgs."mmap" or (errorHandler.buildDepError "mmap"))
          (hsPkgs."process-extras" or (errorHandler.buildDepError "process-extras"))
          (hsPkgs."resourcet" or (errorHandler.buildDepError "resourcet"))
          (hsPkgs."safe" or (errorHandler.buildDepError "safe"))
          (hsPkgs."storable-tuple" or (errorHandler.buildDepError "storable-tuple"))
          (hsPkgs."tar" or (errorHandler.buildDepError "tar"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."time" or (errorHandler.buildDepError "time"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."uniplate" or (errorHandler.buildDepError "uniplate"))
          (hsPkgs."utf8-string" or (errorHandler.buildDepError "utf8-string"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."wai" or (errorHandler.buildDepError "wai"))
          (hsPkgs."wai-logger" or (errorHandler.buildDepError "wai-logger"))
          (hsPkgs."warp" or (errorHandler.buildDepError "warp"))
          (hsPkgs."warp-tls" or (errorHandler.buildDepError "warp-tls"))
          (hsPkgs."zlib" or (errorHandler.buildDepError "zlib"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "8.0") (hsPkgs."semigroups" or (errorHandler.buildDepError "semigroups"));
        buildable = true;
      };
      exes = {
        "hoogle" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."hoogle" or (errorHandler.buildDepError "hoogle"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/hoogle-5.0.19.0.tar.gz";
      sha256 = "a37d3d785935868b9d7e73e1e826fbb25303bd4b16ffa5ea7ae469b0ef091b17";
    });
  }) // {
    package-description-override = "cabal-version:      1.18\r\nbuild-type:         Simple\r\nname:               hoogle\r\nversion:            5.0.19.0\r\nx-revision: 2\r\nlicense:            BSD3\r\nlicense-file:       LICENSE\r\ncategory:           Development\r\nauthor:             Neil Mitchell <ndmitchell@gmail.com>\r\nmaintainer:         Neil Mitchell <ndmitchell@gmail.com>\r\ncopyright:          Neil Mitchell 2004-2026\r\nsynopsis:           Haskell API Search\r\ndescription:\r\n    Hoogle is a Haskell API search engine, which allows you to\r\n    search many standard Haskell libraries by either function name,\r\n    or by approximate type signature.\r\nhomepage:           https://hoogle.haskell.org/\r\nbug-reports:        https://github.com/ndmitchell/hoogle/issues\r\ntested-with:        GHC==9.8, GHC==9.6, GHC==9.4\r\nextra-doc-files:\r\n    README.md\r\n    CHANGES.txt\r\nextra-source-files:\r\n    cbits/*.h\r\n    cbits/*.c\r\ndata-files:\r\n    misc/sample-data/henry.txt\r\n    misc/sample-data/emily-1.11/emily.txt\r\n    misc/sample-data/emily-1.2/emily.txt\r\n    misc/settings.txt\r\n    html/*.js\r\n    html/*.png\r\n    html/*.css\r\n    html/*.xml\r\n    html/*.html\r\n    html/plugin/*.css\r\n    html/plugin/*.js\r\n    html/plugin/*.png\r\n\r\nsource-repository head\r\n    type:     git\r\n    location: https://github.com/ndmitchell/hoogle.git\r\n\r\nlibrary\r\n    hs-source-dirs:     src\r\n    default-language:   Haskell2010\r\n\r\n    build-depends:\r\n        QuickCheck,\r\n        aeson >= 2,\r\n        ansi-terminal,\r\n        base >= 4 && < 5,\r\n        blaze-html,\r\n        blaze-markup,\r\n        binary,\r\n        bytestring >= 0.10.2.0,\r\n        Cabal-syntax >= 3.8,\r\n        cmdargs,\r\n        conduit >= 1.3.0,\r\n        conduit-extra >= 1.2.3.2,\r\n        containers >= 0.5,\r\n        crypton-connection >= 0.4.1,\r\n        data-default-class,\r\n        deepseq,\r\n        directory,\r\n        extra >= 1.6.6,\r\n        filepath,\r\n        ghc-lib-parser >= 9.6.5 && < 9.16,\r\n        hackage-revdeps >= 0.3 && < 0.5,\r\n        old-locale,\r\n        hashable,\r\n        haskell-src-exts >= 1.22 && < 1.25,\r\n        http-conduit >= 2.3,\r\n        http-types,\r\n        js-flot,\r\n        js-jquery,\r\n        mmap,\r\n        process-extras,\r\n        resourcet,\r\n        safe >= 0.3.20,\r\n        storable-tuple,\r\n        tar,\r\n        template-haskell,\r\n        temporary,\r\n        text >= 2,\r\n        time >= 1.5,\r\n        transformers,\r\n        uniplate,\r\n        utf8-string >= 0.3.1,\r\n        vector,\r\n        wai,\r\n        wai-logger,\r\n        warp,\r\n        warp-tls >= 3.4.2,\r\n        zlib\r\n\r\n    c-sources:        cbits/text_search.c\r\n    include-dirs:     cbits\r\n    includes:         include.h\r\n    install-includes: include.h\r\n    cc-options:       -std=c99\r\n\r\n    ghc-options:      -fno-state-hack\r\n    if impl(ghc < 8.0)\r\n        build-depends: semigroups >= 0.18\r\n\r\n    exposed-modules:\r\n        Hoogle\r\n\r\n    other-modules:\r\n        Paths_hoogle\r\n        Action.CmdLine\r\n        Action.Generate\r\n        Action.Search\r\n        Action.Server\r\n        Action.Test\r\n        Input.Cabal\r\n        Input.Download\r\n        Input.Haddock\r\n        Input.Item\r\n        Input.ParseDecl\r\n        Input.Reorder\r\n        Input.Set\r\n        Input.Settings\r\n        Output.Items\r\n        Output.Names\r\n        Output.Tags\r\n        Output.Types\r\n        Query\r\n        General.Conduit\r\n        General.IString\r\n        General.Log\r\n        General.Store\r\n        General.Str\r\n        General.Template\r\n        General.Timing\r\n        General.Util\r\n        General.Web\r\n\r\n\r\nexecutable hoogle\r\n    main-is:            src/Main.hs\r\n    default-language:   Haskell2010\r\n    ghc-options:        -threaded -rtsopts\r\n\r\n    build-depends:\r\n        base >= 4 && < 5,\r\n        hoogle\r\n";
  }