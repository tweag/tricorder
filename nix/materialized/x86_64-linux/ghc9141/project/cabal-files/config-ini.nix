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
    flags = { enable-doctests = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "config-ini"; version = "0.2.7.0"; };
      license = "BSD-3-Clause";
      copyright = "©2018 Getty Ritter";
      maintainer = "Getty Ritter <config-ini@infinitenegativeutility.com>";
      author = "Getty Ritter <config-ini@infinitenegativeutility.com>";
      homepage = "https://github.com/aisamanra/config-ini";
      url = "";
      synopsis = "A library for simple INI-based configuration files.";
      description = "The @config-ini@ library is a set of small monadic languages\nfor writing simple configuration languages with convenient,\nhuman-readable error messages.\n\n> parseConfig :: IniParser (Text, Int, Bool)\n> parseConfig = section \"NETWORK\" $ do\n>   user <- field        \"user\"\n>   port <- fieldOf      \"port\" number\n>   enc  <- fieldFlagDef \"encryption\" True\n>   return (user, port, enc)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
          (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
        ];
        buildable = true;
      };
      tests = {
        "test-ini-compat" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ini" or (errorHandler.buildDepError "ini"))
            (hsPkgs."config-ini" or (errorHandler.buildDepError "config-ini"))
            (hsPkgs."hedgehog" or (errorHandler.buildDepError "hedgehog"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
        "test-prewritten" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."config-ini" or (errorHandler.buildDepError "config-ini"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          ];
          buildable = true;
        };
        "test-doctest" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."doctest" or (errorHandler.buildDepError "doctest"))
            (hsPkgs."microlens" or (errorHandler.buildDepError "microlens"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if compiler.isGhc && compiler.version.lt "7.10" || !flags.enable-doctests
            then false
            else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/config-ini-0.2.7.0.tar.gz";
      sha256 = "3a171c45baa6ed066dd62a4bfd7fb60d99030e9e320c2b73cfd0980252596901";
    });
  }) // {
    package-description-override = "name:             config-ini\r\nversion:          0.2.7.0\r\nx-revision:       2\r\nsynopsis:         A library for simple INI-based configuration files.\r\nhomepage:         https://github.com/aisamanra/config-ini\r\nbug-reports:      https://github.com/aisamanra/config-ini/issues\r\ndescription:      The @config-ini@ library is a set of small monadic languages\r\n                  for writing simple configuration languages with convenient,\r\n                  human-readable error messages.\r\n                  .\r\n                  > parseConfig :: IniParser (Text, Int, Bool)\r\n                  > parseConfig = section \"NETWORK\" $ do\r\n                  >   user <- field        \"user\"\r\n                  >   port <- fieldOf      \"port\" number\r\n                  >   enc  <- fieldFlagDef \"encryption\" True\r\n                  >   return (user, port, enc)\r\n\r\nlicense:          BSD3\r\nlicense-file:     LICENSE\r\nauthor:           Getty Ritter <config-ini@infinitenegativeutility.com>\r\nmaintainer:       Getty Ritter <config-ini@infinitenegativeutility.com>\r\ncopyright:        ©2018 Getty Ritter\r\ncategory:         Configuration\r\nbuild-type:       Simple\r\ncabal-version:    1.18\r\ntested-with:      GHC == 8.8.4, GHC == 8.10.7, GHC == 9.0.2, GHC == 9.2.4, GHC == 9.4.2, GHC == 9.6.2, GHC == 9.8.1\r\nextra-doc-files:\r\n  README.md,\r\n  CHANGELOG.md\r\nextra-source-files:\r\n  test/prewritten/cases/*.hs,\r\n  test/prewritten/cases/*.ini\r\n\r\nsource-repository head\r\n  type: git\r\n  location: git://github.com/aisamanra/config-ini.git\r\n\r\nflag enable-doctests\r\n  description: Build doctest modules as well (can be finicky)\r\n  default:     False\r\n\r\nlibrary\r\n  hs-source-dirs:      src\r\n  exposed-modules:     Data.Ini.Config\r\n                     , Data.Ini.Config.Bidir\r\n                     , Data.Ini.Config.Raw\r\n  ghc-options:         -Wall\r\n  if impl(ghc > 8.0)\r\n    ghc-options:       -fno-warn-redundant-constraints\r\n  build-depends:       base                  >=4.8   && <5\r\n                     , containers            >=0.5   && <1\r\n                     , text                  >=1.2.2 && <3\r\n                     , unordered-containers  >=0.2.7 && <0.5\r\n                     , transformers          >=0.4.1 && <0.7\r\n                     , megaparsec            >=7     && <10\r\n  default-language:    Haskell2010\r\n\r\ntest-suite test-ini-compat\r\n  type:             exitcode-stdio-1.0\r\n  ghc-options:      -Wall -threaded\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   test/ini-compat\r\n  main-is:          Main.hs\r\n  build-depends:    base\r\n                  , ini >=0.4\r\n                  , config-ini\r\n                  , hedgehog\r\n                  , containers\r\n                  , unordered-containers\r\n                  , text\r\n\r\ntest-suite test-prewritten\r\n  type:             exitcode-stdio-1.0\r\n  ghc-options:      -Wall\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   test/prewritten\r\n  main-is:          Main.hs\r\n  build-depends:    base\r\n                  , config-ini\r\n                  , containers\r\n                  , unordered-containers\r\n                  , text\r\n                  , directory\r\n\r\ntest-suite test-doctest\r\n  if impl(ghc < 7.10) || !flag(enable-doctests)\r\n    buildable:      False\r\n  type:             exitcode-stdio-1.0\r\n  ghc-options:      -Wall\r\n  default-language: Haskell2010\r\n  hs-source-dirs:   test/doctest\r\n  main-is:          Main.hs\r\n  build-depends:    base\r\n                  , doctest\r\n                  , microlens\r\n                  , text\r\n";
  }