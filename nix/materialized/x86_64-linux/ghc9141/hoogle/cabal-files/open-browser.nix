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
    flags = { example = false; };
    package = {
      specVersion = "1.12";
      identifier = { name = "open-browser"; version = "0.5.1.0"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "public@pilgrem.com";
      author = "rightfold";
      homepage = "https://github.com/mpilgrem/open-browser";
      url = "";
      synopsis = "Open a web browser from Haskell";
      description = "Open a web browser from Haskell. Windows, macOS, Linux and BSD are supported.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ (if system.isWindows
          then [ (hsPkgs."Win32" or (errorHandler.buildDepError "Win32")) ]
          else if system.isOsx
            then [
              (hsPkgs."process" or (errorHandler.buildDepError "process"))
            ]
            else pkgs.lib.optional (system.isLinux || system.isFreebsd || system.isOpenbsd || system.isNetbsd) (hsPkgs."process" or (errorHandler.buildDepError "process")));
        buildable = true;
      };
      exes = {
        "open-browser-example" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."open-browser" or (errorHandler.buildDepError "open-browser"))
          ];
          buildable = if !flags.example then false else true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/open-browser-0.5.1.0.tar.gz";
      sha256 = "1066e286615e39ef43f7e7437a4644775246e264c33b4d259b4858cff0985f0b";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\r\n\r\n-- This file has been generated from package.yaml by hpack version 0.39.6.\r\n--\r\n-- see: https://github.com/sol/hpack\r\n\r\nname:           open-browser\r\nversion:        0.5.1.0\r\nsynopsis:       Open a web browser from Haskell\r\ndescription:    Open a web browser from Haskell. Windows, macOS, Linux and BSD are supported.\r\ncategory:       Web\r\nhomepage:       https://github.com/mpilgrem/open-browser\r\nbug-reports:    https://github.com/mpilgrem/open-browser/issues\r\nauthor:         rightfold\r\nmaintainer:     public@pilgrem.com\r\nlicense:        BSD3\r\nlicense-file:   LICENSE\r\nbuild-type:     Simple\r\ntested-with:\r\n    GHC >= 8.4\r\nextra-source-files:\r\n    CHANGELOG.md\r\n    README.md\r\n\r\nsource-repository head\r\n  type: git\r\n  location: https://github.com/mpilgrem/open-browser\r\n\r\nflag example\r\n  description: Build the example application\r\n  manual: True\r\n  default: False\r\n\r\nlibrary\r\n  hs-source-dirs:\r\n      lib\r\n  exposed-modules:\r\n      Web.Browser\r\n  build-depends:\r\n      base ==4.*\r\n  default-language: Haskell2010\r\n  if os(windows)\r\n    other-modules:\r\n        Web.Browser.OS\r\n    hs-source-dirs:\r\n        lib/windows\r\n    build-depends:\r\n        Win32 <3\r\n  else\r\n    if os(darwin)\r\n      other-modules:\r\n          Web.Browser.OS\r\n      hs-source-dirs:\r\n          lib/unix-like/open\r\n      build-depends:\r\n          process >=1.2.0.0 && <2\r\n    else\r\n      if os(linux) || os(freebsd) || os(openbsd) || os(netbsd)\r\n        other-modules:\r\n            Web.Browser.OS\r\n        hs-source-dirs:\r\n            lib/unix-like/xdg-open\r\n        build-depends:\r\n            process >=1.2.0.0 && <2\r\n      else\r\n        other-modules:\r\n            Web.Browser.OS\r\n        hs-source-dirs:\r\n            lib/unsupported-os\r\n\r\nexecutable open-browser-example\r\n  main-is: Main.hs\r\n  hs-source-dirs:\r\n      example\r\n  build-depends:\r\n      base ==4.*\r\n    , open-browser\r\n  default-language: Haskell2010\r\n  if !flag(example)\r\n    buildable: False\r\n";
  }