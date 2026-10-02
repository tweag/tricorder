# Package Source Lookup — Work Package

## High-level Description

When exploring an unfamiliar library, the fastest path to understanding its API is reading
the source. Haddock's `--hyperlinked-source` output renders each module as HTML on disk
alongside the documentation. Stripping those HTML tags yields the raw Haskell source —
no network access, no `cabal get`, nothing extra to install. The source is available
whenever a package was built with documentation, which is the case on Nix-managed
environments and on any cabal installation with `documentation: True` in
`~/.cabal/config`.

This proposal adds a `source` subcommand to tricorder and a corresponding socket query type
that returns the source of any module from an installed package. The primary consumers are
agents performing exploratory work — looking up type signatures, understanding data
constructors, tracing call chains — but human users benefit too, particularly once
formatting is in place (Milestone 3).

The daemon resolves `module name → package` using `ghc-pkg find-module`, so callers need
only supply module names. A batch form (`tricorder source M1 M2 ...`) is supported from the
start, since agents commonly need several modules in one pass. Results are cached on the
daemon for the lifetime of the session.

**Deliverables:**

- `tricorder source <Module.Name> [Module.Name ...]` CLI subcommand (one or more modules)
- New `SourceQuery` / `SourceResponse` socket protocol types
- Module-to-package resolution via `ghc-pkg find-module`
- Haddock HTML source retrieval and tag stripping
- In-daemon cache keyed by `(package-id, module-name)`
- _(Stretch)_ Optional source formatting via a user-configured formatter

---

## Core Objectives

- **Make library source accessible to agents and users** — given one or more module
  names, retrieve their source in one call with no manual path construction. Agents use
  this for programmatic exploration; users benefit especially when formatting is enabled.
- **No extra installation** — haddock HTML is already on disk for any package that has
  documentation; no `cabal get` or network access required.
- **Leverage the daemon's session context** — the daemon knows which packages are loaded,
  so a bare module name is sufficient; no package name required.

---

## Metrics for Success

- `tricorder source Data.Map.Strict` returns the full source of that module.
- `tricorder source Data.Map.Strict Data.Map.Lazy` returns both, clearly separated.
- A second call for the same module is served from cache without re-reading disk.
- An unknown module returns a clear error message.
- The socket query path returns the same result as the CLI.

---

## Classification

- **New initiative or continuation of existing:** New initiative
- **Primary nature:** Feature
- **Dependencies:** None (independent of WP-001 and WP-002)

---

## Milestones

### Milestone 1 — Core lookup

**Deliverables:**
- `ghc-pkg find-module` shell-out to resolve module → package
- `ghc-pkg field <pkg> haddock-html` shell-out to get HTML root
- HTML path construction: `<root>/src/<Dotted.Module>.html`
- Tag-stripping to recover raw Haskell source
- `tricorder source <Module> [Module ...]` CLI subcommand wired end-to-end

**Acceptance criteria:**
`tricorder source Data.Map.Strict` prints the Haskell source of that module to stdout.
`tricorder source Data.Map.Strict Data.Map.Lazy` prints both, separated by a header line.

---

### Milestone 2 — Socket protocol and caching

**Deliverables:**
- `SourceQuery` and `SourceResponse` types in `Tricorder.Socket.Protocol`
- Daemon handler serving source via the socket
- In-memory cache keyed by `(package-id, module-name)`, populated on first request

**Acceptance criteria:**
A socket client can issue a `SourceQuery` and receive `SourceResponse`. Repeated queries
for the same module do not re-read disk (verified by timing or a cache-hit counter in
tests).

---

### Milestone 3 — Stretch: formatter integration

**Deliverables:**
- Optional `source-formatter` field in `.tricorder.toml` (e.g. `"ormolu"` or a full command)
- If configured, the daemon pipes stripped source through the formatter before returning
- CLI respects the same config

**Acceptance criteria:**
With `source-formatter = "ormolu"` set, `tricorder source Data.Map.Strict` returns
ormolu-formatted output. Without the field, behaviour is unchanged.

---

## Notes

The haddock source HTML contains `<span>` tags for syntax highlighting but is otherwise
close to the raw source. The stripping strategy needs to handle at minimum: anchor tags
around identifiers, span tags for highlighting classes, and the surrounding page
boilerplate. A simple tag-stripping pass is sufficient; no full HTML parser is needed.

The stretch formatter goal is deliberately deferred to Milestone 3. Agents can work with
unformatted source, and formatter configuration is a user concern that should not block
the core feature.
