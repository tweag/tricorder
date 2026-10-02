# Design: Plugin-Based Structured Diagnostics

## Status

Draft. Supersedes `research.md` for the near-term implementation path.
Low-level contracts in `spec.md`.

---

## Motivation

The current daemon spawns a GHCi subprocess via `ghcid`, which parses GHCi's
human-readable output and returns a structured `[Load]` value. The daemon converts
this to its own `[Message]` type, giving it file path, source location, severity, and
message text.

This is already structured, but it has a ceiling set by what GHCi's text output
contains:

- No error codes (e.g. `GHC-83865`) — GHC emits these as part of the message text
  only, not as a machine-readable field.
- No structured hints — GHC's suggested fixes are embedded in the message body.
- No related spans — "see definition at Foo.hs:12" appears as prose, not as a
  separate location.
- `ghcid`'s parsing is fragile by nature: it works by detecting prompts and
  interpreting output lines, which breaks when GHC changes its formatting.

The `ghcide-integration.md` proposal explored replacing the GHCi subprocess entirely
with an in-process GHC API session. That approach is sound but carries an unavoidable
cost: the daemon binary must be compiled against the same GHC version as the target
project. For a general-purpose community tool, this means shipping one binary per
supported GHC version, mirroring the operational complexity of HLS.

The plugin approach achieves the same diagnostic richness while retaining the
subprocess model — and therefore zero GHC version coupling in the daemon binary.

---

## Architecture

```
┌─────────────────────────────────────┐
│         Client (editor, CLI)        │
│      Unix socket, JSON protocol     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          tricorder daemon               │
│  - File watcher (unchanged)         │
│  - Debounce (unchanged)             │
│  - BuildStore (unchanged)           │
│  - Socket server (unchanged)        │
│  - GhciSession interpreter          │
│    (plugin socket + ghcid fallback) │
└──────────┬──────────────────────────┘
           │ plugin socket (Unix)
┌──────────▼──────────────────────────┐
│       GHCi / cabal repl             │
│  (subprocess, any GHC version)      │
│                                     │
│  ┌──────────────────────────────┐   │
│  │      tricorder-plugin            │   │
│  │  (compiled as project dep,   │   │
│  │   correct GHC auto-selected) │   │
│  │                              │   │
│  │  driverPlugin: wraps Logger  │   │
│  │  typeCheckResultAction:      │   │
│  │    per-module events (future)│   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

The daemon remains a version-agnostic binary. The plugin is a regular Haskell library
that users add to their project; cabal/stack compiles it against the project's own GHC
automatically. The `ghcid` dependency is **retained** as a fallback for projects that
have not yet added `tricorder-plugin`.

---

## Key Design Decisions

### Plugin over in-process GHC API

Linking the daemon against the `ghc` library would require one binary per supported
GHC version (the same constraint HLS carries). The plugin approach delegates that
coupling to the project's own build: cabal compiles `tricorder-plugin` against the right
GHC version automatically.

### ghcid retained as fallback

The daemon opens a plugin socket at startup and waits a short time for the plugin to
connect. If it does, diagnostics flow from the plugin (structured). If not, the daemon
falls back to the existing `ghcid`-backed stdout scraping silently. A log message at
startup indicates which mode is active. This preserves backward compatibility — the
daemon works out of the box without any user setup.

### Socket discovery via environment variable

The daemon communicates the plugin socket path by setting `TRICORDER_PLUGIN_SOCKET` in
the environment of the GHCi subprocess it spawns. The plugin reads this with
`lookupEnv`. If the variable is absent (e.g. the user runs `cabal repl` directly),
the plugin does nothing. This means:

- No `-fplugin-opt` in user cabal files — only `-fplugin=Tricorder.Plugin` is needed.
- The plugin is safe to commit permanently; it is a no-op outside the daemon.

### GHC version support: 9.8+

The GHC diagnostic infrastructure (`DiagnosticMessage`, `MsgEnvelope`, error codes,
hints, related spans) and the Logger API stabilised at GHC 9.8. Targeting 9.8+
gives a CPP-free plugin codebase. GHC 9.6 is three years old and being phased out
of HLS support.

> **Pre-implementation note:** Upgrade the project to GHC 9.8 before starting this
> work if not already there.

---

## Component: tricorder-plugin

A new library, separate from the main `tricorder` library. Users add it once per watched
cabal component:

```cabal
library
  build-depends: ..., tricorder-plugin
  ghc-options:   -fplugin=Tricorder.Plugin
```

The plugin registers two hooks:

- **`driverPlugin`** — fires once at GHCi session startup. Reads
  `TRICORDER_PLUGIN_SOCKET`; if present, wraps GHC's Logger to forward every diagnostic
  to the daemon over a Unix socket. The hook persists across all subsequent `:reload`
  cycles.
- **`typeCheckResultAction`** — no-op in the prototype; see "Future" below.

When `TRICORDER_PLUGIN_SOCKET` is absent the plugin returns immediately without
modifying the session.

---

## Component: tricorder Daemon Changes

| Component | Change |
|---|---|
| `ghcid` dependency | **Retained** as fallback |
| `Tricorder.Daemon.GhciSession` (interpreter) | **Extended** — detects plugin connection; falls back to ghcid |
| `Tricorder.BuildState.Message` | **Extended** — add `errorCode`, `hints`, `relatedSpans` (empty in fallback mode) |
| `Tricorder.GhciSession` (component) | **Minor** — unchanged overall structure |
| File watcher, debounce, BuildStore, socket server, config | **Unchanged** |

---

## Build Lifecycle

### Prototype

```
File change detected
  → debounce settles
  → daemon writes `:reload\n` to GHCi stdin

  [plugin mode]
    → plugin Logger hook fires per diagnostic
    → plugin sends DiagnosticEvent JSON to plugin socket
    → daemon accumulates DiagnosticEvents
    → GHCi prints "Ok/Failed, N modules loaded." to stdout
    → daemon assembles BuildResult from DiagnosticEvents

  [fallback mode]
    → ghcid stdout scraping (current behaviour, unchanged)

  → BuildStore updated → clients notified
```

The "Ok/Failed, N modules loaded." line is the only GHCi stdout parsing retained in
plugin mode. It is a stable, single-line signal that has not changed across GHC
versions.

### Future: Per-Module Events

`typeCheckResultAction` fires once per module as it finishes typechecking. Activating
this hook in a future iteration allows the plugin to emit per-module completion
events. Combined with the module graph (available from `TcGblEnv`), the daemon could:

- Know ahead of time how many modules are in the compilation cycle.
- Detect "all modules done" without any stdout scraping.
- Report incremental progress (N of M modules compiled) to clients.

This eliminates the last stdout dependency entirely and is left for a follow-up once
the prototype is validated.

---

## User Setup

Add to each cabal component that should be watched:

```cabal
library
  build-depends: ..., tricorder-plugin
  ghc-options:   -fplugin=Tricorder.Plugin
```

No changes to `.tricorder.toml`. Without `tricorder-plugin`, the daemon operates in fallback
mode automatically.

---

## Open Questions

1. **Multi-component projects** — cabal multi-repl (`--enable-multi-repl`) loads
   multiple components in one GHCi session. The plugin is loaded once; diagnostics
   arrive interleaved across components. Attribution by `file` field in
   `DiagnosticEvent` is sufficient — no protocol changes needed.

2. **GHCi without cabal** — plain `ghci` invocations require the user to pass
   `-fplugin=Tricorder.Plugin` themselves. Document this; do not attempt to auto-detect.
