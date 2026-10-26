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
    flags = { tagged = true; };
    package = {
      specVersion = "2.2";
      identifier = { name = "boring"; version = "0.2.2.1"; };
      license = "BSD-3-Clause";
      copyright = "(c) 2017-2021 Oleg Grenrus";
      maintainer = "Oleg.Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "https://github.com/phadej/boring";
      url = "";
      synopsis = "Boring and Absurd types";
      description = "* @Boring@ types are isomorphic to @()@.\n\n* @Absurd@ types are isomorphic to @Void@.\n\nSee [What does () mean in Haskell -answer by Conor McBride](https://stackoverflow.com/questions/33112439/what-does-mean-in-haskell/33115522#33115522)";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = ([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "7.6") (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))) ++ pkgs.lib.optional (flags.tagged) (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/boring-0.2.2.1.tar.gz";
      sha256 = "a96edc1d8a782ca888068a9bc971452dc7fbed03b90e5e0d71bd733c5684e62d";
    });
  }) // {
    package-description-override = "cabal-version:      2.2\nname:               boring\nversion:            0.2.2.1\nsynopsis:           Boring and Absurd types\ndescription:\n  * @Boring@ types are isomorphic to @()@.\n  .\n  * @Absurd@ types are isomorphic to @Void@.\n  .\n  See [What does () mean in Haskell -answer by Conor McBride](https://stackoverflow.com/questions/33112439/what-does-mean-in-haskell/33115522#33115522)\n\nhomepage:           https://github.com/phadej/boring\nbug-reports:        https://github.com/phadej/boring/issues\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:         Oleg.Grenrus <oleg.grenrus@iki.fi>\ncopyright:          (c) 2017-2021 Oleg Grenrus\ncategory:           Data\nbuild-type:         Simple\nextra-source-files: ChangeLog.md\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.4\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.3\n   || ==9.12.2\n   || ==9.14.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/boring.git\n  subdir:   boring\n\nflag tagged\n  description:\n    You can disable the use of the `tagged` package using `-f-tagged`.\n    .\n    Disabling this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\n\n  default:     True\n  manual:      True\n\nlibrary\n  exposed-modules:  Data.Boring\n  build-depends:\n      base          >=4.12.0.0 && <4.23\n\n  if impl(ghc <7.6)\n    build-depends: ghc-prim\n\n  if flag(tagged)\n    build-depends: tagged >=0.8.6 && <0.9\n\n  other-extensions:\n    CPP\n    DefaultSignatures\n    FlexibleContexts\n    GADTs\n    Trustworthy\n    TypeOperators\n\n  hs-source-dirs:   src\n  default-language: Haskell2010\n";
  }