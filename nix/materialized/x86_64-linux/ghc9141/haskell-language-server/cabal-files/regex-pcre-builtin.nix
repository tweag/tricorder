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
      identifier = { name = "regex-pcre-builtin"; version = "0.95.2.3.8.44"; };
      license = "BSD-3-Clause";
      copyright = "Copyright (c) 2006, Christopher Kuklewicz";
      maintainer = "audreyt@audreyt.org";
      author = "Audrey Tang";
      homepage = "";
      url = "";
      synopsis = "PCRE Backend for \"Text.Regex\" (regex-base)";
      description = "This package provides a <http://pcre.org/ PCRE> backend for the <//hackage.haskell.org/package/regex-base regex-base> API.\n\nSee also <https://wiki.haskell.org/Regular_expressions> for more information.\n\nIncludes bundled code from www.pcre.org";
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
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ] ++ pkgs.lib.optional (!(compiler.isGhc && compiler.version.ge "8")) (hsPkgs."fail" or (errorHandler.buildDepError "fail"));
        buildable = true;
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/regex-pcre-builtin-0.95.2.3.8.44.tar.gz";
      sha256 = "cacea6a45faf93df8afbf50ecb09f87acabfed0477cba4746205649eb52ec55e";
    });
  }) // {
    package-description-override = "Name:                   regex-pcre-builtin\nVersion:                0.95.2.3.8.44\nx-revision:             7\nCabal-Version:          >=1.10\nstability:              Seems to work, passes a few tests\nbuild-type:             Simple\nlicense:                BSD3\nlicense-file:           LICENSE\ncopyright:              Copyright (c) 2006, Christopher Kuklewicz\nauthor:                 Audrey Tang\nmaintainer:             audreyt@audreyt.org\nbug-reports:            https://github.com/audreyt/regex-pcre-builtin/issues\ncategory:               Text\n\nsynopsis:    PCRE Backend for \"Text.Regex\" (regex-base)\ndescription:\n  This package provides a <http://pcre.org/ PCRE> backend for the <//hackage.haskell.org/package/regex-base regex-base> API.\n  .\n  See also <https://wiki.haskell.org/Regular_expressions> for more information.\n  .\n  Includes bundled code from www.pcre.org\n\nextra-source-files:\n  ChangeLog.md\n  pcre/config.h pcre/pcre.h pcre/pcre_byte_order.c pcre/pcre_compile.c pcre/pcre_config.c pcre/pcre_chartables.c pcre/pcre_dfa_exec.c pcre/pcre_exec.c pcre/pcre_fullinfo.c pcre/pcre_get.c pcre/pcre_globals.c pcre/pcre_internal.h pcre/pcre_jit_compile.c pcre/pcre_maketables.c pcre/pcre_newline.c pcre/pcre_ord2utf8.c pcre/pcre_printint.c pcre/pcre_refcount.c pcre/pcre_scanner.h pcre/pcre_string_utils.c pcre/pcre_study.c pcre/pcre_tables.c pcre/pcre_ucd.c pcre/pcre_valid_utf8.c pcre/pcre_version.c pcre/pcre_xclass.c pcre/pcrecpp.h pcre/pcrecpp_internal.h pcre/pcreposix.h pcre/ucp.h\n\ntested-with:\n  GHC == 9.14.1\n  GHC == 9.12.2\n  GHC == 9.10.3\n  GHC == 9.8.4\n  GHC == 9.6.7\n  GHC == 9.4.8\n  GHC == 9.2.8\n  GHC == 9.0.2\n  GHC == 8.10.7\n  GHC == 8.8.4\n  GHC == 8.6.5\n  GHC == 8.4.4\n  GHC == 8.2.2\n  GHC == 8.0.2\n\nsource-repository head\n  type:     git\n  location: https://github.com/audreyt/regex-pcre-builtin\n\nlibrary\n  hs-source-dirs: src\n  exposed-modules:\n      Text.Regex.PCRE\n      Text.Regex.PCRE.Wrap\n      Text.Regex.PCRE.String\n      Text.Regex.PCRE.Sequence\n      Text.Regex.PCRE.ByteString\n      Text.Regex.PCRE.ByteString.Lazy\n      Text.Regex.PCRE.Text\n      Text.Regex.PCRE.Text.Lazy\n\n  other-modules:\n      Paths_regex_pcre_builtin\n\n  default-language: Haskell2010\n  default-extensions:\n      MultiParamTypeClasses\n      FunctionalDependencies\n      ForeignFunctionInterface\n      ScopedTypeVariables\n      GeneralizedNewtypeDeriving\n      FlexibleContexts\n      TypeSynonymInstances\n      FlexibleInstances\n\n  build-depends: regex-base == 0.94.*\n               , base       >= 4.3 && < 5\n               , containers >= 0.4 && < 0.9\n               , bytestring >= 0.9 && < 0.13\n               , array      >= 0.3 && < 0.6\n               , text       >= 1.2.3 && < 2.2\n\n  if !impl(ghc >= 8)\n      build-depends: fail == 4.9.*\n\n  ghc-options: -O2\n               -Wall -fno-warn-unused-imports\n  cc-options:  -DHAVE_CONFIG_H\n  include-dirs: pcre\n  includes: pcre.h config.h\n  c-sources:\n      pcre/pcre_byte_order.c pcre/pcre_compile.c pcre/pcre_config.c pcre/pcre_chartables.c pcre/pcre_dfa_exec.c pcre/pcre_exec.c pcre/pcre_fullinfo.c pcre/pcre_get.c pcre/pcre_globals.c pcre/pcre_jit_compile.c pcre/pcre_maketables.c pcre/pcre_newline.c pcre/pcre_ord2utf8.c pcre/pcre_refcount.c pcre/pcre_string_utils.c pcre/pcre_study.c pcre/pcre_tables.c pcre/pcre_ucd.c pcre/pcre_valid_utf8.c pcre/pcre_version.c pcre/pcre_xclass.c\n";
  }