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
      specVersion = "3.0";
      identifier = { name = "choice"; version = "0.2.4.2"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "m@boespfl.ug";
      author = "Mathieu Boespflug";
      homepage = "https://github.com/mboes/choice#readme";
      url = "";
      synopsis = "A solution to boolean blindness.";
      description = "Please see README.md.";
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
      url = "http://hackage.haskell.org/package/choice-0.2.4.2.tar.gz";
      sha256 = "8cc11336c4b8003062bd23085ec90d17597db70d20b4221c0bdedc28def43e6d";
    });
  }) // {
    package-description-override = "cabal-version: 3.0\nname: choice\nversion: 0.2.4.2\nsynopsis: A solution to boolean blindness.\ndescription: Please see README.md.\nhomepage: https://github.com/mboes/choice#readme\nlicense: BSD-3-Clause\nauthor: Mathieu Boespflug\nmaintainer: m@boespfl.ug\ncategory: Data\nbuild-type: Simple\nextra-source-files: README.md\n\nlibrary\n  hs-source-dirs: src\n  exposed-modules: Data.Choice\n  build-depends: base >= 4.7 && < 5\n  default-language: Haskell2010\n\nsource-repository head\n  type: git\n  location: https://github.com/mboes/choice\n";
  }