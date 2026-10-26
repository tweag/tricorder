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
      identifier = { name = "open-browser"; version = "0.3.0.1"; };
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
      url = "http://hackage.haskell.org/package/open-browser-0.3.0.1.tar.gz";
      sha256 = "96c521ad0e43bd4ebd340be9067056a99e7281f4f15b41860b236cef769ccc3e";
    });
  }) // {
    package-description-override = "cabal-version: 1.12\r\n\n-- This file has been generated from package.yaml by hpack version 0.38.0.\n--\n-- see: https://github.com/sol/hpack\n\nname:           open-browser\nversion:        0.3.0.1\nsynopsis:       Open a web browser from Haskell\ndescription:    Open a web browser from Haskell. Windows, macOS, Linux and BSD are supported.\ncategory:       Web\nhomepage:       https://github.com/mpilgrem/open-browser\nbug-reports:    https://github.com/mpilgrem/open-browser/issues\nauthor:         rightfold\nmaintainer:     public@pilgrem.com\nlicense:        BSD3\nlicense-file:   LICENSE\nbuild-type:     Simple\ntested-with:\n    GHC >= 8.4\nextra-source-files:\n    CHANGELOG.md\n    README.md\n    stack.yaml\n    stack.yaml.lock\n\nsource-repository head\n  type: git\n  location: https://github.com/mpilgrem/open-browser\n\nflag example\n  description: Build the example application\n  manual: True\n  default: False\n\nlibrary\n  hs-source-dirs:\n      lib\n  exposed-modules:\n      Web.Browser\n  build-depends:\n      base ==4.*\n  default-language: Haskell2010\n  if os(windows)\n    other-modules:\n        Web.Browser.OS\n    hs-source-dirs:\n        lib/windows\n    build-depends:\n        Win32 <3\n  else\n    if os(darwin)\n      other-modules:\n          Utils\n          Web.Browser.OS\n      hs-source-dirs:\n          lib/unix-like/common\n          lib/unix-like/open\n      build-depends:\n          process >=1.4.3.0 && <2\n    else\n      if os(linux) || os(freebsd) || os(openbsd) || os(netbsd)\n        other-modules:\n            Utils\n            Web.Browser.OS\n        hs-source-dirs:\n            lib/unix-like/common\n            lib/unix-like/xdg-open\n        build-depends:\n            process >=1.4.3.0 && <2\n      else\n        other-modules:\n            Web.Browser.OS\n        hs-source-dirs:\n            lib/unsupported-os\n\nexecutable open-browser-example\n  main-is: Main.hs\n  hs-source-dirs:\n      example\n  build-depends:\n      base ==4.*\n    , open-browser\n  default-language: Haskell2010\n  if !flag(example)\n    buildable: False\n";
  }