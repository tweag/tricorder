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
    flags = { safe = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "void"; version = "0.7.4"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (C) 2008-2015 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/ekmett/void";
      url = "";
      synopsis = "A Haskell 98 logically uninhabited data type";
      description = "A Haskell 98 logically uninhabited data type, used to indicate that a given term should not exist.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/void-0.7.4.tar.gz";
      sha256 = "61ff790961edb34fd653e62f9f37020792f416f329b12e87549169e7f624fdf9";
    });
  }) // {
    package-description-override = "name:          void\r\ncategory:      Data Structures\r\nversion:       0.7.4\r\nx-revision: 1\r\nlicense:       BSD3\r\ncabal-version: >= 1.10\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     portable\r\nhomepage:      http://github.com/ekmett/void\r\nbug-reports:   http://github.com/ekmett/void/issues\r\ncopyright:     Copyright (C) 2008-2015 Edward A. Kmett\r\nsynopsis:      A Haskell 98 logically uninhabited data type\r\ndescription:   A Haskell 98 logically uninhabited data type, used to indicate that a given term should not exist.\r\nbuild-type:    Simple\r\ntested-with:   GHC==9.12.2\r\n             , GHC==9.10.3\r\n             , GHC==9.8.4\r\n             , GHC==9.6.6\r\n             , GHC==9.4.8\r\n             , GHC==9.2.8\r\n             , GHC==9.0.2\r\n             , GHC==8.10.7\r\n             , GHC==8.8.4\r\n             , GHC==8.6.5\r\n             , GHC==8.4.4\r\n             , GHC==8.2.2\r\n             , GHC==8.0.2\r\n\r\nextra-source-files:\r\n  .ghci\r\n  .gitignore\r\n  .vim.custom\r\n  CHANGELOG.markdown\r\n  README.markdown\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/ekmett/void.git\r\n\r\nflag safe\r\n  manual: True\r\n  default: False\r\n\r\nlibrary\r\n  default-language: Haskell98\r\n  hs-source-dirs: src\r\n  exposed-modules:\r\n    Data.Void.Unsafe\r\n\r\n  -- void-0.7.4 dropped support for GHC < 8\r\n  build-depends: base >= 4.9 && < 10\r\n\r\n  ghc-options: -Wall\r\n\r\n  if flag(safe)\r\n    cpp-options: -DSAFE\r\n";
  }