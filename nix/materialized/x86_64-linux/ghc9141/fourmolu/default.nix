{
  pkgs = hackage:
    {
      packages = {
        MemoTrie.revision = import ./cabal-files/MemoTrie.nix;
        MemoTrie.flags.examples = false;
        conduit.revision = import ./cabal-files/conduit.nix;
        filepath.revision = hackage.filepath."1.5.4.0".revisions.default;
        attoparsec.revision = import ./cabal-files/attoparsec.nix;
        attoparsec.flags.developer = false;
        text-iso8601.revision = import ./cabal-files/text-iso8601.nix;
        yaml.revision = import ./cabal-files/yaml.nix;
        yaml.flags.no-exe = true;
        yaml.flags.no-examples = true;
        unordered-containers.revision = import ./cabal-files/unordered-containers.nix;
        unordered-containers.flags.debug = false;
        case-insensitive.revision = import ./cabal-files/case-insensitive.nix;
        OneTuple.revision = import ./cabal-files/OneTuple.nix;
        OneTuple.flags.base-ge-4-15 = true;
        OneTuple.flags.base-ge-4-16 = true;
        tasty.revision = import ./cabal-files/tasty.nix;
        tasty.flags.terminal-size = true;
        tasty.flags.unix = true;
        data-fix.revision = import ./cabal-files/data-fix.nix;
        uuid-types.revision = import ./cabal-files/uuid-types.nix;
        vector-stream.revision = import ./cabal-files/vector-stream.nix;
        comonad.revision = import ./cabal-files/comonad.nix;
        comonad.flags.containers = true;
        comonad.flags.indexed-traversable = true;
        comonad.flags.distributive = true;
        ghc-bignum.revision = hackage.ghc-bignum."1.4".revisions.default;
        stm.revision = hackage.stm."2.5.3.1".revisions.default;
        integer-conversion.revision = import ./cabal-files/integer-conversion.nix;
        transformers.revision = hackage.transformers."0.6.1.2".revisions.default;
        distributive.revision = import ./cabal-files/distributive.nix;
        distributive.flags.tagged = true;
        deepseq.revision = hackage.deepseq."1.5.1.0".revisions.default;
        optparse-applicative.revision = import ./cabal-files/optparse-applicative.nix;
        optparse-applicative.flags.process = true;
        split.revision = import ./cabal-files/split.nix;
        directory.revision = hackage.directory."1.3.10.0".revisions.default;
        file-io.revision = hackage.file-io."0.1.5".revisions.default;
        file-embed.revision = import ./cabal-files/file-embed.nix;
        parsec.revision = hackage.parsec."3.1.18.0".revisions.default;
        strict.revision = import ./cabal-files/strict.nix;
        th-abstraction.revision = import ./cabal-files/th-abstraction.nix;
        Diff.revision = import ./cabal-files/Diff.nix;
        parser-combinators.revision = import ./cabal-files/parser-combinators.nix;
        parser-combinators.flags.dev = false;
        mtl.revision = hackage.mtl."2.3.1".revisions.default;
        ansi-terminal-types.revision = import ./cabal-files/ansi-terminal-types.nix;
        process.revision = hackage.process."1.6.26.1".revisions.default;
        base.revision = hackage.base."4.22.0.0".revisions.default;
        choice.revision = import ./cabal-files/choice.nix;
        base-orphans.revision = import ./cabal-files/base-orphans.nix;
        QuickCheck.revision = import ./cabal-files/QuickCheck.nix;
        QuickCheck.flags.old-random = false;
        QuickCheck.flags.templatehaskell = true;
        Cabal-syntax.revision = hackage.Cabal-syntax."3.16.0.0".revisions.default;
        network-uri.revision = import ./cabal-files/network-uri.nix;
        indexed-traversable-instances.revision = import ./cabal-files/indexed-traversable-instances.nix;
        bitvec.revision = import ./cabal-files/bitvec.nix;
        bitvec.flags.simd = true;
        these.revision = import ./cabal-files/these.nix;
        random.revision = import ./cabal-files/random.nix;
        async.revision = import ./cabal-files/async.nix;
        async.flags.bench = false;
        async.flags.debug-auto-label = false;
        bifunctors.revision = import ./cabal-files/bifunctors.nix;
        bifunctors.flags.tagged = true;
        text.revision = hackage.text."2.1.3".revisions.default;
        newtype-generics.revision = import ./cabal-files/newtype-generics.nix;
        safe-exceptions.revision = import ./cabal-files/safe-exceptions.nix;
        time.revision = hackage.time."1.15".revisions.default;
        array.revision = hackage.array."0.5.8.0".revisions.default;
        terminal-size.revision = import ./cabal-files/terminal-size.nix;
        vector-algorithms.revision = import ./cabal-files/vector-algorithms.nix;
        vector-algorithms.flags.bench = true;
        vector-algorithms.flags.internalchecks = false;
        vector-algorithms.flags.boundschecks = true;
        vector-algorithms.flags.unsafechecks = false;
        vector-algorithms.flags.llvm = false;
        semialign.revision = import ./cabal-files/semialign.nix;
        semialign.flags.semigroupoids = true;
        text-short.revision = import ./cabal-files/text-short.nix;
        text-short.flags.asserts = false;
        semigroupoids.revision = import ./cabal-files/semigroupoids.nix;
        semigroupoids.flags.unordered-containers = true;
        semigroupoids.flags.containers = true;
        semigroupoids.flags.comonad = true;
        semigroupoids.flags.tagged = true;
        semigroupoids.flags.contravariant = true;
        contravariant.revision = import ./cabal-files/contravariant.nix;
        contravariant.flags.statevar = true;
        StateVar.revision = import ./cabal-files/StateVar.nix;
        megaparsec.revision = import ./cabal-files/megaparsec.nix;
        megaparsec.flags.dev = false;
        unliftio-core.revision = import ./cabal-files/unliftio-core.nix;
        resourcet.revision = import ./cabal-files/resourcet.nix;
        mono-traversable.revision = import ./cabal-files/mono-traversable.nix;
        happy.revision = import ./cabal-files/happy.nix;
        indexed-traversable.revision = import ./cabal-files/indexed-traversable.nix;
        indexed-traversable.flags.base-ge-4-18 = true;
        hashable.revision = import ./cabal-files/hashable.nix;
        hashable.flags.random-initial-seed = false;
        hashable.flags.arch-native = false;
        character-ps.revision = import ./cabal-files/character-ps.nix;
        th-compat.revision = import ./cabal-files/th-compat.nix;
        hpc.revision = hackage.hpc."0.7.0.2".revisions.default;
        syb.revision = import ./cabal-files/syb.nix;
        ghc-internal.revision = hackage.ghc-internal."9.1401.0".revisions.default;
        alex.revision = import ./cabal-files/alex.nix;
        binary.revision = hackage.binary."0.8.9.3".revisions.default;
        template-haskell.revision = hackage.template-haskell."2.24.0.0".revisions.default;
        unix.revision = hackage.unix."2.8.8.0".revisions.default;
        primitive.revision = import ./cabal-files/primitive.nix;
        aeson.revision = import ./cabal-files/aeson.nix;
        aeson.flags.ordered-keymap = true;
        ansi-terminal.revision = import ./cabal-files/ansi-terminal.nix;
        ansi-terminal.flags.example = false;
        hsc2hs.revision = import ./cabal-files/hsc2hs.nix;
        hsc2hs.flags.in-ghc-tree = false;
        colour.revision = import ./cabal-files/colour.nix;
        exceptions.revision = hackage.exceptions."0.10.11".revisions.default;
        bytestring.revision = hackage.bytestring."0.12.2.0".revisions.default;
        witherable.revision = import ./cabal-files/witherable.nix;
        unliftio.revision = import ./cabal-files/unliftio.nix;
        integer-logarithms.revision = import ./cabal-files/integer-logarithms.nix;
        integer-logarithms.flags.integer-gmp = true;
        integer-logarithms.flags.check-bounds = false;
        time-compat.revision = import ./cabal-files/time-compat.nix;
        tagged.revision = import ./cabal-files/tagged.nix;
        tagged.flags.template-haskell = true;
        tagged.flags.deepseq = true;
        ghc-boot-th.revision = hackage.ghc-boot-th."9.14.1".revisions.default;
        os-string.revision = hackage.os-string."2.0.8".revisions.default;
        transformers-compat.revision = import ./cabal-files/transformers-compat.nix;
        transformers-compat.flags.five-three = true;
        transformers-compat.flags.mtl = true;
        transformers-compat.flags.generic-deriving = true;
        transformers-compat.flags.five = false;
        prettyprinter.revision = import ./cabal-files/prettyprinter.nix;
        prettyprinter.flags.buildreadme = false;
        prettyprinter.flags.text = true;
        assoc.revision = import ./cabal-files/assoc.nix;
        assoc.flags.tagged = false;
        ghc-prim.revision = hackage.ghc-prim."0.13.1".revisions.default;
        happy-lib.revision = import ./cabal-files/happy-lib.nix;
        pretty.revision = hackage.pretty."1.1.3.6".revisions.default;
        splitmix.revision = import ./cabal-files/splitmix.nix;
        splitmix.flags.optimised-mixer = false;
        containers.revision = hackage.containers."0.8".revisions.default;
        prettyprinter-ansi-terminal.revision = import ./cabal-files/prettyprinter-ansi-terminal.nix;
        prettyprinter-ansi-terminal.flags.text = true;
        scientific.revision = import ./cabal-files/scientific.nix;
        scientific.flags.integer-simple = false;
        vector.revision = import ./cabal-files/vector.nix;
        vector.flags.internalchecks = false;
        vector.flags.boundschecks = true;
        vector.flags.wall = false;
        vector.flags.unsafechecks = false;
        rts.revision = hackage.rts."1.0.3".revisions.default;
        th-env.revision = import ./cabal-files/th-env.nix;
        dlist.revision = import ./cabal-files/dlist.nix;
        dlist.flags.werror = false;
        libyaml-clib.revision = import ./cabal-files/libyaml-clib.nix;
        fourmolu.revision = import ./cabal-files/fourmolu.nix;
        fourmolu.flags.dev = false;
        ghc-lib-parser.revision = import ./cabal-files/ghc-lib-parser.nix;
        ghc-lib-parser.flags.threaded-rts = true;
        libyaml.revision = import ./cabal-files/libyaml.nix;
        libyaml.flags.no-unicode = false;
        libyaml.flags.system-libyaml = false;
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
          "parsec" = "3.1.18.0";
          "ghc-bignum" = "1.4";
          "stm" = "2.5.3.1";
          "filepath" = "1.5.4.0";
          "os-string" = "2.0.8";
          "rts" = "1.0.3";
          "unix" = "2.8.8.0";
          "hpc" = "0.7.0.2";
          "exceptions" = "0.10.11";
          "deepseq" = "1.5.1.0";
          "Cabal-syntax" = "3.16.0.0";
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
        "ghc-bignum"
        "stm"
        "transformers"
        "deepseq"
        "directory"
        "file-io"
        "parsec"
        "mtl"
        "process"
        "base"
        "Cabal-syntax"
        "text"
        "time"
        "array"
        "hpc"
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
          "alex".components.exes."alex".planned = lib.mkOverride 900 true;
          "data-fix".components.library.planned = lib.mkOverride 900 true;
          "Cabal-syntax".components.library.planned = lib.mkOverride 900 true;
          "integer-conversion".components.library.planned = lib.mkOverride 900 true;
          "file-io".components.library.planned = lib.mkOverride 900 true;
          "attoparsec".components.sublibs."attoparsec-internal".planned = lib.mkOverride 900 true;
          "resourcet".components.library.planned = lib.mkOverride 900 true;
          "mono-traversable".components.library.planned = lib.mkOverride 900 true;
          "conduit".components.library.planned = lib.mkOverride 900 true;
          "fourmolu".components.exes."fourmolu".planned = lib.mkOverride 900 true;
          "hashable".components.library.planned = lib.mkOverride 900 true;
          "template-haskell".components.library.planned = lib.mkOverride 900 true;
          "text-short".components.library.planned = lib.mkOverride 900 true;
          "network-uri".components.library.planned = lib.mkOverride 900 true;
          "parser-combinators".components.library.planned = lib.mkOverride 900 true;
          "unordered-containers".components.library.planned = lib.mkOverride 900 true;
          "these".components.library.planned = lib.mkOverride 900 true;
          "QuickCheck".components.library.planned = lib.mkOverride 900 true;
          "distributive".components.library.planned = lib.mkOverride 900 true;
          "transformers".components.library.planned = lib.mkOverride 900 true;
          "case-insensitive".components.library.planned = lib.mkOverride 900 true;
          "unliftio-core".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."tabular".planned = lib.mkOverride 900 true;
          "scientific".components.library.planned = lib.mkOverride 900 true;
          "array".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."backend-glr".planned = lib.mkOverride 900 true;
          "unix".components.library.planned = lib.mkOverride 900 true;
          "base-orphans".components.library.planned = lib.mkOverride 900 true;
          "exceptions".components.library.planned = lib.mkOverride 900 true;
          "file-embed".components.library.planned = lib.mkOverride 900 true;
          "unliftio".components.library.planned = lib.mkOverride 900 true;
          "Diff".components.library.planned = lib.mkOverride 900 true;
          "directory".components.library.planned = lib.mkOverride 900 true;
          "syb".components.library.planned = lib.mkOverride 900 true;
          "semigroupoids".components.library.planned = lib.mkOverride 900 true;
          "indexed-traversable-instances".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."frontend".planned = lib.mkOverride 900 true;
          "containers".components.library.planned = lib.mkOverride 900 true;
          "parsec".components.library.planned = lib.mkOverride 900 true;
          "th-env".components.library.planned = lib.mkOverride 900 true;
          "semialign".components.library.planned = lib.mkOverride 900 true;
          "random".components.library.planned = lib.mkOverride 900 true;
          "dlist".components.library.planned = lib.mkOverride 900 true;
          "hpc".components.library.planned = lib.mkOverride 900 true;
          "vector-algorithms".components.library.planned = lib.mkOverride 900 true;
          "aeson".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter".components.library.planned = lib.mkOverride 900 true;
          "megaparsec".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.library.planned = lib.mkOverride 900 true;
          "transformers-compat".components.library.planned = lib.mkOverride 900 true;
          "time-compat".components.library.planned = lib.mkOverride 900 true;
          "safe-exceptions".components.library.planned = lib.mkOverride 900 true;
          "StateVar".components.library.planned = lib.mkOverride 900 true;
          "stm".components.library.planned = lib.mkOverride 900 true;
          "strict".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."grammar".planned = lib.mkOverride 900 true;
          "rts".components.library.planned = lib.mkOverride 900 true;
          "comonad".components.library.planned = lib.mkOverride 900 true;
          "bytestring".components.library.planned = lib.mkOverride 900 true;
          "bitvec".components.library.planned = lib.mkOverride 900 true;
          "attoparsec".components.library.planned = lib.mkOverride 900 true;
          "colour".components.library.planned = lib.mkOverride 900 true;
          "integer-logarithms".components.library.planned = lib.mkOverride 900 true;
          "deepseq".components.library.planned = lib.mkOverride 900 true;
          "optparse-applicative".components.library.planned = lib.mkOverride 900 true;
          "tagged".components.library.planned = lib.mkOverride 900 true;
          "filepath".components.library.planned = lib.mkOverride 900 true;
          "assoc".components.library.planned = lib.mkOverride 900 true;
          "OneTuple".components.library.planned = lib.mkOverride 900 true;
          "witherable".components.library.planned = lib.mkOverride 900 true;
          "happy".components.exes."happy".planned = lib.mkOverride 900 true;
          "ghc-internal".components.library.planned = lib.mkOverride 900 true;
          "yaml".components.library.planned = lib.mkOverride 900 true;
          "newtype-generics".components.library.planned = lib.mkOverride 900 true;
          "time".components.library.planned = lib.mkOverride 900 true;
          "primitive".components.library.planned = lib.mkOverride 900 true;
          "choice".components.library.planned = lib.mkOverride 900 true;
          "ghc-bignum".components.library.planned = lib.mkOverride 900 true;
          "pretty".components.library.planned = lib.mkOverride 900 true;
          "th-compat".components.library.planned = lib.mkOverride 900 true;
          "character-ps".components.library.planned = lib.mkOverride 900 true;
          "os-string".components.library.planned = lib.mkOverride 900 true;
          "split".components.library.planned = lib.mkOverride 900 true;
          "prettyprinter-ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "th-abstraction".components.library.planned = lib.mkOverride 900 true;
          "ghc-lib-parser".components.library.planned = lib.mkOverride 900 true;
          "mtl".components.library.planned = lib.mkOverride 900 true;
          "bifunctors".components.library.planned = lib.mkOverride 900 true;
          "uuid-types".components.library.planned = lib.mkOverride 900 true;
          "vector".components.sublibs."benchmarks-O2".planned = lib.mkOverride 900 true;
          "fourmolu".components.library.planned = lib.mkOverride 900 true;
          "text-iso8601".components.library.planned = lib.mkOverride 900 true;
          "binary".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal-types".components.library.planned = lib.mkOverride 900 true;
          "ghc-boot-th".components.library.planned = lib.mkOverride 900 true;
          "ansi-terminal".components.library.planned = lib.mkOverride 900 true;
          "happy-lib".components.sublibs."backend-lalr".planned = lib.mkOverride 900 true;
          "libyaml-clib".components.library.planned = lib.mkOverride 900 true;
          "hsc2hs".components.exes."hsc2hs".planned = lib.mkOverride 900 true;
          "vector-stream".components.library.planned = lib.mkOverride 900 true;
          "MemoTrie".components.library.planned = lib.mkOverride 900 true;
          "base".components.library.planned = lib.mkOverride 900 true;
          "process".components.library.planned = lib.mkOverride 900 true;
          "vector".components.library.planned = lib.mkOverride 900 true;
          "contravariant".components.library.planned = lib.mkOverride 900 true;
          "terminal-size".components.library.planned = lib.mkOverride 900 true;
          "tasty".components.library.planned = lib.mkOverride 900 true;
          "text".components.library.planned = lib.mkOverride 900 true;
          "indexed-traversable".components.library.planned = lib.mkOverride 900 true;
          "splitmix".components.library.planned = lib.mkOverride 900 true;
          "libyaml".components.library.planned = lib.mkOverride 900 true;
          "ghc-prim".components.library.planned = lib.mkOverride 900 true;
          "async".components.library.planned = lib.mkOverride 900 true;
        };
      })
  ];
}