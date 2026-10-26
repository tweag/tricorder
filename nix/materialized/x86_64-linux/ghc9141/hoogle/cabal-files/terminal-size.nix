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
      identifier = { name = "terminal-size"; version = "0.3.4"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "matvey.aksenov@gmail.com";
      author = "Andreas Hammar, Matvey Aksenov";
      homepage = "";
      url = "";
      synopsis = "Get terminal window height and width";
      description = "Get terminal window height and width without ncurses dependency.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && (compiler.version.ge "7.2" && compiler.version.lt "7.6")) (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))) ++ pkgs.lib.optionals (system.isWindows) [
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."Win32" or (errorHandler.buildDepError "Win32"))
        ];
        build-tools = [
          (hsPkgs.pkgsBuildBuild.hsc2hs.components.exes.hsc2hs or (pkgs.pkgsBuildBuild.hsc2hs or (errorHandler.buildToolDepError "hsc2hs:hsc2hs")))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/terminal-size-0.3.4.tar.gz";
      sha256 = "b0f070d6926cdaacf3a412c5518e5c23afca1e0ed00808a5328c96e468b67f49";
    });
  }) // {
    package-description-override = "name:                terminal-size\r\nversion:             0.3.4\r\nx-revision: 1\r\nsynopsis:            Get terminal window height and width\r\ndescription:\r\n  Get terminal window height and width without ncurses dependency.\r\nlicense:             BSD3\r\nlicense-file:        LICENSE\r\nauthor:              Andreas Hammar, Matvey Aksenov\r\nmaintainer:          matvey.aksenov@gmail.com\r\ncategory:            System\r\nbuild-type:          Simple\r\ncabal-version:       >= 1.10\r\nextra-source-files:\r\n  README.markdown\r\n  CHANGELOG.markdown\r\n\r\nsource-repository head\r\n  type:     git\r\n  location: https://github.com/biegunka/terminal-size\r\n\r\nsource-repository this\r\n  type:     git\r\n  location: https://github.com/biegunka/terminal-size\r\n  tag:      0.3.4\r\n\r\nlibrary\r\n  default-language:\r\n    Haskell2010\r\n\r\n  build-depends:\r\n    base >= 4 && < 5\r\n  if impl(ghc >= 7.2 && < 7.6)\r\n     build-depends:\r\n       ghc-prim\r\n  if os(windows)\r\n     build-depends:\r\n       process,\r\n       Win32 >= 2.13.2.0 && < 2.15\r\n\r\n  build-tools:\r\n    hsc2hs\r\n  hs-source-dirs:\r\n    src\r\n  exposed-modules:\r\n    System.Console.Terminal.Size\r\n\r\n  other-modules:\r\n    System.Console.Terminal.Common\r\n  if os(Windows)\r\n    other-modules:\r\n      System.Console.Terminal.Windows\r\n  else\r\n    other-modules:\r\n      System.Console.Terminal.Posix\r\n\r\n  ghc-options:\r\n    -Wall\r\n    -fno-warn-unused-do-bind\r\n";
  }