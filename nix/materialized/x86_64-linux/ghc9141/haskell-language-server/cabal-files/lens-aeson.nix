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
      specVersion = "1.10";
      identifier = { name = "lens-aeson"; version = "1.2.3"; };
      license = "MIT";
      copyright = "Copyright (C) 2012 Paul Wilson\nCopyright (C) 2013 Edward A. Kmett";
      maintainer = "Edward A. Kmett <ekmett@gmail.com>";
      author = "Edward A. Kmett";
      homepage = "http://github.com/lens/lens-aeson/";
      url = "";
      synopsis = "Law-abiding lenses for aeson";
      description = "Law-abiding lenses for aeson.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
          (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          (hsPkgs."scientific" or (errorHandler.buildDepError "scientific"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/lens-aeson-1.2.3.tar.gz";
      sha256 = "7bbc6affe248c84dfda13576636ecb52e575ee0e796d8c29a76a28c3ad424c01";
    });
  }) // {
    package-description-override = "name:          lens-aeson\r\ncategory:      Data, JSON, Lenses\r\nversion:       1.2.3\r\nx-revision: 3\r\nlicense:       MIT\r\ncabal-version: >= 1.10\r\nlicense-file:  LICENSE\r\nauthor:        Edward A. Kmett\r\nmaintainer:    Edward A. Kmett <ekmett@gmail.com>\r\nstability:     provisional\r\nhomepage:      http://github.com/lens/lens-aeson/\r\nbug-reports:   http://github.com/lens/lens-aeson/issues\r\ncopyright:\r\n  Copyright (C) 2012 Paul Wilson\r\n  Copyright (C) 2013 Edward A. Kmett\r\nbuild-type:    Simple\r\ntested-with:   GHC == 8.0.2\r\n             , GHC == 8.2.2\r\n             , GHC == 8.4.4\r\n             , GHC == 8.6.5\r\n             , GHC == 8.8.4\r\n             , GHC == 8.10.7\r\n             , GHC == 9.0.2\r\n             , GHC == 9.2.7\r\n             , GHC == 9.4.5\r\n             , GHC == 9.6.2\r\nsynopsis:      Law-abiding lenses for aeson\r\ndescription:   Law-abiding lenses for aeson.\r\n\r\nextra-source-files:\r\n  .gitignore\r\n  .hlint.yaml\r\n  .vim.custom\r\n  AUTHORS.markdown\r\n  README.markdown\r\n  CHANGELOG.markdown\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/lens/lens-aeson\r\n\r\nlibrary\r\n  build-depends:\r\n    base                 >= 4.9       && < 5,\r\n    lens                 >= 5.0       && < 6,\r\n    text                 >= 0.11.1.10 && < 2.2,\r\n    text-short           >= 0.1.4     && < 0.2,\r\n    vector               >= 0.9       && < 0.14,\r\n    unordered-containers >= 0.2.3     && < 0.3,\r\n    bytestring           >= 0.9       && < 0.13,\r\n    aeson                >= 2.0.2     && < 2.4,\r\n    scientific           >= 0.3.2     && < 0.4\r\n\r\n  exposed-modules:\r\n    Data.Aeson.Lens\r\n\r\n  ghc-options: -Wall -Wtabs -O2\r\n  hs-source-dirs: src\r\n  default-language: Haskell2010\r\n";
  }