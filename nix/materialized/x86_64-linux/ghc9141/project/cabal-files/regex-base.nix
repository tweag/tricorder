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
      specVersion = "1.24";
      identifier = { name = "regex-base"; version = "0.94.0.3"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2006, Christopher Kuklewicz";
      maintainer = "Andreas Abel";
      author = "Christopher Kuklewicz";
      homepage = "https://wiki.haskell.org/Regular_expressions";
      url = "";
      synopsis = "Common \"Text.Regex.*\" API for Regex matching";
      description = "This package does not provide the ability to do regular expression matching.\nInstead, it provides the type classes that constitute the abstract API\nthat is implemented by @regex-*@ backends such as:\n\n* <https://hackage.haskell.org/package/regex-posix regex-posix>\n\n* <https://hackage.haskell.org/package/regex-parsec regex-parsec>\n\n* <https://hackage.haskell.org/package/regex-dfa regex-dfa>\n\n* <https://hackage.haskell.org/package/regex-tdfa regex-tdfa>\n\n* <https://hackage.haskell.org/package/regex-pcre regex-pcre>\n\nSee also <https://wiki.haskell.org/Regular_expressions> for more information.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/regex-base-0.94.0.3.tar.gz";
      sha256 = "e8ca2dee598c790dd1c1c4359bdd1e495d9b881f5aa1f539c22f0dd5563747bf";
    });
  }) // {
    package-description-override = "cabal-version:          1.24\nname:                   regex-base\nversion:                0.94.0.3\n\nbuild-type:             Simple\nlicense:                BSD3\nlicense-file:           LICENSE\ncopyright:              Copyright (c) 2006, Christopher Kuklewicz\nauthor:                 Christopher Kuklewicz\nmaintainer:             Andreas Abel\nhomepage:               https://wiki.haskell.org/Regular_expressions\nbug-reports:            https://github.com/haskell-hvr/regex-base/issues\nsynopsis:               Common \"Text.Regex.*\" API for Regex matching\ncategory:               Text\ndescription:\n  This package does not provide the ability to do regular expression matching.\n  Instead, it provides the type classes that constitute the abstract API\n  that is implemented by @regex-*@ backends such as:\n  .\n  * <https://hackage.haskell.org/package/regex-posix regex-posix>\n  .\n  * <https://hackage.haskell.org/package/regex-parsec regex-parsec>\n  .\n  * <https://hackage.haskell.org/package/regex-dfa regex-dfa>\n  .\n  * <https://hackage.haskell.org/package/regex-tdfa regex-tdfa>\n  .\n  * <https://hackage.haskell.org/package/regex-pcre regex-pcre>\n  .\n  See also <https://wiki.haskell.org/Regular_expressions> for more information.\n\nextra-doc-files:\n  ChangeLog.md\n  README.md\n\ntested-with:\n  GHC == 9.12.1\n  GHC == 9.10.1\n  GHC == 9.8.4\n  GHC == 9.6.6\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-hvr/regex-base.git\n\nsource-repository this\n  type:     git\n  location: https://github.com/haskell-hvr/regex-base.git\n  tag:      v0.94.0.3\n\nlibrary\n  hs-source-dirs: src\n\n  exposed-modules:\n      Text.Regex.Base\n      Text.Regex.Base.RegexLike\n      Text.Regex.Base.Context\n      Text.Regex.Base.Impl\n\n  other-modules:\n      Paths_regex_base\n\n  default-language:\n      Haskell2010\n\n  default-extensions:\n      NoImplicitPrelude\n      Safe\n      MultiParamTypeClasses\n      FunctionalDependencies\n      TypeSynonymInstances\n      FlexibleInstances\n      FlexibleContexts\n\n  build-depends:\n        base        >= 4.9   && < 5\n      , containers  >= 0.5   && < 1\n      , bytestring  >= 0.10  && < 1\n      , array       >= 0.5   && < 1\n      , text        >= 1.2.3 && < 1.3 || >= 2.0 && < 3\n\n  ghc-options:\n      -Wall\n      -Wcompat\n";
  }