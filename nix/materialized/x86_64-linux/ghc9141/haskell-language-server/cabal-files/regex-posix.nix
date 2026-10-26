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
    flags = { _regex-posix-clib = false; };
    package = {
      specVersion = "1.24";
      identifier = { name = "regex-posix"; version = "0.96.0.2"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2007-2010, Christopher Kuklewicz";
      maintainer = "Andreas Abel";
      author = "Christopher Kuklewicz";
      homepage = "";
      url = "";
      synopsis = "POSIX Backend for \"Text.Regex\" (regex-base)";
      description = "The POSIX regex backend for <//hackage.haskell.org/package/regex-base regex-base>.\n\nThe main appeal of this backend is that it's very lightweight due to its reliance on the ubiquitous <https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/regex.h.html POSIX.2 regex> facility that is provided by the standard C library on most POSIX platforms.\n\nSee also <https://wiki.haskell.org/Regular_expressions> for more information.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."regex-base" or (errorHandler.buildDepError "regex-base"))
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."array" or (errorHandler.buildDepError "array"))
        ] ++ pkgs.lib.optional (flags._regex-posix-clib || system.isWindows) (hsPkgs."regex-posix-clib" or (errorHandler.buildDepError "regex-posix-clib"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/regex-posix-0.96.0.2.tar.gz";
      sha256 = "7e570460c35c5deec54d1ba46305ddb4679c7d4aae84f631dd0c61daaeaa8150";
    });
  }) // {
    package-description-override = "cabal-version:          1.24\nname:                   regex-posix\nversion:                0.96.0.2\n\nbuild-type:             Simple\nlicense:                BSD3\nlicense-file:           LICENSE\ncopyright:              Copyright (c) 2007-2010, Christopher Kuklewicz\nauthor:                 Christopher Kuklewicz\nmaintainer:             Andreas Abel\nbug-reports:            https://github.com/haskell-hvr/regex-posix\nsynopsis:               POSIX Backend for \"Text.Regex\" (regex-base)\ncategory:               Text\ndescription:\n  The POSIX regex backend for <//hackage.haskell.org/package/regex-base regex-base>.\n  .\n  The main appeal of this backend is that it's very lightweight due to its reliance on the ubiquitous <https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/regex.h.html POSIX.2 regex> facility that is provided by the standard C library on most POSIX platforms.\n  .\n  See also <https://wiki.haskell.org/Regular_expressions> for more information.\n\nextra-doc-files:\n  README.md\n  ChangeLog.md\n\nextra-source-files:\n  cbits/myfree.h\n\ntested-with:\n  GHC == 9.12.1\n  GHC == 9.10.1\n  GHC == 9.8.4\n  GHC == 9.6.6\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell-hvr/regex-posix.git\n\nsource-repository this\n  type:     git\n  location: https://github.com/haskell-hvr/regex-base.git\n  tag:      v0.96.0.2\n\nflag _regex-posix-clib\n  manual: False\n  default: False\n  description: Use <//hackage.haskell.org/package/regex-posix-clib regex-posix-clib> package (used by default on Windows)\n\nlibrary\n  hs-source-dirs: src\n  exposed-modules:\n      Text.Regex.Posix\n      Text.Regex.Posix.Wrap\n      Text.Regex.Posix.String\n      Text.Regex.Posix.Sequence\n      Text.Regex.Posix.ByteString\n      Text.Regex.Posix.ByteString.Lazy\n\n  other-modules:\n      Paths_regex_posix\n\n  c-sources:        cbits/myfree.c\n  include-dirs:     cbits\n\n  if flag(_regex-posix-clib) || os(windows)\n    build-depends: regex-posix-clib == 2.7.*\n    -- Otherwise, use POSIX.2 regex implementation from @libc@.\n    -- However, Windows/msys2 doesn't provide a POSIX.2 regex impl in its @libc@.\n\n  default-language:\n      Haskell2010\n  default-extensions:\n      NoImplicitPrelude\n      MultiParamTypeClasses\n      FunctionalDependencies\n      ForeignFunctionInterface\n      GeneralizedNewtypeDeriving\n      FlexibleContexts\n      FlexibleInstances\n\n  build-depends:\n        regex-base == 0.94.*\n      , base       >= 4.9  && < 5\n      , containers >= 0.5  && < 1\n      , bytestring >= 0.10 && < 1\n      , array      >= 0.5  && < 1\n\n  ghc-options:\n      -Wall\n      -Wcompat\n      -Wno-orphans\n";
  }