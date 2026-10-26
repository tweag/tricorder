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
      identifier = { name = "js-jquery"; version = "3.7.1"; };
      license = "MIT";
      copyright = "Neil Mitchell 2014-2025";
      maintainer = "Neil Mitchell <ndmitchell@gmail.com>";
      author = "Neil Mitchell <ndmitchell@gmail.com>";
      homepage = "https://github.com/ndmitchell/js-jquery#readme";
      url = "";
      synopsis = "Obtain minified jQuery code";
      description = "This package bundles the minified <http://jquery.com/ jQuery> code into a Haskell package,\nso it can be depended upon by Cabal packages. The first three components of\nthe version number match the upstream jQuery version. The package is designed\nto meet the redistribution requirements of downstream users (e.g. Debian).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
      tests = {
        "js-jquery-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."js-jquery" or (errorHandler.buildDepError "js-jquery"))
            (hsPkgs."HTTP" or (errorHandler.buildDepError "HTTP"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/js-jquery-3.7.1.tar.gz";
      sha256 = "a087fa01a1c52f5386d43f5355f64841c5a4b56b53720090d66b5aa00bfeb106";
    });
  }) // {
    package-description-override = "cabal-version:      1.18\nbuild-type:         Simple\nname:               js-jquery\nversion:            3.7.1\nlicense:            MIT\nlicense-file:       LICENSE\ncategory:           Javascript\nauthor:             Neil Mitchell <ndmitchell@gmail.com>\nmaintainer:         Neil Mitchell <ndmitchell@gmail.com>\ncopyright:          Neil Mitchell 2014-2025\nsynopsis:           Obtain minified jQuery code\ndescription:\n    This package bundles the minified <http://jquery.com/ jQuery> code into a Haskell package,\n    so it can be depended upon by Cabal packages. The first three components of\n    the version number match the upstream jQuery version. The package is designed\n    to meet the redistribution requirements of downstream users (e.g. Debian).\nhomepage:           https://github.com/ndmitchell/js-jquery#readme\nbug-reports:        https://github.com/ndmitchell/js-jquery/issues\ntested-with:        GHC==9.12, GHC==9.10, GHC==9.8, GHC==9.6, GHC==9.4, GHC==9.2, GHC==9.0\nextra-source-files:\n    javascript/jquery-3.7.1.js\nextra-doc-files:\n    CHANGES.txt\n    README.md\n\ndata-dir: javascript\ndata-files:\n    jquery-3.7.1.min.js\n\nsource-repository head\n    type:     git\n    location: https://github.com/ndmitchell/js-jquery.git\n\nlibrary\n    default-language: Haskell2010\n    hs-source-dirs:   src\n    build-depends:\n        base == 4.*\n\n    exposed-modules:\n        Language.Javascript.JQuery\n\n    other-modules:\n        Paths_js_jquery\n\ntest-suite js-jquery-test\n    default-language: Haskell2010\n    type: exitcode-stdio-1.0\n    main-is: src/Test.hs\n    other-modules:\n        Paths_js_jquery\n    build-depends:\n        base == 4.*,\n        js-jquery,\n        HTTP\n";
  }