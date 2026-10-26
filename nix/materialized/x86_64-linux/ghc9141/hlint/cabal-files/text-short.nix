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
    flags = { asserts = false; };
    package = {
      specVersion = "1.18";
      identifier = { name = "text-short"; version = "0.1.6.1"; };
      license = "BSD-3-Clause";
      copyright = "";
      maintainer = "hvr@gnu.org";
      author = "Herbert Valerio Riedel";
      homepage = "";
      url = "";
      synopsis = "Memory-efficient representation of Unicode text strings";
      description = "This package provides the 'ShortText' type which is suitable for keeping many short strings in memory. This is similiar to how 'ShortByteString' relates to 'ByteString'.\n\nThe main difference between 'Text' and 'ShortText' is that 'ShortText' doesn't support zero-copy slicing (thereby saving 2 words), and, compared to text-1.*, that it uses UTF-8 instead of UTF-16 internally. Consequently, the memory footprint of a (boxed) 'ShortText' value is 4 words (2 words when unboxed) plus the length of the UTF-8 encoded payload.";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
          (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
          (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          (hsPkgs."ghc-prim" or (errorHandler.buildDepError "ghc-prim"))
          (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
          (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ];
        buildable = true;
      };
      tests = {
        "text-short-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-short" or (errorHandler.buildDepError "text-short"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/text-short-0.1.6.1.tar.gz";
      sha256 = "83669f402354274fbcdc75126443af733267b955e451f72c0c6d86ae8da87416";
    });
  }) // {
    package-description-override = "cabal-version:      1.18\nname:               text-short\nversion:            0.1.6.1\nsynopsis:           Memory-efficient representation of Unicode text strings\nlicense:            BSD3\nlicense-file:       LICENSE\nauthor:             Herbert Valerio Riedel\nmaintainer:         hvr@gnu.org\nbug-reports:        https://github.com/hvr/text-short/issues\ncategory:           Data\nbuild-type:         Simple\ndescription:\n  This package provides the 'ShortText' type which is suitable for keeping many short strings in memory. This is similiar to how 'ShortByteString' relates to 'ByteString'.\n  .\n  The main difference between 'Text' and 'ShortText' is that 'ShortText' doesn't support zero-copy slicing (thereby saving 2 words), and, compared to text-1.*, that it uses UTF-8 instead of UTF-16 internally. Consequently, the memory footprint of a (boxed) 'ShortText' value is 4 words (2 words when unboxed) plus the length of the UTF-8 encoded payload.\n\ntested-with:\n  GHC ==8.6.5\n   || ==8.8.3\n   || ==8.10.7\n   || ==9.0.2\n   || ==9.2.8\n   || ==9.4.8\n   || ==9.6.6\n   || ==9.8.4\n   || ==9.10.2\n   || ==9.12.2\n   || ==9.14.1\n\nextra-source-files: ChangeLog.md\n\nsource-repository head\n  type:     git\n  location: https://github.com/hvr/text-short.git\n\nflag asserts\n  description: Enable runtime-checks via @assert@\n  default:     False\n  manual:      True\n\nlibrary\n  exposed-modules:\n    Data.Text.Short\n    Data.Text.Short.Partial\n    Data.Text.Short.Unsafe\n\n  other-modules:    Data.Text.Short.Internal\n  build-depends:\n      base              >=4.12     && <4.23\n    , binary            >=0.8.6.0  && <0.9\n    , bytestring        >=0.10.8.2 && <0.13\n    , deepseq           >=1.4.4.0  && <1.6\n    , ghc-prim          >=0.5.3    && <0.14\n    , hashable          >=1.4.4.0  && <1.6\n    , template-haskell  >=2.14.0.0 && <2.25\n    , text              >=1.2.3.1  && <1.3  || >=2.0 && <2.2\n\n  other-modules:    PrimOps\n  hs-source-dirs:   src src-ghc804\n  default-language: Haskell2010\n  other-extensions:\n    CPP\n    GeneralizedNewtypeDeriving\n    MagicHash\n    TemplateHaskellQuotes\n    Trustworthy\n    UnliftedFFITypes\n    Unsafe\n\n  c-sources:        cbits/cbits.c\n\n  if flag(asserts)\n    ghc-options: -fno-ignore-asserts\n\n  else\n    cc-options: -DNDEBUG=1\n\n  ghc-options:      -Wall\n  cc-options:       -Wall\n\ntest-suite text-short-tests\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   src-test\n  main-is:          Tests.hs\n\n  -- bytestring dependency for cabal_macros.h\n  build-depends:\n      base\n    , binary\n    , bytestring\n    , text\n    , text-short\n\n  -- deps which don't inherit constraints from library stanza:\n  build-depends:\n      tasty             >=1.4    && <1.6\n    , tasty-hunit       >=0.10.0 && <0.11\n    , tasty-quickcheck  >=0.10   && <0.12\n\n  default-language: Haskell2010\n";
  }