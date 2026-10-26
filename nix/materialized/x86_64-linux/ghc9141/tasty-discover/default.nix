{
  pkgs = hackage:
    {
      packages = {
        filepath.revision = hackage.filepath."1.5.4.0".revisions.default;
        tasty.revision = import ./cabal-files/tasty.nix;
        tasty.flags.terminal-size = true;
        tasty.flags.unix = true;
        stm.revision = hackage.stm."2.5.3.1".revisions.default;
        transformers.revision = hackage.transformers."0.6.1.2".revisions.default;
        deepseq.revision = hackage.deepseq."1.5.1.0".revisions.default;
        optparse-applicative.revision = import ./cabal-files/optparse-applicative.nix;
        optparse-applicative.flags.process = true;
        directory.revision = hackage.directory."1.3.10.0".revisions.default;
        file-io.revision = hackage.file-io."0.1.5".revisions.default;
        mtl.revision = hackage.mtl."2.3.1".revisions.default;
        ansi-terminal-types.revision = import ./cabal-files/ansi-terminal-types.nix;
        process.revision = hackage.process."1.6.26.1".revisions.default;
        base.revision = hackage.base."4.22.0.0".revisions.default;
        text.revision = hackage.text."2.1.3".revisions.default;
        time.revision = hackage.time."1.15".revisions.default;
        array.revision = hackage.array."0.5.8.0".revisions.default;
        terminal-size.revision = import ./cabal-files/terminal-size.nix;
        ghc-internal.revision = hackage.ghc-internal."9.1401.0".revisions.default;
        binary.revision = hackage.binary."0.8.9.3".revisions.default;
        template-haskell.revision = hackage.template-haskell."2.24.0.0".revisions.default;
        unix.revision = hackage.unix."2.8.8.0".revisions.default;
        ansi-terminal.revision = import ./cabal-files/ansi-terminal.nix;
        ansi-terminal.flags.example = false;
        hsc2hs.revision = import ./cabal-files/hsc2hs.nix;
        hsc2hs.flags.in-ghc-tree = false;
        colour.revision = import ./cabal-files/colour.nix;
        exceptions.revision = hackage.exceptions."0.10.11".revisions.default;
        bytestring.revision = hackage.bytestring."0.12.2.0".revisions.default;
        tagged.revision = import ./cabal-files/tagged.nix;
        tagged.flags.deepseq = true;
        ghc-boot-th.revision = hackage.ghc-boot-th."9.14.1".revisions.default;
        Glob.revision = import ./cabal-files/Glob.nix;
        os-string.revision = hackage.os-string."2.0.8".revisions.default;
        transformers-compat.revision = import ./cabal-files/transformers-compat.nix;
        transformers-compat.flags.five-three = true;
        transformers-compat.flags.mtl = true;
        transformers-compat.flags.generic-deriving = true;
        transformers-compat.flags.five = false;
        prettyprinter.revision = import ./cabal-files/prettyprinter.nix;
        prettyprinter.flags.buildreadme = false;
        prettyprinter.flags.text = true;
        ghc-prim.revision = hackage.ghc-prim."0.13.1".revisions.default;
        pretty.revision = hackage.pretty."1.1.3.6".revisions.default;
        containers.revision = hackage.containers."0.8".revisions.default;
        prettyprinter-ansi-terminal.revision = import ./cabal-files/prettyprinter-ansi-terminal.nix;
        prettyprinter-ansi-terminal.flags.text = true;
        tasty-discover.revision = import ./cabal-files/tasty-discover.nix;
        tasty-discover.flags.dev = false;
        rts.revision = hackage.rts."1.0.3".revisions.default;
        dlist.revision = import ./cabal-files/dlist.nix;
        dlist.flags.werror = false;
      };
      compiler = {
        version = "9.14.1";
        nix-name = "ghc9141";
        packages = {
          "ghc-boot-th" = "9.14.1";
          "binary" = "0.8.9.3";
          "pretty" = "1.1.3.6";
          "array" = "0.5.8.0";
          "time" = "1.15";
          "file-io" = "0.1.5";
          "ghc-prim" = "0.13.1";
          "bytestring" = "0.12.2.0";
          "process" = "1.6.26.1";
          "mtl" = "2.3.1";
          "text" = "2.1.3";
          "template-haskell" = "2.24.0.0";
          "stm" = "2.5.3.1";
          "filepath" = "1.5.4.0";
          "os-string" = "2.0.8";
          "rts" = "1.0.3";
          "unix" = "2.8.8.0";
          "exceptions" = "0.10.11";
          "deepseq" = "1.5.1.0";
          "transformers" = "0.6.1.2";
          "containers" = "0.8";
          "ghc-internal" = "9.1401.0";
          "base" = "4.22.0.0";
          "directory" = "1.3.10.0";
        };
      };
    };
  extras = hackage:
    { packages = {}; };
  modules = [
    {
      preExistingPkgs = [
        "filepath"
        "stm"
        "transformers"
        "deepseq"
        "directory"
        "file-io"
        "mtl"
        "process"
        "base"
        "text"
        "time"
        "array"
        "ghc-internal"
        "binary"
        "template-haskell"
        "unix"
        "exceptions"
        "bytestring"
        "ghc-boot-th"
        "os-string"
        "ghc-prim"
        "pretty"
        "containers"
        "rts"
      ];
    }
    ({ lib, ... }:
      { packages = {}; })
    ({ lib, ... }:
      {
        packages = {
          "file-io".components.library.planned = lib.mkOverride 900 true;
          "template-haskell".components.library.planned = lib.mkOverride 900 true;
          "transformers".components.library.planned = lib.mkOverride 900 true;
          "Glob".components.library.planned = lib.mkOverride 900 true;
          "array".components.library.planned = lib.mkOverride 900 true;
          "unix".components.library.planned = lib.mkOverride 900 true;
          "exceptions".components.library.planned = lib.mkOverride 900 true;
          "directory".components.library.planned = lib.mkOverride 900 true;
          "containers".components.library.planned = lib.mkOverride 900 true;
          "dlist".components.library.planned = lib.mkOverride 900 true;
          "tasty-discover".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter".components.library.planned = lib.mkOverride 900 true;
          "transformers-compat".components.library.planned = lib.mkOverride 900 true;
          "stm".components.library.planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          "bytestring".components.library.planned = lib.mkOverride 900 true;
          "colour".components.library.planned = lib.mkOverride 900 true;
          "deepseq".components.library.planned = lib.mkOverride 900 true;
          "optparse-applicative".components.library.planned = lib.mkOverride 900 true;
          "tagged".components.library.planned = lib.mkOverride 900 true;
          "filepath".components.library.planned = lib.mkOverride 900 true;
          "ghc-internal".components.library.planned = lib.mkOverride 900 true;
          "time".components.library.planned = lib.mkOverride 900 true;
          "pretty".components.library.planned = lib.mkOverride 900 true;
          "os-string".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter-ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "mtl".components.library.planned = lib.mkOverride 900 true;
          "binary".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal-types".components.library.planned = lib.mkOverride 900 true;
          "tasty-discover".components.exes."tasty-discover".planned = lib.mkOverride 900 true;
          "ghc-boot-th".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "hsc2hs".components.exes."hsc2hs".planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "process".components.library.planned = lib.mkOverride 900 true;
          "terminal-size".components.library.planned = lib.mkOverride 900 true;
          "tasty".components.library.planned = lib.mkOverride 900 true;
          "text".components.library.planned = lib.mkOverride 900 true;
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
        };
      })
  ];
}