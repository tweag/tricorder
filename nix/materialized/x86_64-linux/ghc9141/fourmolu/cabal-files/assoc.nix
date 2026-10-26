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
    flags = { tagged = false; };
    package = {
      specVersion = "3.0";
      identifier = { name = "assoc"; version = "1.1.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      author = "Oleg Grenrus <oleg.grenrus@iki.fi>";
      homepage = "";
      url = "";
      synopsis = "swap and assoc: Symmetric and Semigroupy Bifunctors";
      description = "Provides generalisations of\n@swap :: (a,b) -> (b,a)@ and\n@assoc :: ((a,b),c) -> (a,(b,c))@\nto\n@Bifunctor@s supporting similar operations (e.g. @Either@, @These@).";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
        ] ++ pkgs.lib.optional (flags.tagged) (hsPkgs."tagged" or (errorHandler.buildDepError "tagged"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/assoc-1.1.1.tar.gz";
      sha256 = "231149b7fef09f5dd95af51228615e3b296dbd0faadeca053e0644a4b13b0ff6";
    });
  }) // {
    package-description-override = "cabal-version:      3.0\nname:               assoc\nversion:            1.1.1\nx-revision:         2\nlicense:            BSD-3-Clause\nlicense-file:       LICENSE\nsynopsis:           swap and assoc: Symmetric and Semigroupy Bifunctors\ncategory:           Data\ndescription:\n  Provides generalisations of\n  @swap :: (a,b) -> (b,a)@ and\n  @assoc :: ((a,b),c) -> (a,(b,c))@\n  to\n  @Bifunctor@s supporting similar operations (e.g. @Either@, @These@).\n\nauthor:             Oleg Grenrus <oleg.grenrus@iki.fi>\nmaintainer:         Oleg Grenrus <oleg.grenrus@iki.fi>\nbuild-type:         Simple\nextra-source-files: CHANGELOG.md\ntested-with:\n    GHC ==8.6.5\n     || ==8.8.4\n     || ==8.10.7\n     || ==9.0.2\n     || ==9.2.8\n     || ==9.4.8\n     || ==9.6.6\n     || ==9.8.4\n     || ==9.10.2\n     || ==9.12.2\n     || ==9.14.1\n\nsource-repository head\n  type:     git\n  location: https://github.com/phadej/assoc.git\n\nflag tagged\n  default:     False\n  manual:      True\n  description:\n    You can disable the use of the `tagged` package using `-f-tagged`.\n    .\n    Disabing this is an unsupported configuration, but it may be useful for accelerating builds in sandboxes for expert users.\n\nlibrary\n  default-language: Haskell2010\n  hs-source-dirs:   src\n  build-depends:    base >=4.12 && <4.23\n\n  if flag(tagged)\n    build-depends: tagged >=0.8.8 && <0.9\n\n  exposed-modules:\n    Data.Bifunctor.Assoc\n    Data.Bifunctor.Swap\n\n  other-extensions: TypeFamilies\n";
  }