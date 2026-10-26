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
    flags = { dev = false; };
    package = {
      specVersion = "2.4";
      identifier = { name = "parser-combinators"; version = "1.3.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "Mark Karpov <markkarpov92@gmail.com>";
      author = "Mark Karpov <markkarpov92@gmail.com>\nAlex Washburn <github@recursion.ninja>";
      homepage = "https://github.com/mrkkrp/parser-combinators";
      url = "";
      synopsis = "Lightweight package providing commonly useful parser combinators";
      description = "Lightweight package providing commonly useful parser combinators.";
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
      url = "http://hackage.haskell.org/package/parser-combinators-1.3.1.tar.gz";
      sha256 = "9c506cc38f9df0fc23a942e739ed1f0799fc6c54515d770de044168ecff740bf";
    });
  }) // {
    package-description-override = "cabal-version:   2.4\nname:            parser-combinators\nversion:         1.3.1\nlicense:         BSD-3-Clause\nlicense-file:    LICENSE.md\nmaintainer:      Mark Karpov <markkarpov92@gmail.com>\nauthor:\n    Mark Karpov <markkarpov92@gmail.com>\n    Alex Washburn <github@recursion.ninja>\n\ntested-with:     ghc ==9.8.4 ghc ==9.10.3 ghc ==9.12.1\nhomepage:        https://github.com/mrkkrp/parser-combinators\nbug-reports:     https://github.com/mrkkrp/parser-combinators/issues\nsynopsis:\n    Lightweight package providing commonly useful parser combinators\n\ndescription:\n    Lightweight package providing commonly useful parser combinators.\n\ncategory:        Parsing\nbuild-type:      Simple\nextra-doc-files:\n    CHANGELOG.md\n    README.md\n\nsource-repository head\n    type:     git\n    location: https://github.com/mrkkrp/parser-combinators.git\n\nflag dev\n    description: Turn on development settings.\n    default:     False\n    manual:      True\n\nlibrary\n    exposed-modules:\n        Control.Applicative.Combinators\n        Control.Applicative.Combinators.NonEmpty\n        Control.Applicative.Permutations\n        Control.Monad.Combinators\n        Control.Monad.Combinators.Expr\n        Control.Monad.Combinators.NonEmpty\n        Control.Monad.Permutations\n\n    default-language: Haskell2010\n    build-depends:    base >=4.15 && <5\n\n    if flag(dev)\n        ghc-options:\n            -Wall -Werror -Wredundant-constraints -Wpartial-fields\n            -Wunused-packages\n\n    else\n        ghc-options: -O2 -Wall\n";
  }