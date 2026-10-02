# Design: Package Source Lookup

## Status

Draft.

---

## Motivation

Agents exploring a Haskell codebase frequently need to inspect the API of an installed
library: what constructors a type has, what a function's signature is, how a typeclass is
structured. The conventional options are:

- **Hackage / Hoogle online** — requires network access; not always available in a dev
  environment.
- **`cabal get <pkg>`** — downloads a source tarball; works, but is slow, leaves
  artefacts on disk, and requires knowing the package name up front.
- **Local `.hs` files** — not reliably present on disk; package managers install compiled
  artifacts, not source.
- **Haddock HTML** — present on disk for any package built with documentation (cabal's
  `documentation: True`); contains the actual source code rendered with syntax
  highlighting.

Haddock's `--hyperlinked-source` output renders each module as an HTML file under
`<haddock-html>/src/<Dotted.Module.Name>.html`. Stripping the HTML tags recovers the
original Haskell source. This is already on disk, requires no network access, and covers
the overwhelming majority of exploration needs.

---

## Approach

### Lookup chain

```
User supplies: Data.Map.Strict

1. ghc-pkg find-module Data.Map.Strict
   → containers-0.6.8

2. ghc-pkg field containers haddock-html
   → /nix/store/.../html/

3. Read /nix/store/.../html/src/Data.Map.Strict.html
   → strip tags
   → raw Haskell source
```

Step 1 resolves module → package without the caller needing to know which package a
module belongs to. The daemon performs this resolution; the CLI caller supplies only the
module name.

### Tag stripping

Haddock source HTML wraps tokens in `<span class="...">` for syntax highlighting and
`<a ...>` for cross-references. A simple regex or character-level pass that removes all
`<...>` sequences and unescapes HTML entities (`&lt;`, `&gt;`, `&amp;`, `&#39;`,
`&quot;`) recovers the source faithfully. No full HTML parser is required.

The page boilerplate (header, navigation, `<html>`, `<body>`) must be discarded. The
source content lives inside a `<pre>` element with id `"src"` or similar; targeting that
element before stripping is more robust than stripping the entire file.

### Caching

Both shell-outs (`find-module`, `field`) and the stripped source are stable for the
lifetime of a GHCi session: installed packages do not change while the daemon is running.
The daemon holds an in-memory map `(package-id, module-name) → Text` populated on first
request. The module → package mapping is cached separately as `module-name → package-id`.

### Socket protocol

A new constructor is added to the existing `Query` sum type:

```haskell
data Query
  = StatusQuery
  | SourceQuery [ModuleName]   -- one or more modules
```

```haskell
data Response
  = StatusResponse BuildState
  | SourceResponse SourceResult   -- new

data SourceResult
  = SourceFound Text           -- stripped Haskell source
  | SourceNotFound ModuleName  -- module not in any installed package
  | SourceNoHaddock PackageId  -- package found but no haddock-html
```

The CLI `tricorder source <Module>` sends a `SourceQuery` over the socket and writes the
result to stdout, identical to how `tricorder status` works today.

### Formatter (stretch)

If `source-formatter` is set in `.tricorder.toml`, the daemon pipes the stripped source
through the configured command before caching and returning it. The formatter receives
source on stdin and must emit formatted source on stdout (standard unix filter contract).
Caching stores the formatted result, so the formatter runs at most once per module per
session.

```toml
[source]
formatter = "ormolu --stdin-input-file dummy.hs"
```

The formatter is optional and its absence changes nothing.

---

## Alternatives Considered

### `cabal get` + read `.hs` directly

Works, but: slow (network or local cache lookup), leaves a directory behind, and requires
knowing the package name. For agents making many lookups in one session, the latency
adds up. The haddock HTML path is faster and entirely local.

### GHCi `:info` / `:type` / `:source`

GHCi's `:source` command prints the source file path for a loaded module. This only works
for modules that are part of the current project, not installed dependencies. `:info` and
`:type` give signatures but not full module source.

### Parse haddock `.hoogle` or `.txt` index files

Haddock generates `doc-index.html` and `.hoogle` files, but these are search indices, not
source. They give type signatures but not definitions or the full module structure.

### Ship a standalone `tricorder-source` binary

Keeping the feature inside the daemon (with a CLI front-end over the socket) means the
cache is shared across all callers for the session lifetime. A standalone binary would
re-read and re-strip on every invocation.

---

## Open Questions

1. **`ghc-pkg find-module` for ambiguous modules** — if a module is provided by more than
   one package (e.g. a re-export shim), `find-module` returns multiple results. Strategy:
   return the first result and log a warning. In practice this is rare for the exploration
   use case.

2. **Packages without haddock HTML** — some packages are installed without documentation
   (e.g. `--disable-documentation` in cabal). The `SourceNoHaddock` response variant
   handles this; the CLI should suggest `cabal get` as a fallback in the error message.

3. **Module name vs. file name casing** — haddock uses the dotted module name directly as
   the filename (`Data.Map.Strict.html`). This is deterministic; no lookup table needed.
