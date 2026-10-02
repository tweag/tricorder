# Design: Custom GHCi Session Manager

## Status

Implemented. See `README.md` for the module map and `spec.md` for interfaces.

---

## Problem

`runGhciSessionIO` delegated all GHCi process management to the `ghcid` library via
`Ghcid.startGhci` and `Ghcid.reload`. This created two practical problems:

**Loss of control.** Progress callbacks (`[N of M] Compiling`) were routed through
ghcid's opaque startup callback — the only per-line hook the library exposed. There
was no way to intercept mid-reload output, control the synchronisation timeout, or
add custom GHCi commands without forking the library. The `parseProgress` function
existed precisely because tricorder had to reach into a callback designed for logging,
not for structured event delivery.

**An unnecessary dependency.** ghcid carries transitive dependencies that tricorder
already pulls in elsewhere (`process`, `extra`). The genuinely useful parts of ghcid
are the sentinel-marker synchronisation protocol and the output parser — together about
300 lines, both small enough to own directly.

---

## Approach

### Keep the effect interface; replace only the interpreters

The `GhciSession` effect and `LoadResult` type are stable contracts used throughout
`Builder.hs`. They remain unchanged. `runGhciSessionScripted` is unaffected. Only
`runGhciSessionIO` received a parallel replacement (`runGhciSessionCustom`); the old
interpreter is kept alongside it for now via `runGhciSessionFromEnv`.

### Sentinel-marker synchronisation

To know when a GHCi command has finished producing output, the same approach as ghcid
is followed: after each command, a one-liner is sent that prints a unique numbered
marker to both stdout and stderr:

```
putStrLn "#~TRI-FINISH-N~#" >> System.IO.hPutStrLn System.IO.stderr "#~TRI-FINISH-N~#"
```

The reader drains both streams concurrently until it sees the marker on each. This
is robust: it does not depend on timing, prompt appearance, or stream buffering.
Independent markers on both streams ensure a late stderr line cannot arrive after
the next command has started.

The counter `N` increments with each command, preventing a stale marker from a prior
command from being mistaken for a fresh one. Note: the actual expression uses
`putStrLn` (which adds a newline), not `putStr`.

### Initialisation sequence

On startup, `startGhciProcess`:

1. Spawns the subprocess with `setCreateGroup True` and separate stdout/stderr pipes,
   using `System.Process.Typed`
2. Sends a blank line to stdin (some launchers like `stack` consume stdin before GHCi
   is ready; the blank line satisfies any such prompt without affecting GHCi itself)
3. Reads stdout until `"GHCi, version"` (or `"GHCJSi, version"` / `"Clashi, version"`)
   appears (discards all prior output)
4. Sends `:set prompt ""`, `:set prompt-cont ""`, `:set +c`, and any caller-supplied
   `extraSetupCommands`
5. Sends the first sync command to flush any remaining startup output
6. Returns the `GhciProcess` handle

If the version banner does not appear within `startupTimeout` seconds (default 60),
the process is stopped and `StartupTimeout` is thrown.

### Output parser

The parser recognises the four patterns emitted by GHCi during `:reload`:

| Line pattern | Produces |
|---|---|
| `[N of M] Compiling Mod ( file, ... )` | `GLoading N M modName filePath` |
| `file:L:C: severity:\nmessage lines` | `GMessage severity file (l,c) (el,ec) lines` |
| `Loaded GHCi configuration from path` | `GLoadConfig filePath` |
| `Ok, N modules loaded` / `Failed, ...` | discarded (count comes from `:show modules`) |

ANSI escape codes are stripped before matching. The original (unstripped) lines are
stored in `GMessage`'s message-lines field so colour is preserved for display.

The `GhciLoad` type is a fresh local definition — not a vendored copy of
`Language.Haskell.Ghcid.Load`. The `GLoading` variant carries the N and M counters
directly as `Int` fields, which removes the need for a separate `parseProgress` pass
during reload.

`LoadResult` was moved into `GhciParser` so it is independent of both backends.
`extractTitle`, `stripAnsi`, and `toRelative` also live there, as they are pure
utilities with no process-management concerns.

### Progress reporting

In `runGhciSessionCustom`, progress updates are emitted inline during reload: after
`execGhci ":reload"` returns, the result list is scanned for `GLoading n m _ _`
items and each one issues a `setPhase ... (Building (Just BuildProgress {compiled=n, total=m}))`.
Because `GLoading` carries the counters, no separate `parseProgress` re-parse is needed.

### Process group management

`setCreateGroup True` in `System.Process.Typed` ensures that `stopProcess` and
interrupt signals reach all descendants (e.g. the GHC subprocess spawned by
`cabal repl`). Shutdown: send `:quit`, wait up to `shutdownTimeout` seconds (default 5),
then call `stopProcess` from `System.Process.Typed`.

### Configuration

`GhciProcess.Config` holds `startupTimeout`, `shutdownTimeout`, and
`extraSetupCommands`. `withGhciProcess` is called with `def` (the `Default` instance)
in `runGhciSessionCustom`; callers that need non-default timeouts can call
`withGhciProcess` directly.

### Command serialisation

A `TVar SessionState` serialises access to the subprocess stdin, where
`SessionState = Idle Int | Busy Int` tracks both exclusivity and the per-command
marker counter. Only one `execGhci` call runs at a time; callers block in STM
until the session is `Idle`.

### Module layout

Parser and process-management live under `Tricorder.Daemon.GhciSession.*`
(`GhciParser` and `GhciProcess`). The sole production interpreter is `runGhciSession`
in `Tricorder.Daemon.GhciSession`. The `ghcid` library and its companion
`GhcidBackend` module have been removed.

---

## Alternatives Considered

### Keep ghcid, patch it upstream

The improvements needed (first-class progress events, synchronisation control) would
require API changes in ghcid. Direct ownership is more pragmatic.

### Prompt detection (ghciwatch style)

Set a unique custom prompt string; read stdout until the prompt appears. Rejected
because: sentinel markers work even if the output contains the prompt string, and they
independently synchronise stdout and stderr, which prevents a late stderr line from
arriving attributed to the wrong command.

### Shell out to the `ghciwatch` binary

ghciwatch has its own file-watching loop, restart logic, and output format. Adapting
its output stream to tricorder's event model would require a translation layer at
least as complex as the custom manager itself.

---

## Trade-offs

**Parser ownership.** Any GHCi output format change in a new GHC version requires a
fix here. Mitigated by: keeping the parser narrowly scoped (only the four patterns
above), testing it against real output samples, and making the test fixtures easy to
update.

**Reinvention.** The synchronisation protocol and parser are adaptations of ghcid's
existing design. The value is control and dependency removal, not new ideas.

---

## Resolved Questions

1. **Startup timeout.** Resolved as `startupTimeout` in `Config` (default 60 s). Not
   currently exposed in `.tricorder.toml`.

2. **Vendor or rewrite the `Load` type?** Rewritten as `GhciLoad`. The `GLoading`
   variant was extended with N and M counters (absent from `ghcid`'s `Loading` type),
   eliminating the need for a separate `parseProgress` call. All variants use
   positional fields rather than record syntax.

3. **Backend selector.** Resolved: `runGhciSessionFromEnv` and `runGhciSessionIO` have
   been removed. `runGhciSession` is the sole production interpreter.
