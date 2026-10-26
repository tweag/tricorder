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
    flags = {
      pedantic = false;
      ignore-plugins-ghc-bounds = false;
      dynamic = true;
      cabalfmt = true;
      isolatecabalfmttests = false;
      cabalgild = true;
      isolatecabalgildtests = false;
      cabal = true;
      class = true;
      callhierarchy = true;
      eval = true;
      importlens = true;
      casesplit = true;
      rename = true;
      ghc-lib = true;
      hlint = true;
      stan = true;
      signaturehelp = true;
      pragmas = true;
      splice = true;
      alternatenumberformat = true;
      qualifyimportednames = true;
      coderange = true;
      changetypesignature = true;
      gadt = true;
      explicitfixity = true;
      explicitfields = true;
      overloadedrecorddot = true;
      fourmolu = true;
      ormolu = true;
      stylishhaskell = true;
      refactor = true;
      semantictokens = true;
      notes = true;
      export = true;
      test-exe = true;
      ghcide-bench = true;
      plugin-tutorial = true;
    };
    package = {
      specVersion = "3.4";
      identifier = { name = "haskell-language-server"; version = "2.15.0.0"; };
      license = "Apache-2.0";
      copyright = "The Haskell IDE Team";
      maintainer = "alan.zimm@gmail.com";
      author = "The Haskell IDE Team";
      homepage = "https://github.com/haskell/haskell-language-server#readme";
      url = "";
      synopsis = "LSP server for GHC";
      description = "Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>";
      buildType = "Simple";
    };
    components = {
      "library" = {
        depends = (((((((((((((((((((((((((((([
          (hsPkgs."base" or (errorHandler.buildDepError "base"))
          (hsPkgs."aeson-pretty" or (errorHandler.buildDepError "aeson-pretty"))
          (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
          (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
          (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
          (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
          (hsPkgs."githash" or (errorHandler.buildDepError "githash"))
          (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
          (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
          (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
          (hsPkgs."optparse-simple" or (errorHandler.buildDepError "optparse-simple"))
          (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
          (hsPkgs."process" or (errorHandler.buildDepError "process"))
          (hsPkgs."text" or (errorHandler.buildDepError "text"))
        ] ++ pkgs.lib.optional (flags.cabal) (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-plugin"))) ++ pkgs.lib.optional (flags.callhierarchy) (hsPkgs."haskell-language-server".components.sublibs.hls-call-hierarchy-plugin or (errorHandler.buildDepError "haskell-language-server:hls-call-hierarchy-plugin"))) ++ pkgs.lib.optional (flags.cabalfmt && flags.cabal) (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-fmt-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-fmt-plugin"))) ++ pkgs.lib.optional (flags.cabalgild && flags.cabal) (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-gild-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-gild-plugin"))) ++ pkgs.lib.optional (flags.changetypesignature) (hsPkgs."haskell-language-server".components.sublibs.hls-change-type-signature-plugin or (errorHandler.buildDepError "haskell-language-server:hls-change-type-signature-plugin"))) ++ pkgs.lib.optional (flags.class) (hsPkgs."haskell-language-server".components.sublibs.hls-class-plugin or (errorHandler.buildDepError "haskell-language-server:hls-class-plugin"))) ++ pkgs.lib.optional (flags.eval) (hsPkgs."haskell-language-server".components.sublibs.hls-eval-plugin or (errorHandler.buildDepError "haskell-language-server:hls-eval-plugin"))) ++ pkgs.lib.optional (flags.importlens) (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-imports-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-imports-plugin"))) ++ pkgs.lib.optional (flags.casesplit && !(compiler.isGhc && compiler.version.lt "9.14")) (hsPkgs."haskell-language-server".components.sublibs.hls-case-split-plugin or (errorHandler.buildDepError "haskell-language-server:hls-case-split-plugin"))) ++ pkgs.lib.optional (flags.rename) (hsPkgs."haskell-language-server".components.sublibs.hls-rename-plugin or (errorHandler.buildDepError "haskell-language-server:hls-rename-plugin"))) ++ pkgs.lib.optional (flags.hlint && !(compiler.isGhc && (compiler.version.ge "9.10" && compiler.version.lt "9.11")) && !(compiler.isGhc && compiler.version.ge "9.14")) (hsPkgs."haskell-language-server".components.sublibs.hls-hlint-plugin or (errorHandler.buildDepError "haskell-language-server:hls-hlint-plugin"))) ++ pkgs.lib.optional (flags.stan && (compiler.isGhc && compiler.version.lt "9.11" || flags.ignore-plugins-ghc-bounds)) (hsPkgs."haskell-language-server".components.sublibs.hls-stan-plugin or (errorHandler.buildDepError "haskell-language-server:hls-stan-plugin"))) ++ pkgs.lib.optional (flags.signaturehelp) (hsPkgs."haskell-language-server".components.sublibs.hls-signature-help-plugin or (errorHandler.buildDepError "haskell-language-server:hls-signature-help-plugin"))) ++ pkgs.lib.optional (flags.pragmas) (hsPkgs."haskell-language-server".components.sublibs.hls-pragmas-plugin or (errorHandler.buildDepError "haskell-language-server:hls-pragmas-plugin"))) ++ pkgs.lib.optional (flags.splice) (hsPkgs."haskell-language-server".components.sublibs.hls-splice-plugin or (errorHandler.buildDepError "haskell-language-server:hls-splice-plugin"))) ++ pkgs.lib.optional (flags.alternatenumberformat) (hsPkgs."haskell-language-server".components.sublibs.hls-alternate-number-format-plugin or (errorHandler.buildDepError "haskell-language-server:hls-alternate-number-format-plugin"))) ++ pkgs.lib.optional (flags.qualifyimportednames) (hsPkgs."haskell-language-server".components.sublibs.hls-qualify-imported-names-plugin or (errorHandler.buildDepError "haskell-language-server:hls-qualify-imported-names-plugin"))) ++ pkgs.lib.optional (flags.coderange) (hsPkgs."haskell-language-server".components.sublibs.hls-code-range-plugin or (errorHandler.buildDepError "haskell-language-server:hls-code-range-plugin"))) ++ pkgs.lib.optional (flags.gadt) (hsPkgs."haskell-language-server".components.sublibs.hls-gadt-plugin or (errorHandler.buildDepError "haskell-language-server:hls-gadt-plugin"))) ++ pkgs.lib.optional (flags.explicitfixity) (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-fixity-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-fixity-plugin"))) ++ pkgs.lib.optional (flags.explicitfields) (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-record-fields-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-record-fields-plugin"))) ++ pkgs.lib.optional (flags.fourmolu) (hsPkgs."haskell-language-server".components.sublibs.hls-fourmolu-plugin or (errorHandler.buildDepError "haskell-language-server:hls-fourmolu-plugin"))) ++ pkgs.lib.optional (flags.ormolu) (hsPkgs."haskell-language-server".components.sublibs.hls-ormolu-plugin or (errorHandler.buildDepError "haskell-language-server:hls-ormolu-plugin"))) ++ pkgs.lib.optional (flags.stylishhaskell && !(compiler.isGhc && compiler.version.ge "9.14")) (hsPkgs."haskell-language-server".components.sublibs.hls-stylish-haskell-plugin or (errorHandler.buildDepError "haskell-language-server:hls-stylish-haskell-plugin"))) ++ pkgs.lib.optional (flags.refactor) (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))) ++ pkgs.lib.optional (flags.overloadedrecorddot) (hsPkgs."haskell-language-server".components.sublibs.hls-overloaded-record-dot-plugin or (errorHandler.buildDepError "haskell-language-server:hls-overloaded-record-dot-plugin"))) ++ pkgs.lib.optional (flags.semantictokens) (hsPkgs."haskell-language-server".components.sublibs.hls-semantic-tokens-plugin or (errorHandler.buildDepError "haskell-language-server:hls-semantic-tokens-plugin"))) ++ pkgs.lib.optional (flags.notes) (hsPkgs."haskell-language-server".components.sublibs.hls-notes-plugin or (errorHandler.buildDepError "haskell-language-server:hls-notes-plugin"))) ++ pkgs.lib.optional (flags.export) (hsPkgs."haskell-language-server".components.sublibs.hls-export-plugin or (errorHandler.buildDepError "haskell-language-server:hls-export-plugin"));
        buildable = true;
      };
      sublibs = {
        "hls-cabal-fmt-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."process-extras" or (errorHandler.buildDepError "process-extras"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.cabalfmt || !flags.cabal then false else true;
        };
        "hls-cabal-gild-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."process-extras" or (errorHandler.buildDepError "process-extras"))
          ];
          buildable = if !flags.cabalgild || !flags.cabal then false else true;
        };
        "hls-cabal-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."cabal-add" or (errorHandler.buildDepError "cabal-add"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."Cabal" or (errorHandler.buildDepError "Cabal"))
            (hsPkgs."pretty" or (errorHandler.buildDepError "pretty"))
          ];
          buildable = if !flags.cabal then false else true;
        };
        "hls-class-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.class then false else true;
        };
        "hls-call-hierarchy-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hiedb" or (errorHandler.buildDepError "hiedb"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."sqlite-simple" or (errorHandler.buildDepError "sqlite-simple"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.callhierarchy then false else true;
        };
        "hls-eval-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."Diff" or (errorHandler.buildDepError "Diff"))
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."exceptions" or (errorHandler.buildDepError "exceptions"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."megaparsec" or (errorHandler.buildDepError "megaparsec"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unliftio" or (errorHandler.buildDepError "unliftio"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = if !flags.eval then false else true;
        };
        "hls-explicit-imports-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.importlens then false else true;
        };
        "hls-case-split-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
          ];
          buildable = if !flags.casesplit || compiler.isGhc && compiler.version.lt "9.14"
            then false
            else true;
        };
        "hls-rename-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hiedb" or (errorHandler.buildDepError "hiedb"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."mod" or (errorHandler.buildDepError "mod"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = if !flags.rename then false else true;
        };
        "hls-hlint-plugin" = {
          depends = ([
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hlint" or (errorHandler.buildDepError "hlint"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."refact" or (errorHandler.buildDepError "refact"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."temporary" or (errorHandler.buildDepError "temporary"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."ghc-lib-parser-ex" or (errorHandler.buildDepError "ghc-lib-parser-ex"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.ge "9.11" || compiler.isGhc && compiler.version.lt "9.10") (hsPkgs."apply-refact" or (errorHandler.buildDepError "apply-refact"))) ++ (if flags.ghc-lib
            then [
              (hsPkgs."ghc-lib-parser" or (errorHandler.buildDepError "ghc-lib-parser"))
            ]
            else [
              (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
              (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
            ]);
          buildable = if !flags.hlint || compiler.isGhc && (compiler.version.ge "9.10" && compiler.version.lt "9.11") || compiler.isGhc && compiler.version.ge "9.14"
            then false
            else true;
        };
        "hls-stan-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."stan" or (errorHandler.buildDepError "stan"))
            (hsPkgs."trial" or (errorHandler.buildDepError "trial"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
          ];
          buildable = if !flags.stan || compiler.isGhc && compiler.version.gt "9.11" && !flags.ignore-plugins-ghc-bounds
            then false
            else true;
        };
        "hls-signature-help-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.signaturehelp then false else true;
        };
        "hls-pragmas-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."fuzzy" or (errorHandler.buildDepError "fuzzy"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
          ];
          buildable = if !flags.pragmas then false else true;
        };
        "hls-splice-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."foldl" or (errorHandler.buildDepError "foldl"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          ];
          buildable = if !flags.splice then false else true;
        };
        "hls-alternate-number-format-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.alternatenumberformat then false else true;
        };
        "hls-qualify-imported-names-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.qualifyimportednames then false else true;
        };
        "hls-code-range-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."semigroupoids" or (errorHandler.buildDepError "semigroupoids"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = if !flags.coderange then false else true;
        };
        "hls-change-type-signature-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          ];
          buildable = if !flags.changetypesignature then false else true;
        };
        "hls-gadt-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.gadt then false else true;
        };
        "hls-explicit-fixity-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.explicitfixity then false else true;
        };
        "hls-explicit-record-fields-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
          ];
          buildable = if !flags.explicitfields then false else true;
        };
        "hls-overloaded-record-dot-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
          ];
          buildable = if !flags.overloadedrecorddot then false else true;
        };
        "hls-fourmolu-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."fourmolu" or (errorHandler.buildDepError "fourmolu"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."process-extras" or (errorHandler.buildDepError "process-extras"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          buildable = if !flags.fourmolu then false else true;
        };
        "hls-ormolu-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."process-extras" or (errorHandler.buildDepError "process-extras"))
            (hsPkgs."ormolu" or (errorHandler.buildDepError "ormolu"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
          ];
          buildable = if !flags.ormolu then false else true;
        };
        "hls-stylish-haskell-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."stylish-haskell" or (errorHandler.buildDepError "stylish-haskell"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.stylishhaskell || compiler.isGhc && compiler.version.ge "9.14"
            then false
            else true;
        };
        "hls-refactor-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."ghc-boot" or (errorHandler.buildDepError "ghc-boot"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-exactprint-utils or (errorHandler.buildDepError "haskell-language-server:hls-exactprint-utils"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."syb" or (errorHandler.buildDepError "syb"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."time" or (errorHandler.buildDepError "time"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.10") (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"));
          buildable = if !flags.refactor then false else true;
        };
        "hls-semantic-tokens-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."dlist" or (errorHandler.buildDepError "dlist"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."template-haskell" or (errorHandler.buildDepError "template-haskell"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
          ];
          buildable = if !flags.semantictokens then false else true;
        };
        "hls-notes-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."array" or (errorHandler.buildDepError "array"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ];
          buildable = if !flags.notes then false else true;
        };
        "hls-exactprint-utils" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
          ];
          buildable = true;
        };
        "hls-export-plugin" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghc-boot-th" or (errorHandler.buildDepError "ghc-boot-th"))
            (hsPkgs."ghc-exactprint" or (errorHandler.buildDepError "ghc-exactprint"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-exactprint-utils or (errorHandler.buildDepError "haskell-language-server:hls-exactprint-utils"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
          ];
          buildable = if !flags.export then false else true;
        };
        "ghcide-bench-lib" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."async" or (errorHandler.buildDepError "async"))
            (hsPkgs."binary" or (errorHandler.buildDepError "binary"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."table-layout" or (errorHandler.buildDepError "table-layout"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."row-types" or (errorHandler.buildDepError "row-types"))
          ];
          buildable = true;
        };
      };
      exes = {
        "haskell-language-server" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."haskell-language-server" or (errorHandler.buildDepError "haskell-language-server"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."prettyprinter" or (errorHandler.buildDepError "prettyprinter"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = true;
        };
        "haskell-language-server-wrapper" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server" or (errorHandler.buildDepError "haskell-language-server"))
            (hsPkgs."hie-bios" or (errorHandler.buildDepError "hie-bios"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."unliftio-core" or (errorHandler.buildDepError "unliftio-core"))
          ] ++ (if !system.isWindows
            then [
              (hsPkgs."unix" or (errorHandler.buildDepError "unix"))
              (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            ]
            else [
              (hsPkgs."process" or (errorHandler.buildDepError "process"))
            ]);
          buildable = true;
        };
        "ghcide-test-preprocessor" = {
          depends = [ (hsPkgs."base" or (errorHandler.buildDepError "base")) ];
          buildable = if !flags.test-exe then false else true;
        };
        "ghcide-bench" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."optparse-applicative" or (errorHandler.buildDepError "optparse-applicative"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
            (hsPkgs."safe-exceptions" or (errorHandler.buildDepError "safe-exceptions"))
            (hsPkgs."hls-graph" or (errorHandler.buildDepError "hls-graph"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."haskell-language-server".components.sublibs.ghcide-bench-lib or (errorHandler.buildDepError "haskell-language-server:ghcide-bench-lib"))
          ];
          buildable = if !flags.ghcide-bench then false else true;
        };
        "plugin-tutorial" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."markdown-unlit" or (errorHandler.buildDepError "markdown-unlit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.markdown-unlit.components.exes.markdown-unlit or (pkgs.pkgsBuildBuild.markdown-unlit or (errorHandler.buildToolDepError "markdown-unlit:markdown-unlit")))
          ];
          buildable = if flags.plugin-tutorial && (compiler.isGhc && compiler.version.ge "9.6" && (compiler.isGhc && compiler.version.lt "9.10"))
            then true
            else false;
        };
      };
      tests = {
        "hls-cabal-fmt-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-plugin"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-fmt-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-fmt-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          build-tools = pkgs.lib.optional (flags.isolatecabalfmttests) (hsPkgs.pkgsBuildBuild.cabal-fmt.components.exes.cabal-fmt or (pkgs.pkgsBuildBuild.cabal-fmt or (errorHandler.buildToolDepError "cabal-fmt:cabal-fmt")));
          buildable = if !flags.cabalfmt || !flags.cabal then false else true;
        };
        "hls-cabal-gild-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-plugin"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-gild-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-gild-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          build-tools = pkgs.lib.optional (flags.isolatecabalgildtests) (hsPkgs.pkgsBuildBuild.cabal-gild.components.exes.cabal-gild or (pkgs.pkgsBuildBuild.cabal-gild or (errorHandler.buildToolDepError "cabal-gild:cabal-gild")));
          buildable = if !flags.cabalgild || !flags.cabal then false else true;
        };
        "hls-cabal-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."Cabal-syntax" or (errorHandler.buildDepError "Cabal-syntax"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-cabal-plugin or (errorHandler.buildDepError "haskell-language-server:hls-cabal-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.cabal then false else true;
        };
        "hls-class-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-class-plugin or (errorHandler.buildDepError "haskell-language-server:hls-class-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.class then false else true;
        };
        "hls-call-hierarchy-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-call-hierarchy-plugin or (errorHandler.buildDepError "haskell-language-server:hls-call-hierarchy-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.callhierarchy then false else true;
        };
        "hls-eval-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-eval-plugin or (errorHandler.buildDepError "haskell-language-server:hls-eval-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.eval then false else true;
        };
        "hls-explicit-imports-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-imports-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-imports-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.importlens then false else true;
        };
        "hls-case-split-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-case-split-plugin or (errorHandler.buildDepError "haskell-language-server:hls-case-split-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.casesplit || compiler.isGhc && compiler.version.lt "9.14"
            then false
            else true;
        };
        "hls-rename-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-rename-plugin or (errorHandler.buildDepError "haskell-language-server:hls-rename-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.rename then false else true;
        };
        "hls-hlint-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-hlint-plugin or (errorHandler.buildDepError "haskell-language-server:hls-hlint-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.hlint || compiler.isGhc && (compiler.version.ge "9.10" && compiler.version.lt "9.11") || compiler.isGhc && compiler.version.ge "9.14"
            then false
            else true;
        };
        "hls-stan-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-stan-plugin or (errorHandler.buildDepError "haskell-language-server:hls-stan-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.stan || compiler.isGhc && compiler.version.gt "9.11" && !flags.ignore-plugins-ghc-bounds
            then false
            else true;
        };
        "hls-signature-help-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-signature-help-plugin or (errorHandler.buildDepError "haskell-language-server:hls-signature-help-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.signaturehelp then false else true;
        };
        "hls-pragmas-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-pragmas-plugin or (errorHandler.buildDepError "haskell-language-server:hls-pragmas-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.pragmas then false else true;
        };
        "hls-splice-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-splice-plugin or (errorHandler.buildDepError "haskell-language-server:hls-splice-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.splice then false else true;
        };
        "hls-alternate-number-format-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-alternate-number-format-plugin or (errorHandler.buildDepError "haskell-language-server:hls-alternate-number-format-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.alternatenumberformat then false else true;
        };
        "hls-qualify-imported-names-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-qualify-imported-names-plugin or (errorHandler.buildDepError "haskell-language-server:hls-qualify-imported-names-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          buildable = if !flags.qualifyimportednames then false else true;
        };
        "hls-code-range-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-code-range-plugin or (errorHandler.buildDepError "haskell-language-server:hls-code-range-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."transformers" or (errorHandler.buildDepError "transformers"))
            (hsPkgs."vector" or (errorHandler.buildDepError "vector"))
          ];
          buildable = if !flags.coderange then false else true;
        };
        "hls-change-type-signature-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-change-type-signature-plugin or (errorHandler.buildDepError "haskell-language-server:hls-change-type-signature-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.changetypesignature then false else true;
        };
        "hls-gadt-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-gadt-plugin or (errorHandler.buildDepError "haskell-language-server:hls-gadt-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.gadt then false else true;
        };
        "hls-explicit-fixity-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-fixity-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-fixity-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.explicitfixity then false else true;
        };
        "hls-explicit-record-fields-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-explicit-record-fields-plugin or (errorHandler.buildDepError "haskell-language-server:hls-explicit-record-fields-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          buildable = if !flags.explicitfields then false else true;
        };
        "hls-overloaded-record-dot-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-overloaded-record-dot-plugin or (errorHandler.buildDepError "haskell-language-server:hls-overloaded-record-dot-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          buildable = if !flags.overloadedrecorddot then false else true;
        };
        "hls-fourmolu-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-fourmolu-plugin or (errorHandler.buildDepError "haskell-language-server:hls-fourmolu-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.fourmolu.components.exes.fourmolu or (pkgs.pkgsBuildBuild.fourmolu or (errorHandler.buildToolDepError "fourmolu:fourmolu")))
          ];
          buildable = if !flags.fourmolu then false else true;
        };
        "hls-ormolu-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-ormolu-plugin or (errorHandler.buildDepError "haskell-language-server:hls-ormolu-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."ormolu" or (errorHandler.buildDepError "ormolu"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.ormolu.components.exes.ormolu or (pkgs.pkgsBuildBuild.ormolu or (errorHandler.buildToolDepError "ormolu:ormolu")))
          ];
          buildable = if !flags.ormolu then false else true;
        };
        "hls-stylish-haskell-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-stylish-haskell-plugin or (errorHandler.buildDepError "haskell-language-server:hls-stylish-haskell-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          buildable = if !flags.stylishhaskell || compiler.isGhc && compiler.version.ge "9.14"
            then false
            else true;
        };
        "hls-refactor-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."parser-combinators" or (errorHandler.buildDepError "parser-combinators"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.refactor then false else true;
        };
        "hls-semantic-tokens-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-semantic-tokens-plugin or (errorHandler.buildDepError "haskell-language-server:hls-semantic-tokens-plugin"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
          ];
          buildable = if !flags.semantictokens then false else true;
        };
        "hls-notes-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-notes-plugin or (errorHandler.buildDepError "haskell-language-server:hls-notes-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ];
          buildable = if !flags.notes then false else true;
        };
        "hls-export-plugin-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.hls-export-plugin or (errorHandler.buildDepError "haskell-language-server:hls-export-plugin"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
          ];
          buildable = if !flags.export then false else true;
        };
        "func-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."bytestring" or (errorHandler.buildDepError "bytestring"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."deepseq" or (errorHandler.buildDepError "deepseq"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hashable" or (errorHandler.buildDepError "hashable"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
          ] ++ pkgs.lib.optional (flags.refactor) (hsPkgs."haskell-language-server".components.sublibs.hls-refactor-plugin or (errorHandler.buildDepError "haskell-language-server:hls-refactor-plugin"));
          build-tools = [
            (hsPkgs.pkgsBuildBuild.haskell-language-server.components.exes.haskell-language-server or (pkgs.pkgsBuildBuild.haskell-language-server or (errorHandler.buildToolDepError "haskell-language-server:haskell-language-server")))
          ];
          buildable = true;
        };
        "wrapper-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
            (hsPkgs."process" or (errorHandler.buildDepError "process"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.haskell-language-server.components.exes.haskell-language-server-wrapper or (pkgs.pkgsBuildBuild.haskell-language-server-wrapper or (errorHandler.buildToolDepError "haskell-language-server:haskell-language-server-wrapper")))
            (hsPkgs.pkgsBuildBuild.haskell-language-server.components.exes.haskell-language-server or (pkgs.pkgsBuildBuild.haskell-language-server or (errorHandler.buildToolDepError "haskell-language-server:haskell-language-server")))
          ];
          buildable = true;
        };
        "ghcide-tests" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."enummapset" or (errorHandler.buildDepError "enummapset"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."ghc" or (errorHandler.buildDepError "ghc"))
            (hsPkgs."ghcide" or (errorHandler.buildDepError "ghcide"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."list-t" or (errorHandler.buildDepError "list-t"))
            (hsPkgs."lsp" or (errorHandler.buildDepError "lsp"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."lsp-types" or (errorHandler.buildDepError "lsp-types"))
            (hsPkgs."mtl" or (errorHandler.buildDepError "mtl"))
            (hsPkgs."network-uri" or (errorHandler.buildDepError "network-uri"))
            (hsPkgs."QuickCheck" or (errorHandler.buildDepError "QuickCheck"))
            (hsPkgs."random" or (errorHandler.buildDepError "random"))
            (hsPkgs."regex-tdfa" or (errorHandler.buildDepError "regex-tdfa"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."sqlite-simple" or (errorHandler.buildDepError "sqlite-simple"))
            (hsPkgs."stm" or (errorHandler.buildDepError "stm"))
            (hsPkgs."stm-containers" or (errorHandler.buildDepError "stm-containers"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-expected-failure" or (errorHandler.buildDepError "tasty-expected-failure"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-quickcheck" or (errorHandler.buildDepError "tasty-quickcheck"))
            (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."text-rope" or (errorHandler.buildDepError "text-rope"))
            (hsPkgs."unordered-containers" or (errorHandler.buildDepError "unordered-containers"))
            (hsPkgs."hls-test-utils" or (errorHandler.buildDepError "hls-test-utils"))
          ] ++ pkgs.lib.optional (compiler.isGhc && compiler.version.lt "9.3") (hsPkgs."ghc-typelits-knownnat" or (errorHandler.buildDepError "ghc-typelits-knownnat"));
          build-tools = [
            (hsPkgs.pkgsBuildBuild.ghcide.components.exes.ghcide or (pkgs.pkgsBuildBuild.ghcide or (errorHandler.buildToolDepError "ghcide:ghcide")))
            (hsPkgs.pkgsBuildBuild.haskell-language-server.components.exes.ghcide-test-preprocessor or (pkgs.pkgsBuildBuild.ghcide-test-preprocessor or (errorHandler.buildToolDepError "haskell-language-server:ghcide-test-preprocessor")))
            (hsPkgs.pkgsBuildBuild.implicit-hie.components.exes.gen-hie or (pkgs.pkgsBuildBuild.gen-hie or (errorHandler.buildToolDepError "implicit-hie:gen-hie")))
          ];
          buildable = true;
        };
        "ghcide-bench-test" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."haskell-language-server".components.sublibs.ghcide-bench-lib or (errorHandler.buildDepError "haskell-language-server:ghcide-bench-lib"))
            (hsPkgs."lsp-test" or (errorHandler.buildDepError "lsp-test"))
            (hsPkgs."tasty" or (errorHandler.buildDepError "tasty"))
            (hsPkgs."tasty-hunit" or (errorHandler.buildDepError "tasty-hunit"))
            (hsPkgs."tasty-rerun" or (errorHandler.buildDepError "tasty-rerun"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.ghcide.components.exes.ghcide or (pkgs.pkgsBuildBuild.ghcide or (errorHandler.buildToolDepError "ghcide:ghcide")))
          ];
          buildable = true;
        };
      };
      benchmarks = {
        "benchmark" = {
          depends = [
            (hsPkgs."base" or (errorHandler.buildDepError "base"))
            (hsPkgs."aeson" or (errorHandler.buildDepError "aeson"))
            (hsPkgs."containers" or (errorHandler.buildDepError "containers"))
            (hsPkgs."data-default" or (errorHandler.buildDepError "data-default"))
            (hsPkgs."directory" or (errorHandler.buildDepError "directory"))
            (hsPkgs."extra" or (errorHandler.buildDepError "extra"))
            (hsPkgs."filepath" or (errorHandler.buildDepError "filepath"))
            (hsPkgs."haskell-language-server".components.sublibs.ghcide-bench-lib or (errorHandler.buildDepError "haskell-language-server:ghcide-bench-lib"))
            (hsPkgs."haskell-language-server" or (errorHandler.buildDepError "haskell-language-server"))
            (hsPkgs."hls-plugin-api" or (errorHandler.buildDepError "hls-plugin-api"))
            (hsPkgs."lens" or (errorHandler.buildDepError "lens"))
            (hsPkgs."lens-aeson" or (errorHandler.buildDepError "lens-aeson"))
            (hsPkgs."shake" or (errorHandler.buildDepError "shake"))
            (hsPkgs."shake-bench" or (errorHandler.buildDepError "shake-bench"))
            (hsPkgs."text" or (errorHandler.buildDepError "text"))
            (hsPkgs."yaml" or (errorHandler.buildDepError "yaml"))
          ];
          build-tools = [
            (hsPkgs.pkgsBuildBuild.haskell-language-server.components.exes.ghcide-bench or (pkgs.pkgsBuildBuild.ghcide-bench or (errorHandler.buildToolDepError "haskell-language-server:ghcide-bench")))
          ];
          buildable = true;
        };
      };
    };
  } // {
    src = pkgs.lib.mkDefault (pkgs.fetchurl {
      url = "http://hackage.haskell.org/package/haskell-language-server-2.15.0.0.tar.gz";
      sha256 = "0ef0cd32616bdc3ff9524107b942aba9914b53bb7dcd7bf26c05a62831b3eabf";
    });
  }) // {
    package-description-override = "cabal-version:      3.4\ncategory:           Development\nname:               haskell-language-server\nversion:            2.15.0.0\nsynopsis:           LSP server for GHC\ndescription:\n  Please see the README on GitHub at <https://github.com/haskell/haskell-language-server#readme>\n\nhomepage:           https://github.com/haskell/haskell-language-server#readme\nbug-reports:        https://github.com/haskell/haskell-language-server/issues\nauthor:             The Haskell IDE Team\nmaintainer:         alan.zimm@gmail.com\ncopyright:          The Haskell IDE Team\nlicense:            Apache-2.0\nlicense-file:       LICENSE\nbuild-type:         Simple\ntested-with:        GHC == {9.14.1, 9.12.2, 9.10.3, 9.8.4, 9.6.7}\nextra-source-files:\n  README.md\n  ChangeLog.md\n  test/testdata/**/*.project\n  test/testdata/**/*.cabal\n  test/testdata/**/*.yaml\n  test/testdata/**/*.hs\n  test/testdata/**/*.json\n\n  -- These globs should only match test/testdata\n  plugins/**/*.project\n  plugins/**/*.expected\n  plugins/**/*.cabal\n  plugins/**/*.yaml\n  plugins/**/*.txt\n  plugins/**/*.hs\n\n  ghcide-test/data/**/*.cabal\n  ghcide-test/data/**/*.hs\n  ghcide-test/data/**/*.hs-boot\n  ghcide-test/data/**/*.project\n  ghcide-test/data/**/*.yaml\n\n  bindist/wrapper.in\n\nsource-repository head\n  type:     git\n  location: https://github.com/haskell/haskell-language-server\n\ncommon defaults\n  default-language: GHC2021\n  -- Should have been in GHC2021, an oversight\n  default-extensions: ExplicitNamespaces\n  build-depends:\n    , base >=4.12 && <5\n\ncommon test-defaults\n  ghc-options: -threaded -rtsopts -with-rtsopts=-N\n  if impl(ghc >= 9.8)\n    -- We allow using partial functions in tests\n    ghc-options: -Wno-x-partial\n\n-- Default warnings in HLS\ncommon warnings\n  ghc-options: -Wall\n               -Wredundant-constraints\n               -Wunused-packages\n               -Wno-name-shadowing\n               -Wno-unticked-promoted-constructors\n\nflag pedantic\n  description: Enable -Werror\n  default:     False\n  manual:      True\n\n-- Allow compiling in pedantic mode\ncommon pedantic\n  if flag(pedantic)\n    ghc-options:\n      -Werror\n      -- Note [unused-packages]\n      -- ~~~~~~~~~~~~~~~~~~~~~~\n      -- Some packages need CPP conditioned on MIN_VERSION_ghc(x,y,z).\n      -- MIN_VERSION_<pkg> is CPP macro that cabal defines only when <pkg> is declared as a dependency.\n      -- But -Wunused-packages still reports it as unused dependency if it's not imported.\n      -- For packages with such \"unused\" dependencies we demote -Wunused-packages error\n      -- (enabled by --flag=pedantic) to warning via -Wwarn=unused-packages.\n      -Wwarn=unused-packages\n\n-- Plugin flags are designed for 'cabal install haskell-language-server':\n-- - Bulk flags should be default:False\n-- - Individual flags should be default:True\n\n-- The intent of this flag is being able to keep the ghc condition for hackage\n-- but skip it via flags in cabal.project as plugins for new ghcs usually\n-- are buildable using cabal.project tweaks\nflag ignore-plugins-ghc-bounds\n  description: Force the inclusion of plugins even if they are not buildable by default with a specific ghc version\n  default:     False\n  manual:      True\n\nflag dynamic\n  description: Build with the dyn rts\n  default:     True\n  manual:      True\n\n----------------------------\n----------------------------\n-- PLUGINS\n----------------------------\n----------------------------\n\n-----------------------------\n-- cabal-fmt plugin\n-----------------------------\n\nflag cabalfmt\n  description: Enable cabal-fmt plugin\n  default:     True\n  manual:      True\n\ncommon cabalfmt\n  if flag(cabalfmt) && flag(cabal)\n    build-depends: haskell-language-server:hls-cabal-fmt-plugin\n    cpp-options: -Dhls_cabalfmt\n\nflag isolateCabalfmtTests\n  description: Should tests search for 'cabal-fmt' on the $PATH or shall we install it via build-tool-depends?\n  -- By default, search on the PATH\n  default:     False\n  manual:      True\n\nlibrary hls-cabal-fmt-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(cabalfmt) || !flag(cabal)\n    buildable: False\n  exposed-modules:  Ide.Plugin.CabalFmt\n  hs-source-dirs:   plugins/hls-cabal-fmt-plugin/src\n  build-depends:\n    , directory\n    , filepath\n    , ghcide          == 2.15.0.0\n    , hls-plugin-api  == 2.15.0.0\n    , lens\n    , lsp-types\n    , mtl\n    , process-extras\n    , text\n\n-- The `hls-cabal-plugin` is needed for tests, as we need to install notification handlers\ntest-suite hls-cabal-fmt-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(cabalfmt) || !flag(cabal)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-cabal-fmt-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , directory\n    , filepath\n    , haskell-language-server:hls-cabal-plugin\n    , haskell-language-server:hls-cabal-fmt-plugin\n    , hls-plugin-api        == 2.15.0.0\n    , hls-test-utils        == 2.15.0.0\n\n  if flag(isolateCabalfmtTests)\n    build-tool-depends: cabal-fmt:cabal-fmt ^>=0.1.12\n    cpp-options: -Dhls_isolate_cabalfmt_tests\n\n-----------------------------\n-- cabal-gild plugin\n-----------------------------\n\nflag cabalgild\n  description: Enable cabal-gild plugin\n  default:     True\n  manual:      True\n\ncommon cabalgild\n  if flag(cabalgild) && flag(cabal)\n    build-depends: haskell-language-server:hls-cabal-gild-plugin\n    cpp-options: -Dhls_cabalgild\n\nflag isolateCabalGildTests\n  description: Should tests search for 'cabal-gild' on the $PATH or shall we install it via build-tool-depends?\n  -- By default, search on the PATH\n  default:     False\n  manual:      True\n\nlibrary hls-cabal-gild-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(cabalgild) || !flag(cabal)\n    buildable: False\n  exposed-modules:  Ide.Plugin.CabalGild\n  hs-source-dirs:   plugins/hls-cabal-gild-plugin/src\n  build-depends:\n    , directory\n    , filepath\n    , ghcide          == 2.15.0.0\n    , hls-plugin-api  == 2.15.0.0\n    , lsp-types\n    , text\n    , mtl\n    , process-extras\n\n-- The `hls-cabal-plugin` is needed for tests, as we need to install notification handlers\ntest-suite hls-cabal-gild-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(cabalgild) || !flag(cabal)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-cabal-gild-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , directory\n    , filepath\n    , haskell-language-server:hls-cabal-plugin\n    , haskell-language-server:hls-cabal-gild-plugin\n    , hls-plugin-api        == 2.15.0.0\n    , hls-test-utils        == 2.15.0.0\n\n  if flag(isolateCabalGildTests)\n    -- https://github.com/tfausak/cabal-gild/issues/89\n    build-tool-depends: cabal-gild:cabal-gild >= 1.3 && < 1.3.2\n    cpp-options: -Dhls_isolate_cabalgild_tests\n\n-----------------------------\n-- cabal plugin\n-----------------------------\n\nflag cabal\n  description: Enable cabal plugin\n  default:     True\n  manual:      True\n\ncommon cabal\n  if flag(cabal)\n    build-depends: haskell-language-server:hls-cabal-plugin\n    cpp-options: -Dhls_cabal\n\nlibrary hls-cabal-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(cabal)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Cabal\n    Ide.Plugin.Cabal.Diagnostics\n    Ide.Plugin.Cabal.Completion.CabalFields\n    Ide.Plugin.Cabal.Completion.Completer.FilePath\n    Ide.Plugin.Cabal.Completion.Completer.Module\n    Ide.Plugin.Cabal.Completion.Completer.Paths\n    Ide.Plugin.Cabal.Completion.Completer.Simple\n    Ide.Plugin.Cabal.Completion.Completer.Snippet\n    Ide.Plugin.Cabal.Completion.Completer.Types\n    Ide.Plugin.Cabal.Completion.Completions\n    Ide.Plugin.Cabal.Completion.Data\n    Ide.Plugin.Cabal.Completion.Types\n    Ide.Plugin.Cabal.Definition\n    Ide.Plugin.Cabal.FieldSuggest\n    Ide.Plugin.Cabal.Files\n    Ide.Plugin.Cabal.OfInterest\n    Ide.Plugin.Cabal.LicenseSuggest\n    Ide.Plugin.Cabal.Rules\n    Ide.Plugin.Cabal.CabalAdd.Command\n    Ide.Plugin.Cabal.CabalAdd.CodeAction\n    Ide.Plugin.Cabal.CabalAdd.Types\n    Ide.Plugin.Cabal.Orphans\n    Ide.Plugin.Cabal.Outline\n    Ide.Plugin.Cabal.Parse\n\n\n  build-depends:\n    , bytestring\n    , Cabal-syntax          >= 3.7\n    , containers\n    , deepseq\n    , directory\n    , filepath\n    , extra                 >=1.7.4\n    , ghcide                == 2.15.0.0\n    , hashable\n    , hls-plugin-api        == 2.15.0.0\n    , hls-graph             == 2.15.0.0\n    , lens\n    , lsp                   ^>=2.8\n    , lsp-types             ^>=2.4\n    , mtl\n    , regex-tdfa            ^>=1.3.1\n    , text\n    , text-rope\n    , transformers\n    , unordered-containers  >=0.2.10.0\n    , containers\n    , cabal-add             ^>=0.2\n    , aeson\n    , Cabal\n    , pretty\n\n  hs-source-dirs:   plugins/hls-cabal-plugin/src\n\ntest-suite hls-cabal-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(cabal)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-cabal-plugin/test\n  main-is:          Main.hs\n  other-modules:\n    CabalAdd\n    Completer\n    Context\n    Definition\n    Outline\n    Utils\n  build-depends:\n    , bytestring\n    , Cabal-syntax          >= 3.7\n    , extra\n    , filepath\n    , ghcide\n    , haskell-language-server:hls-cabal-plugin\n    , hls-test-utils    == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- class plugin\n-----------------------------\n\nflag class\n  description: Enable class plugin\n  default:     True\n  manual:      True\n\ncommon class\n  if flag(class)\n    build-depends: haskell-language-server:hls-class-plugin\n    cpp-options: -Dhls_class\n\nlibrary hls-class-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(class)\n    buildable: False\n  exposed-modules:    Ide.Plugin.Class\n  other-modules:      Ide.Plugin.Class.CodeAction\n                    , Ide.Plugin.Class.CodeLens\n                    , Ide.Plugin.Class.ExactPrint\n                    , Ide.Plugin.Class.Types\n                    , Ide.Plugin.Class.Utils\n  hs-source-dirs:     plugins/hls-class-plugin/src\n  build-depends:\n    , aeson\n    , containers\n    , deepseq\n    , extra\n    , ghc\n    , ghc-exactprint  >= 1.5 && < 1.15\n    , ghcide          == 2.15.0.0\n    , hls-graph\n    , hls-plugin-api  == 2.15.0.0\n    , lens\n    , lsp\n    , text\n    , transformers\n\n  default-extensions:\n    DataKinds\n    OverloadedStrings\n\ntest-suite hls-class-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(class)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-class-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-class-plugin\n    , hls-test-utils     == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- call-hierarchy plugin\n-----------------------------\n\nflag callHierarchy\n  description: Enable call hierarchy plugin\n  default:     True\n  manual:      True\n\ncommon callHierarchy\n  if flag(callHierarchy)\n    build-depends: haskell-language-server:hls-call-hierarchy-plugin\n    cpp-options: -Dhls_callHierarchy\n\nlibrary hls-call-hierarchy-plugin\n  import: defaults, pedantic, warnings\n  if !flag(callHierarchy)\n    buildable: False\n  exposed-modules:    Ide.Plugin.CallHierarchy\n  other-modules:\n    Ide.Plugin.CallHierarchy.Internal\n    Ide.Plugin.CallHierarchy.Query\n    Ide.Plugin.CallHierarchy.Types\n\n  hs-source-dirs:     plugins/hls-call-hierarchy-plugin/src\n  build-depends:\n    , aeson\n    , containers\n    , extra\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hiedb                 ^>= 0.8.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp                    >=2.8\n    , sqlite-simple\n    , text\n\n  default-extensions: DataKinds\n\ntest-suite hls-call-hierarchy-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(callHierarchy)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-call-hierarchy-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , aeson\n    , containers\n    , extra\n    , filepath\n    , haskell-language-server:hls-call-hierarchy-plugin\n    , hls-test-utils        == 2.15.0.0\n    , lens\n    , lsp\n    , lsp-test\n    , text\n\n-----------------------------\n-- eval plugin\n-----------------------------\n\nflag eval\n  description: Enable eval plugin\n  default:     True\n  manual:      True\n\ncommon eval\n  if flag(eval)\n    build-depends: haskell-language-server:hls-eval-plugin\n    cpp-options: -Dhls_eval\n\nlibrary hls-eval-plugin\n  import: defaults, pedantic, warnings\n  if !flag(eval)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Eval\n    Ide.Plugin.Eval.Types\n\n  hs-source-dirs:     plugins/hls-eval-plugin/src\n  other-modules:\n    Ide.Plugin.Eval.Code\n    Ide.Plugin.Eval.Config\n    Ide.Plugin.Eval.GHC\n    Ide.Plugin.Eval.Handlers\n    Ide.Plugin.Eval.Parse.Comments\n    Ide.Plugin.Eval.Parse.Option\n    Ide.Plugin.Eval.Rules\n    Ide.Plugin.Eval.Util\n\n  build-depends:\n    , aeson\n    , bytestring\n    , containers\n    , deepseq\n    , Diff                  ^>=0.5 || ^>=1.0.0\n    , dlist\n    , exceptions\n    , extra\n    , filepath\n    , ghc\n    , ghc-boot-th\n    , ghcide                == 2.15.0.0\n    , hls-graph\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp                   ^>=2.8\n    , lsp-types\n    , megaparsec            >=9.0\n    , mtl\n    , parser-combinators    >=1.2\n    , text\n    , text-rope\n    , transformers\n    , unliftio\n    , unordered-containers\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-eval-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(eval)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-eval-plugin/test\n  main-is:          Main.hs\n  ghc-options:      -fno-ignore-asserts\n  build-depends:\n    , aeson\n    , containers\n    , extra\n    , filepath\n    , haskell-language-server:hls-eval-plugin\n    , hls-plugin-api\n    , hls-test-utils   == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- import lens plugin\n-----------------------------\n\nflag importLens\n  description: Enable importLens plugin\n  default:     True\n  manual:      False\n\ncommon importLens\n  if flag(importLens)\n    build-depends: haskell-language-server:hls-explicit-imports-plugin\n    cpp-options: -Dhls_importLens\n\nlibrary hls-explicit-imports-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(importlens)\n    buildable: False\n  exposed-modules:  Ide.Plugin.ExplicitImports\n  hs-source-dirs:   plugins/hls-explicit-imports-plugin/src\n  build-depends:\n    , aeson\n    , containers\n    , deepseq\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-graph\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp\n    , mtl\n    , text\n    , transformers\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-explicit-imports-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(importlens)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-explicit-imports-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , extra\n    , filepath\n    , haskell-language-server:hls-explicit-imports-plugin\n    , hls-test-utils   == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- case split plugin\n-----------------------------\n\nflag caseSplit\n  description: Enable caseSplit plugin\n  default:     True\n  manual:      True\n\ncommon caseSplit\n  if flag(casesplit) && !impl(ghc < 9.14)\n    build-depends: haskell-language-server:hls-case-split-plugin\n    cpp-options: -Dhls_caseSplit\n\nlibrary hls-case-split-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(casesplit) || impl(ghc < 9.14)\n    buildable: False\n  exposed-modules:  Ide.Plugin.CaseSplit\n  hs-source-dirs:   plugins/hls-case-split-plugin/src\n  build-depends:\n    , extra\n    , ghc\n    , haskell-language-server:hls-refactor-plugin\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp\n    , mtl\n    , syb\n    , text\n    , transformers\n    , ghc-exactprint        >= 1.14.1.0\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-case-split-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(casesplit) || impl(ghc < 9.14)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-case-split-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-case-split-plugin\n    , hls-test-utils   == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- rename plugin\n-----------------------------\n\nflag rename\n  description: Enable rename plugin\n  default:     True\n  manual:      True\n\ncommon rename\n  if flag(rename)\n    build-depends: haskell-language-server:hls-rename-plugin\n    cpp-options: -Dhls_rename\n\nlibrary hls-rename-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(rename)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Rename\n    Ide.Plugin.Rename.ModuleName\n  hs-source-dirs:   plugins/hls-rename-plugin/src\n  build-depends:\n    , aeson\n    , containers\n    , filepath\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hashable\n    , hiedb                 ^>= 0.8.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , haskell-language-server:hls-refactor-plugin\n    , lens\n    , lsp-types\n    , mtl\n    , mod\n    , syb\n    , text\n    , text-rope\n    , transformers\n    , unordered-containers\n\n\ntest-suite hls-rename-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(rename)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-rename-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , aeson\n    , containers\n    , filepath\n    , hls-plugin-api\n    , haskell-language-server:hls-rename-plugin\n    , hls-test-utils             == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- hlint plugin\n-----------------------------\n\nflag ghc-lib\n  description:\n    Use ghc-lib-parser rather than the ghc library (requires hlint and\n    ghc-lib-parser-ex to also be built with it)\n  default: True\n  manual: True\n\nflag hlint\n  description: Enable hlint plugin\n  default:     True\n  manual:      True\n\ncommon hlint\n  -- Hlint isn't compatible with GHC 9.10, and crashes in subtle ways.\n  -- See https://github.com/haskell/haskell-language-server/issues/4674\n  -- for its wake of destruction.\n  -- hlint depends on ghc-lib-parser which doesn't support GHC 9.14\n  if flag(hlint) && !impl(ghc ==9.10.*) && !impl(ghc >= 9.14)\n    build-depends: haskell-language-server:hls-hlint-plugin\n    cpp-options: -Dhls_hlint\n\nlibrary hls-hlint-plugin\n  import:           defaults, pedantic, warnings\n  -- Hlint isn't compatible with GHC 9.10, and crashes in subtle ways.\n  -- See https://github.com/haskell/haskell-language-server/issues/4674\n  -- for its wake of destruction.\n  -- hlint depends on ghc-lib-parser which doesn't support GHC 9.14\n  if !flag(hlint) || impl(ghc ==9.10.*) || impl(ghc >= 9.14)\n    buildable: False\n  exposed-modules:  Ide.Plugin.Hlint\n  hs-source-dirs:   plugins/hls-hlint-plugin/src\n  build-depends:\n    , aeson\n    , bytestring\n    , containers\n    , deepseq\n    , filepath\n    , ghcide                == 2.15.0.0\n    , hashable\n    , hlint                 >= 3.5 && < 3.11\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , mtl\n    , refact\n    , regex-tdfa\n    , stm\n    , temporary\n    , text\n    , text-rope\n    , transformers\n    , unordered-containers\n    , ghc-lib-parser-ex\n    , lsp-types\n\n  -- apply-refact doesn't work on 9.10, or even have a buildable\n  -- configuration\n  if impl(ghc >= 9.11) || impl(ghc < 9.10)\n    cpp-options:   -DAPPLY_REFACT\n    build-depends: apply-refact\n\n  if flag(ghc-lib)\n    cpp-options:   -DGHC_LIB\n    build-depends:\n        ghc-lib-parser\n  else\n    build-depends:\n        ghc\n      , ghc-boot\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-hlint-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  -- Hlint isn't compatible with GHC 9.10, and crashes in subtle ways.\n  -- See https://github.com/haskell/haskell-language-server/issues/4674\n  -- for its wake of destruction.\n  -- hlint depends on ghc-lib-parser which doesn't support GHC 9.14\n  if !flag(hlint) || impl(ghc ==9.10.*) || impl(ghc >= 9.14)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-hlint-plugin/test\n  main-is:          Main.hs\n  -- Work around https://gitlab.haskell.org/ghc/ghc/-/issues/24648\n  if os(darwin)\n    ghc-options: -optl-Wl,-ld_classic\n\n  build-depends:\n      aeson\n    , containers\n    , filepath\n    , haskell-language-server:hls-hlint-plugin\n    , hls-plugin-api\n    , hls-test-utils      == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- stan plugin\n-----------------------------\n\nflag stan\n  description: Enable stan plugin\n  default:     True\n  manual:      True\n\ncommon stan\n  if flag(stan) && (impl(ghc < 9.11) || flag(ignore-plugins-ghc-bounds))\n    build-depends: haskell-language-server:hls-stan-plugin\n    cpp-options: -Dhls_stan\n\nlibrary hls-stan-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(stan) || (impl(ghc > 9.11) && !flag(ignore-plugins-ghc-bounds))\n    buildable: False\n  exposed-modules:    Ide.Plugin.Stan\n  hs-source-dirs:     plugins/hls-stan-plugin/src\n  build-depends:\n    , deepseq\n    , hashable\n    , hls-plugin-api\n    , ghcide\n    , lsp-types\n    , text\n    , unordered-containers\n    , stan >= 0.2.1.0\n    , trial\n    , directory\n\n  default-extensions:\n    LambdaCase\n    TypeFamilies\n    DuplicateRecordFields\n    OverloadedStrings\n\ntest-suite hls-stan-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(stan) || (impl(ghc > 9.11) && !flag(ignore-plugins-ghc-bounds))\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-stan-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-stan-plugin\n    , hls-plugin-api\n    , hls-test-utils      == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n  default-extensions:\n    OverloadedStrings\n\n-----------------------------\n-- signature help plugin\n-----------------------------\n\nflag signatureHelp\n  description: Enable signature help plugin\n  default:     True\n  manual:      True\n\ncommon signatureHelp\n  if flag(signatureHelp)\n    build-depends: haskell-language-server:hls-signature-help-plugin\n    cpp-options: -Dhls_signatureHelp\n\nlibrary hls-signature-help-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(signatureHelp)\n    buildable: False\n  exposed-modules:  Ide.Plugin.SignatureHelp\n  hs-source-dirs:   plugins/hls-signature-help-plugin/src\n  default-extensions:\n    DerivingStrategies\n    LambdaCase\n    OverloadedStrings\n  build-depends:\n    , containers\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lsp-types\n    , text\n    , transformers\n\n\ntest-suite hls-signature-help-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(signatureHelp)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-signature-help-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , ghcide\n    , haskell-language-server:hls-signature-help-plugin\n    , hls-test-utils             == 2.15.0.0\n    , text\n  default-extensions:\n    DerivingStrategies\n    OverloadedStrings\n\n-----------------------------\n-- pragmas plugin\n-----------------------------\n\nflag pragmas\n  description: Enable pragmas plugin\n  default:     True\n  manual:      True\n\ncommon pragmas\n  if flag(pragmas)\n    build-depends: haskell-language-server:hls-pragmas-plugin\n    cpp-options: -Dhls_pragmas\n\nlibrary hls-pragmas-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(pragmas)\n    buildable: False\n  exposed-modules:  Ide.Plugin.Pragmas\n  hs-source-dirs:   plugins/hls-pragmas-plugin/src\n  build-depends:\n    , aeson\n    , extra\n    , fuzzy\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp\n    , text\n    , containers\n\ntest-suite hls-pragmas-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(pragmas)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-pragmas-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , aeson\n    , filepath\n    , haskell-language-server:hls-pragmas-plugin\n    , hls-test-utils      == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n\n-----------------------------\n-- splice plugin\n-----------------------------\n\nflag splice\n  description: Enable splice plugin\n  default:     True\n  manual:      True\n\ncommon splice\n  if flag(splice)\n    build-depends: haskell-language-server:hls-splice-plugin\n    cpp-options: -Dhls_splice\n\nlibrary hls-splice-plugin\n  import:           defaults, pedantic, warnings\n  if !(flag(splice))\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Splice\n    Ide.Plugin.Splice.Types\n\n  hs-source-dirs:     plugins/hls-splice-plugin/src\n  build-depends:\n    , aeson\n    , extra\n    , foldl\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , haskell-language-server:hls-refactor-plugin\n    , lens\n    , lsp\n    , mtl\n    , syb\n    , text\n    , transformers\n    , unliftio-core\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-splice-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !(flag(splice))\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-splice-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-splice-plugin\n    , hls-test-utils == 2.15.0.0\n    , text\n\n-----------------------------\n-- alternate number format plugin\n-----------------------------\n\nflag alternateNumberFormat\n  description: Enable Alternate Number Format plugin\n  default:     True\n  manual:      True\n\ncommon alternateNumberFormat\n  if flag(alternateNumberFormat)\n    build-depends: haskell-language-server:hls-alternate-number-format-plugin\n    cpp-options: -Dhls_alternateNumberFormat\n\nlibrary hls-alternate-number-format-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(alternateNumberFormat)\n    buildable: False\n  exposed-modules:  Ide.Plugin.AlternateNumberFormat, Ide.Plugin.Conversion\n  other-modules:    Ide.Plugin.Literals\n  hs-source-dirs:   plugins/hls-alternate-number-format-plugin/src\n  build-depends:\n    , containers\n    , extra\n    , ghcide               == 2.15.0.0\n    , ghc-boot-th\n    , hls-graph\n    , hls-plugin-api       == 2.15.0.0\n    , lens\n    , lsp                  ^>=2.8\n    , mtl\n    , syb\n    , text\n\n  default-extensions:\n    LambdaCase\n    OverloadedStrings\n    RecordWildCards\n\ntest-suite hls-alternate-number-format-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(alternateNumberFormat)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-alternate-number-format-plugin/test\n  other-modules:    Properties.Conversion\n  main-is:          Main.hs\n  ghc-options:      -fno-ignore-asserts\n  build-depends:\n    , containers\n    , filepath\n    , haskell-language-server:hls-alternate-number-format-plugin\n    , hls-test-utils       == 2.15.0.0\n    , regex-tdfa\n    , tasty-quickcheck\n    , text\n\n  default-extensions:\n    LambdaCase\n    OverloadedStrings\n    RecordWildCards\n\n-----------------------------\n-- qualify imported names plugin\n-----------------------------\n\nflag qualifyImportedNames\n  description: Enable qualifyImportedNames plugin\n  default:     True\n  manual:      True\n\ncommon qualifyImportedNames\n  if flag(qualifyImportedNames)\n    build-depends: haskell-language-server:hls-qualify-imported-names-plugin\n    cpp-options: -Dhls_qualifyImportedNames\n\nlibrary hls-qualify-imported-names-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(qualifyImportedNames)\n    buildable: False\n  exposed-modules:  Ide.Plugin.QualifyImportedNames\n  hs-source-dirs:   plugins/hls-qualify-imported-names-plugin/src\n  build-depends:\n    , containers\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp\n    , text\n    , text-rope\n    , dlist\n    , transformers\n\n  default-extensions:\n    DataKinds\n\ntest-suite hls-qualify-imported-names-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(qualifyImportedNames)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-qualify-imported-names-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , text\n    , filepath\n    , haskell-language-server:hls-qualify-imported-names-plugin\n    , hls-test-utils             == 2.15.0.0\n\n-----------------------------\n-- code range plugin\n-----------------------------\n\nflag codeRange\n  description: Enable Code Range plugin\n  default:     True\n  manual:      True\n\ncommon codeRange\n  if flag(codeRange)\n    build-depends: haskell-language-server:hls-code-range-plugin\n    cpp-options: -Dhls_codeRange\n\nlibrary hls-code-range-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(codeRange)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.CodeRange\n    Ide.Plugin.CodeRange.Rules\n  other-modules:\n    Ide.Plugin.CodeRange.ASTPreProcess\n  hs-source-dirs: plugins/hls-code-range-plugin/src\n  build-depends:\n    , containers\n    , deepseq\n    , extra\n    , ghc\n    , ghcide           == 2.15.0.0\n    , hashable\n    , hls-plugin-api   == 2.15.0.0\n    , lens\n    , lsp\n    , mtl\n    , semigroupoids\n    , transformers\n    , vector\n\ntest-suite hls-code-range-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(codeRange)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-code-range-plugin/test\n  main-is:          Main.hs\n  other-modules:\n    Ide.Plugin.CodeRangeTest\n    Ide.Plugin.CodeRange.RulesTest\n  build-depends:\n    , bytestring\n    , filepath\n    , haskell-language-server:hls-code-range-plugin\n    , hls-test-utils             == 2.15.0.0\n    , lens\n    , lsp\n    , lsp-test\n    , transformers\n    , vector\n\n-----------------------------\n-- change type signature plugin\n-----------------------------\n\nflag changeTypeSignature\n  description: Enable changeTypeSignature plugin\n  default:     True\n  manual:      True\n\ncommon changeTypeSignature\n  if flag(changeTypeSignature)\n    build-depends: haskell-language-server:hls-change-type-signature-plugin\n    cpp-options: -Dhls_changeTypeSignature\n\nlibrary hls-change-type-signature-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(changeTypeSignature)\n    buildable: False\n  exposed-modules:  Ide.Plugin.ChangeTypeSignature\n  hs-source-dirs:   plugins/hls-change-type-signature-plugin/src\n  build-depends:\n    , ghcide           == 2.15.0.0\n    , hls-plugin-api   == 2.15.0.0\n    , lens\n    , lsp-types\n    , regex-tdfa\n    , syb\n    , text\n    , transformers\n    , containers\n    , ghc\n  default-extensions:\n    DataKinds\n    ExplicitNamespaces\n    OverloadedStrings\n    RecordWildCards\n\n\ntest-suite hls-change-type-signature-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(changeTypeSignature)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-change-type-signature-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-change-type-signature-plugin\n    , hls-test-utils       == 2.15.0.0\n    , regex-tdfa\n    , text\n  default-extensions:\n    OverloadedStrings\n    ViewPatterns\n\n-----------------------------\n-- gadt plugin\n-----------------------------\n\nflag gadt\n  description: Enable gadt plugin\n  default:     True\n  manual:      True\n\ncommon gadt\n  if flag(gadt)\n    build-depends: haskell-language-server:hls-gadt-plugin\n    cpp-options: -Dhls_gadt\n\nlibrary hls-gadt-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(gadt)\n    buildable: False\n  exposed-modules:  Ide.Plugin.GADT\n  other-modules:    Ide.Plugin.GHC\n  hs-source-dirs:   plugins/hls-gadt-plugin/src\n  build-depends:\n    , aeson\n    , containers\n    , extra\n    , ghc\n    , ghcide                 == 2.15.0.0\n    , ghc-exactprint\n    , hls-plugin-api         == 2.15.0.0\n    , haskell-language-server:hls-refactor-plugin\n    , lens\n    , lsp                    >=2.8\n    , mtl\n    , text\n    , transformers\n\n  default-extensions: DataKinds\n\ntest-suite hls-gadt-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(gadt)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-gadt-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-gadt-plugin\n    , hls-test-utils              == 2.15.0.0\n    , text\n\n-----------------------------\n-- explicit fixity plugin\n-----------------------------\n\nflag explicitFixity\n  description: Enable explicitFixity plugin\n  default:     True\n  manual:      True\n\ncommon explicitFixity\n  if flag(explicitFixity)\n    build-depends: haskell-language-server:hls-explicit-fixity-plugin\n    cpp-options: -DexplicitFixity\n\nlibrary hls-explicit-fixity-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(explicitFixity)\n    buildable: False\n  exposed-modules:  Ide.Plugin.ExplicitFixity\n  hs-source-dirs:   plugins/hls-explicit-fixity-plugin/src\n  build-depends:\n    , containers\n    , deepseq\n    , extra\n    , ghcide                == 2.15.0.0\n    , hashable\n    , hls-plugin-api        == 2.15.0.0\n    , lsp                   >=2.8\n    , text\n\n  default-extensions: DataKinds\n\ntest-suite hls-explicit-fixity-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(explicitFixity)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-explicit-fixity-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-explicit-fixity-plugin\n    , hls-test-utils              == 2.15.0.0\n    , text\n\n-----------------------------\n-- explicit fields plugin\n-----------------------------\n\nflag explicitFields\n  description: Enable explicitFields plugin\n  default:     True\n  manual:      True\n\ncommon explicitFields\n  if flag(explicitFields)\n    build-depends: haskell-language-server:hls-explicit-record-fields-plugin\n    cpp-options: -DexplicitFields\n\nlibrary hls-explicit-record-fields-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(explicitFields)\n    buildable: False\n  exposed-modules:  Ide.Plugin.ExplicitFields\n  build-depends:\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lsp\n    , lens\n    , hls-graph\n    , text\n    , syb\n    , transformers\n    , containers\n    , aeson\n  hs-source-dirs:   plugins/hls-explicit-record-fields-plugin/src\n\n  if flag(pedantic)\n    ghc-options: -Wwarn=incomplete-record-updates\n\ntest-suite hls-explicit-record-fields-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(explicitFields)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-explicit-record-fields-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , text\n    , ghcide\n    , haskell-language-server:hls-explicit-record-fields-plugin\n    , hls-test-utils              == 2.15.0.0\n\n-----------------------------\n-- overloaded record dot plugin\n-----------------------------\n\nflag overloadedRecordDot\n  description: Enable overloadedRecordDot plugin\n  default:     True\n  manual:      True\n\ncommon overloadedRecordDot\n  if flag(overloadedRecordDot)\n    build-depends: haskell-language-server:hls-overloaded-record-dot-plugin\n    cpp-options: -Dhls_overloaded_record_dot\n\nlibrary hls-overloaded-record-dot-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(overloadedRecordDot)\n    buildable: False\n  exposed-modules:  Ide.Plugin.OverloadedRecordDot\n  build-depends:\n    , aeson\n    , ghcide\n    , hls-plugin-api\n    , lsp\n    , lens\n    , hls-graph\n    , text\n    , syb\n    , transformers\n    , containers\n    , deepseq\n  hs-source-dirs:   plugins/hls-overloaded-record-dot-plugin/src\n\ntest-suite hls-overloaded-record-dot-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(overloadedRecordDot)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-overloaded-record-dot-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , text\n    , haskell-language-server:hls-overloaded-record-dot-plugin\n    , hls-test-utils              == 2.15.0.0\n\n\n-----------------------------\n-- fourmolu plugin\n-----------------------------\n\nflag fourmolu\n  description: Enable fourmolu plugin\n  default:     True\n  manual:      True\n\ncommon fourmolu\n  if flag(fourmolu)\n    build-depends: haskell-language-server:hls-fourmolu-plugin\n    cpp-options: -Dhls_fourmolu\n\nlibrary hls-fourmolu-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(fourmolu)\n    buildable: False\n  exposed-modules:  Ide.Plugin.Fourmolu\n  hs-source-dirs:   plugins/hls-fourmolu-plugin/src\n  build-depends:\n    , filepath\n    , fourmolu        ^>= 0.14 || ^>= 0.15 || ^>= 0.16 || ^>=0.17 || ^>=0.18 || ^>=0.19 || ^>=0.20\n    , ghc-boot-th\n    , ghcide          == 2.15.0.0\n    , hls-plugin-api  == 2.15.0.0\n    , lens\n    , lsp             ^>= 2.8\n    , mtl\n    , process-extras  >= 0.7.1\n    , text\n    , transformers\n    , yaml\n\ntest-suite hls-fourmolu-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(fourmolu)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-fourmolu-plugin/test\n  main-is:          Main.hs\n  -- Work around https://gitlab.haskell.org/ghc/ghc/-/issues/24648\n  if os(darwin)\n    ghc-options: -optl-Wl,-ld_classic\n  build-tool-depends:\n    fourmolu:fourmolu\n  build-depends:\n    , aeson\n    , containers\n    , filepath\n    , haskell-language-server:hls-fourmolu-plugin\n    , hls-plugin-api\n    , hls-test-utils       == 2.15.0.0\n    , lens\n    , lsp-test\n    , lsp-types\n    , text\n\n-----------------------------\n-- ormolu plugin\n-----------------------------\n\nflag ormolu\n  description: Enable ormolu plugin\n  default:     True\n  manual:      True\n\ncommon ormolu\n  if flag(ormolu)\n    build-depends: haskell-language-server:hls-ormolu-plugin\n    cpp-options: -Dhls_ormolu\n\nlibrary hls-ormolu-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(ormolu)\n    buildable: False\n  exposed-modules:  Ide.Plugin.Ormolu\n  hs-source-dirs:   plugins/hls-ormolu-plugin/src\n  build-depends:\n    , extra\n    , filepath\n    , ghc-boot-th\n    , ghcide          == 2.15.0.0\n    , hls-plugin-api  == 2.15.0.0\n    , lsp\n    , mtl\n    , process-extras  >= 0.7.1\n    , ormolu          ^>=0.5.3 || ^>= 0.6 || ^>= 0.7 || ^>=0.8\n    , text\n    , transformers\n\n\ntest-suite hls-ormolu-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(ormolu)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-ormolu-plugin/test\n  main-is:          Main.hs\n  -- Work around https://gitlab.haskell.org/ghc/ghc/-/issues/24648\n  if os(darwin)\n    ghc-options: -optl-Wl,-ld_classic\n  build-tool-depends:\n    ormolu:ormolu\n  build-depends:\n    , aeson\n    , containers\n    , filepath\n    , haskell-language-server:hls-ormolu-plugin\n    , hls-plugin-api\n    , hls-test-utils     == 2.15.0.0\n    , lens\n    , lsp-types\n    , ormolu\n    , text\n\n-----------------------------\n-- stylish-haskell plugin\n-----------------------------\n\nflag stylishHaskell\n  description: Enable stylishHaskell plugin\n  default:     True\n  manual:      True\n\ncommon stylishHaskell\n  -- stylish-haskell depends on ghc-lib-parser which doesn't support GHC 9.14\n  if flag(stylishHaskell) && !impl(ghc >= 9.14)\n    build-depends: haskell-language-server:hls-stylish-haskell-plugin\n    cpp-options: -Dhls_stylishHaskell\n\nlibrary hls-stylish-haskell-plugin\n  import:           defaults, pedantic, warnings\n  -- https://github.com/haskell/stylish-haskell/issues/479\n  -- stylish-haskell depends on ghc-lib-parser which doesn't support GHC 9.14\n  if !flag(stylishHaskell) || impl(ghc >= 9.14)\n    buildable: False\n  exposed-modules:  Ide.Plugin.StylishHaskell\n  hs-source-dirs:   plugins/hls-stylish-haskell-plugin/src\n  build-depends:\n    , directory\n    , filepath\n    , ghc-boot-th\n    , ghcide           == 2.15.0.0\n    , hls-plugin-api   == 2.15.0.0\n    , lsp-types\n    , mtl\n    , stylish-haskell  >=0.12 && <0.16\n    , text\n\n\ntest-suite hls-stylish-haskell-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  -- stylish-haskell depends on ghc-lib-parser which doesn't support GHC 9.14\n  if !flag(stylishHaskell) || impl(ghc >= 9.14)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-stylish-haskell-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-stylish-haskell-plugin\n    , hls-test-utils              == 2.15.0.0\n\n-----------------------------\n-- refactor plugin\n-----------------------------\n\nflag refactor\n  description: Enable refactor plugin\n  default:     True\n  manual:      True\n\ncommon refactor\n  if flag(refactor)\n    build-depends: haskell-language-server:hls-refactor-plugin\n    cpp-options: -Dhls_refactor\n\nlibrary hls-refactor-plugin\n  import:           defaults, pedantic, warnings\n  if !flag(refactor)\n    buildable: False\n  exposed-modules:  Development.IDE.GHC.ExactPrint\n                    Development.IDE.GHC.Compat.ExactPrint\n                    Development.IDE.Plugin.CodeAction\n                    Development.IDE.Plugin.CodeAction.Util\n                    Development.IDE.GHC.Dump\n  other-modules:    Development.IDE.Plugin.CodeAction.Args\n                    Development.IDE.Plugin.CodeAction.ExactPrint\n                    Development.IDE.Plugin.CodeAction.PositionIndexed\n                    Development.IDE.Plugin.Plugins.AddArgument\n                    Development.IDE.Plugin.Plugins.Diagnostic\n                    Development.IDE.Plugin.Plugins.FillHole\n                    Development.IDE.Plugin.Plugins.FillTypeWildcard\n                    Development.IDE.Plugin.Plugins.ImportUtils\n  default-extensions:\n    CPP\n    DataKinds\n    DerivingStrategies\n    DerivingVia\n    DuplicateRecordFields\n    ExplicitNamespaces\n    FunctionalDependencies\n    LambdaCase\n    OverloadedStrings\n    PatternSynonyms\n    RecordWildCards\n    ViewPatterns\n  hs-source-dirs:   plugins/hls-refactor-plugin/src\n  build-depends:\n    , ghc\n    , bytestring\n    , ghc-boot\n    , regex-tdfa\n    , ghcide                == 2.15.0.0\n    , haskell-language-server:hls-exactprint-utils\n    , hls-plugin-api        == 2.15.0.0\n    , lsp\n    , text\n    , text-rope\n    , transformers\n    , unordered-containers\n    , containers\n    , ghc-exactprint < 1 || >= 1.4\n    , extra\n    , syb\n    , hls-graph\n    , dlist\n    , deepseq\n    , mtl\n    , lens\n    , time\n  if impl(ghc < 9.10)\n    build-depends: data-default\n\ntest-suite hls-refactor-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(refactor)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-refactor-plugin/test\n  main-is:          Main.hs\n  other-modules:    Test.AddArgument\n  ghc-options:      -O0\n  build-depends:\n    , data-default\n    , directory\n    , extra\n    , filepath\n    , ghcide:ghcide\n    , haskell-language-server:hls-refactor-plugin\n    , hls-test-utils      == 2.15.0.0\n    , lens\n    , lsp-test\n    , lsp-types\n    , parser-combinators\n    , regex-tdfa\n    , shake\n    , tasty\n    , tasty-hunit\n    , text\n\n-----------------------------\n-- semantic tokens plugin\n-----------------------------\n\nflag semanticTokens\n  description: Enable semantic tokens plugin\n  default:     True\n  manual:      True\n\ncommon semanticTokens\n  if flag(semanticTokens)\n    build-depends: haskell-language-server:hls-semantic-tokens-plugin\n    cpp-options: -Dhls_semanticTokens\n\nlibrary hls-semantic-tokens-plugin\n  import: defaults, pedantic, warnings\n  if !flag(semanticTokens)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.SemanticTokens\n    Ide.Plugin.SemanticTokens.Types\n    Ide.Plugin.SemanticTokens.Mappings\n  other-modules:\n    Ide.Plugin.SemanticTokens.Query\n    Ide.Plugin.SemanticTokens.SemanticConfig\n    Ide.Plugin.SemanticTokens.Utils\n    Ide.Plugin.SemanticTokens.Tokenize\n    Ide.Plugin.SemanticTokens.Internal\n\n  hs-source-dirs:     plugins/hls-semantic-tokens-plugin/src\n  build-depends:\n    , containers\n    , extra\n    , text-rope\n    , mtl                   >= 2.2\n    , ghc\n    , ghcide                == 2.15.0.0\n    , hls-plugin-api        == 2.15.0.0\n    , lens\n    , lsp                    >=2.8\n    , text\n    , transformers\n    , bytestring\n    , array\n    , deepseq\n    , dlist\n    , hls-graph == 2.15.0.0\n    , template-haskell\n    , data-default\n    , stm\n    , stm-containers\n\n  default-extensions: DataKinds\n\ntest-suite hls-semantic-tokens-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(semanticTokens)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-semantic-tokens-plugin/test\n  main-is:          SemanticTokensTest.hs\n\n  build-depends:\n    , aeson\n    , containers\n    , data-default\n    , filepath\n    , ghcide                == 2.15.0.0\n    , haskell-language-server:hls-semantic-tokens-plugin\n    , hls-plugin-api        == 2.15.0.0\n    , hls-test-utils        == 2.15.0.0\n    , lens\n    , lsp\n    , lsp-test\n    , text\n    , text-rope\n\n-----------------------------\n-- notes plugin\n-----------------------------\n\nflag notes\n  description: Enable notes plugin\n  default:     True\n  manual:      True\n\ncommon notes\n  if flag(notes)\n    build-depends: haskell-language-server:hls-notes-plugin\n    cpp-options: -Dhls_notes\n\nlibrary hls-notes-plugin\n  import: defaults, pedantic, warnings\n  if !flag(notes)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Notes\n  hs-source-dirs:     plugins/hls-notes-plugin/src\n  build-depends:\n    , array\n    , ghcide == 2.15.0.0\n    , hls-graph == 2.15.0.0\n    , hls-plugin-api == 2.15.0.0\n    , lens\n    , lsp >=2.8\n    , mtl >= 2.2\n    , regex-tdfa >= 1.3.1\n    , text\n    , text-rope\n    , unordered-containers\n  default-extensions:\n      DataKinds\n    , DeriveAnyClass\n    , DerivingStrategies\n    , OverloadedStrings\n    , LambdaCase\n    , TypeFamilies\n\ntest-suite hls-notes-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(notes)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-notes-plugin/test\n  main-is:          NotesTest.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-notes-plugin\n    , hls-test-utils == 2.15.0.0\n  default-extensions: OverloadedStrings\n\n-----------------------------\n-- export plugin\n-----------------------------\n\nlibrary hls-exactprint-utils\n  import: defaults, pedantic, warnings\n  exposed-modules:\n    Development.IDE.GHC.ExactPrint.Annotation\n    Development.IDE.GHC.ExactPrint.CPP\n  hs-source-dirs:     hls-exactprint-utils/src\n  build-depends:\n    , ghc\n    , ghc-exactprint\n    , ghcide          == 2.15.0.0\n    , lsp             >=2.8\n    , text\n    , text-rope\n  default-extensions:\n      CPP\n\nflag export\n  description: Enable export plugin\n  default:     True\n  manual:      True\n\ncommon export\n  if flag(export)\n    build-depends: haskell-language-server:hls-export-plugin\n    cpp-options: -Dhls_export\n\nlibrary hls-export-plugin\n  import: defaults, pedantic, warnings\n  if !flag(export)\n    buildable: False\n  exposed-modules:\n    Ide.Plugin.Export\n  other-modules:\n    Ide.Plugin.Export.Cursor\n    Ide.Plugin.Export.ExactPrint\n    Ide.Plugin.Export.Exports\n    Ide.Plugin.Export.Utils\n  hs-source-dirs:     plugins/hls-export-plugin/src\n  default-language:   GHC2021\n  build-depends:\n    , containers\n    , ghc\n    , ghc-boot-th\n    , ghc-exactprint\n    , ghcide          == 2.15.0.0\n    , haskell-language-server:hls-exactprint-utils\n    , hls-plugin-api  == 2.15.0.0\n    , lens\n    , lsp >=2.8\n    , stm\n    , text\n    , text-rope\n  default-extensions:\n    , DataKinds\n    , LambdaCase\n    , OverloadedStrings\n\ntest-suite hls-export-plugin-tests\n  import:           defaults, pedantic, test-defaults, warnings\n  if !flag(export)\n    buildable: False\n  type:             exitcode-stdio-1.0\n  hs-source-dirs:   plugins/hls-export-plugin/test\n  main-is:          Main.hs\n  build-depends:\n    , filepath\n    , haskell-language-server:hls-export-plugin\n    , hls-test-utils == 2.15.0.0\n    , lens\n    , lsp-types\n    , text\n  default-extensions: OverloadedStrings\n\n----------------------------\n----------------------------\n-- HLS\n----------------------------\n----------------------------\n\nlibrary\n  import:           defaults\n                  , warnings\n                  , pedantic\n                  -- plugins\n                  , cabal\n                  , callHierarchy\n                  , cabalfmt\n                  , cabalgild\n                  , changeTypeSignature\n                  , class\n                  , eval\n                  , importLens\n                  , caseSplit\n                  , rename\n                  , hlint\n                  , stan\n                  , signatureHelp\n                  , pragmas\n                  , splice\n                  , alternateNumberFormat\n                  , qualifyImportedNames\n                  , codeRange\n                  , gadt\n                  , explicitFixity\n                  , explicitFields\n                  , fourmolu\n                  , ormolu\n                  , stylishHaskell\n                  , refactor\n                  , overloadedRecordDot\n                  , semanticTokens\n                  , notes\n                  , export\n\n  exposed-modules:\n    Ide.Arguments\n    Ide.Main\n    Ide.Version\n    HlsPlugins\n\n  other-modules:    Paths_haskell_language_server\n  autogen-modules:  Paths_haskell_language_server\n  hs-source-dirs:   src\n  build-depends:\n    , aeson-pretty\n    , data-default\n    , directory\n    , extra\n    , filepath\n    , ghc\n    , ghcide                == 2.15.0.0\n    , githash               >=0.1.6.1\n    , hie-bios\n    , hls-plugin-api        == 2.15.0.0\n    , optparse-applicative\n    , optparse-simple\n    , prettyprinter         >= 1.7\n    , process\n    , text\n\n  default-extensions: DataKinds\n\nexecutable haskell-language-server\n  import:           defaults\n                  , warnings\n                  , pedantic\n  main-is:          Main.hs\n  hs-source-dirs:   exe\n\n  ghc-options:\n    -threaded\n    -- allow user RTS overrides\n    -rtsopts\n    -- disable idle GC\n    -- increase nursery size\n    -- Enable collection of heap statistics\n    \"-with-rtsopts=-I0 -A128M -T\"\n  if flag(pedantic)\n    ghc-options: -Werror\n  if !os(windows) && flag(dynamic)\n  -- We want to link against the dyn rts just like official GHC binaries do;\n  --   the linked rts determines how external libs are loaded dynamically by TH.\n  -- The standard way of doing this is via the --enable-dynamic-executables Cabal option\n  -- Unfortunately it doesnt' work, see https://github.com/haskell/haskell-language-server/issues/2659\n  -- One can use --ghc-options=-dynamic but this gets applied to the dependencies as well,\n  -- which results in massive rebuilds and incompatibilities with profiling.\n  -- So instead we set the -dynamic flag diretly here.\n    ghc-options: -dynamic\n\n  build-depends:\n    , haskell-language-server\n    , hls-plugin-api\n    , lsp\n    , prettyprinter           >= 1.7\n    , text\n\n  default-extensions: DataKinds\n\nexecutable haskell-language-server-wrapper\n  import:           defaults\n                  , warnings\n                  , pedantic\n  main-is:          Wrapper.hs\n  hs-source-dirs:   exe\n  other-modules:    Paths_haskell_language_server\n  autogen-modules:  Paths_haskell_language_server\n  ghc-options:\n    -threaded\n    -- allow user RTS overrides\n    -rtsopts\n    -- disable idle GC\n    -- increase nursery size\n    \"-with-rtsopts=-I0 -A128M\"\n\n  build-depends:\n    , data-default\n    , directory\n    , extra\n    , filepath\n    , ghcide\n    , haskell-language-server\n    , hie-bios\n    , hls-plugin-api\n    , lsp\n    , lsp-types\n    , text\n    , transformers\n    , unliftio-core\n  if !os(windows)\n      build-depends:\n        , unix\n        , containers\n  else\n      build-depends:\n        , process\n\ntest-suite func-test\n  import:             defaults\n                    , test-defaults\n                    , warnings\n                    , pedantic\n                    , refactor\n  type:               exitcode-stdio-1.0\n  build-tool-depends:\n    haskell-language-server:haskell-language-server,\n\n  build-depends:\n    , aeson\n    , bytestring\n    , containers\n    , deepseq\n    , extra\n    , filepath\n    , ghcide:ghcide\n    , hashable\n    , hls-plugin-api\n    , hls-test-utils == 2.15.0.0\n    , lens\n    , lsp-test\n    , lsp-types\n    , text\n    , unordered-containers\n\n  hs-source-dirs:     test/functional test/utils\n\n  main-is:            Main.hs\n  other-modules:\n    Config\n    ConfigSchema\n    Format\n    FunctionalBadProject\n    HieBios\n    Progress\n    Test.Hls.Command\n    Test.Hls.Flags\n\n  default-extensions: OverloadedStrings\n\n-- Duplicating inclusion plugin conditions until tests are moved to their own packages\n  if flag(eval)\n    cpp-options: -Dhls_eval\n-- formatters\n  if flag(fourmolu) && (impl(ghc < 9.14) || flag(ignore-plugins-ghc-bounds))\n    cpp-options: -Dhls_fourmolu\n  if flag(ormolu) && (impl(ghc < 9.14) || flag(ignore-plugins-ghc-bounds))\n    cpp-options: -Dhls_ormolu\n\ntest-suite wrapper-test\n  import:             defaults\n                    , warnings\n                    , pedantic\n  type:               exitcode-stdio-1.0\n  build-tool-depends:\n    haskell-language-server:haskell-language-server-wrapper,\n    haskell-language-server:haskell-language-server\n\n  build-depends:\n    , extra\n    , hls-test-utils              == 2.15.0.0\n    , process\n\n  hs-source-dirs:     test/wrapper\n  main-is:            Main.hs\n\nbenchmark benchmark\n    import:           defaults, warnings\n    -- Depends on shake-bench which is unbuildable after this point\n    type: exitcode-stdio-1.0\n    ghc-options: -threaded\n    main-is: Main.hs\n    hs-source-dirs: bench\n    build-tool-depends:\n        haskell-language-server:ghcide-bench\n    default-extensions:\n        LambdaCase\n        RecordWildCards\n        ViewPatterns\n\n    build-depends:\n      , aeson\n      , containers\n      , data-default\n      , directory\n      , extra\n      , filepath\n      , haskell-language-server:ghcide-bench-lib\n      , haskell-language-server\n      , hls-plugin-api\n      , lens\n      , lens-aeson\n      , shake\n      , shake-bench == 0.2.*\n      , text\n      , yaml\n\nflag test-exe\n  description: Build the ghcide-test-preprocessor executable\n  default:     True\n\nexecutable ghcide-test-preprocessor\n  import: warnings\n  default-language:   GHC2021\n  hs-source-dirs:   ghcide-test/preprocessor\n  main-is:          Main.hs\n  build-depends:    base >=4 && <5\n\n  if !flag(test-exe)\n    buildable: False\n\ntest-suite ghcide-tests\n  import: warnings, defaults\n  type:               exitcode-stdio-1.0\n  default-language:   GHC2021\n  build-tool-depends:\n    , ghcide:ghcide\n    , haskell-language-server:ghcide-test-preprocessor\n    , implicit-hie:gen-hie\n\n  build-depends:\n    , aeson\n    , containers\n    , data-default\n    , directory\n    , enummapset\n    , extra\n    , filepath\n    , ghc\n    , ghcide\n    , hls-plugin-api\n    , lens\n    , list-t\n    , lsp\n    , lsp-test                ^>=0.18.0\n    , lsp-types\n    , mtl\n    , network-uri\n    , QuickCheck\n    , random\n    , regex-tdfa              ^>=1.3.1\n    , shake\n    , sqlite-simple\n    , stm\n    , stm-containers\n    , tasty\n    , tasty-expected-failure\n    , tasty-hunit             >=0.10\n    , tasty-quickcheck\n    , tasty-rerun\n    , text\n    , text-rope\n    , unordered-containers\n    , hls-test-utils == 2.15.0.0\n\n  if impl(ghc <9.3)\n    build-depends: ghc-typelits-knownnat\n\n  hs-source-dirs:     ghcide-test/exe\n  ghc-options:        -threaded -O0\n\n  main-is:            Main.hs\n  other-modules:\n    Config\n    AsyncTests\n    BootTests\n    ClientSettingsTests\n    CodeLensTests\n    CompletionTests\n    ConstructorHoverTests\n    CPPTests\n    CradleTests\n    DependentFileTest\n    DiagnosticTests\n    EpsPollutionTests\n    ExceptionTests\n    FindDefinitionAndHoverTests\n    FindImplementationAndHoverTests\n    FuzzySearch\n    GarbageCollectionTests\n    HaddockTests\n    HieDbRetry\n    HighlightTests\n    Hover\n    IfaceTests\n    InitializeResponseTests\n    LogType\n    NonLspCommandLine\n    OpenCloseTest\n    OutlineTests\n    PluginSimpleTests\n    PositionMappingTests\n    PreprocessorTests\n    Progress\n    ReferenceTests\n    ResolveTests\n    RootUriTests\n    SafeTests\n    SymlinkTests\n    THTests\n    UnitTests\n    WatchedFileTests\n\n  -- Tests that have been pulled out of the main file\n  default-extensions:\n    LambdaCase\n    OverloadedStrings\n    RecordWildCards\n    ViewPatterns\n\nflag ghcide-bench\n  description: Build the ghcide-bench executable\n  default:     True\n\nexecutable ghcide-bench\n    import: defaults\n    if !flag(ghcide-bench)\n      buildable: False\n    build-depends:\n        aeson,\n        bytestring,\n        containers,\n        data-default,\n        extra,\n        filepath,\n        hls-plugin-api,\n        hls-test-utils,\n        lens,\n        lsp-test,\n        lsp-types,\n        optparse-applicative,\n        process,\n        safe-exceptions,\n        hls-graph,\n        shake,\n        tasty-hunit >= 0.10,\n        text,\n        haskell-language-server:ghcide-bench-lib,\n    hs-source-dirs: ghcide-bench/exe\n    ghc-options: -threaded -Wall -Wno-name-shadowing -rtsopts\n    main-is: Main.hs\n    default-extensions:\n        LambdaCase\n        OverloadedStrings\n        RecordWildCards\n        ViewPatterns\n\nlibrary ghcide-bench-lib\n    import: defaults\n    hs-source-dirs: ghcide-bench/src\n    ghc-options: -Wall -Wno-name-shadowing\n    exposed-modules:\n        Experiments.Types\n        Experiments\n    build-depends:\n        aeson,\n        async,\n        binary,\n        bytestring,\n        deepseq,\n        directory,\n        extra,\n        filepath,\n        ghcide:{ghcide},\n        hashable,\n        lens,\n        lsp-test,\n        lsp-types,\n        optparse-applicative,\n        parser-combinators,\n        process,\n        safe-exceptions,\n        shake,\n        table-layout,\n        text,\n        hls-test-utils,\n        row-types\n    default-extensions:\n        LambdaCase\n        RecordWildCards\n        ViewPatterns\n\n\ntest-suite ghcide-bench-test\n    import: defaults\n    type: exitcode-stdio-1.0\n    build-tool-depends:\n        ghcide:ghcide,\n    main-is: Main.hs\n    hs-source-dirs: ghcide-bench/test\n    ghc-options: -Wunused-packages\n    ghc-options: -threaded -Wall\n    build-depends:\n        extra,\n        haskell-language-server:ghcide-bench-lib,\n        lsp-test ^>= 0.18,\n        tasty,\n        tasty-hunit >= 0.10,\n        tasty-rerun\n    default-extensions:\n        LambdaCase\n        OverloadedStrings\n        RecordWildCards\n        ViewPatterns\n\nflag plugin-tutorial\n  description: Build the plugin tutorial executable\n  default:     True\n  manual:      True\n\nexecutable plugin-tutorial\n  import: defaults\n  -- The plugin tutorial is only compatible with 9.6 and 9.8.\n  -- No particular reason, just to avoid excessive CPP.\n  if flag(plugin-tutorial) && (impl(ghc >= 9.6) && impl(ghc < 9.10))\n    buildable: True\n  else\n    buildable: False\n  ghc-options: -pgmL markdown-unlit\n  main-is: docs/contributing/plugin-tutorial.lhs\n  build-tool-depends: markdown-unlit:markdown-unlit\n  build-depends:\n    base,\n    ghcide,\n    hls-plugin-api,\n    aeson,\n    lsp,\n    lsp-types,\n    markdown-unlit,\n    text,\n    unordered-containers,\n    containers,\n    transformers,\n    ghc,\n";
  }