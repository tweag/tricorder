# Re-Resolve Targets on Cabal Change — Completed

## Summary

When a `.cabal` file changes, tricorder now reloads the active `Session` (targets, GHCi
command, watch directories, test targets) from disk and restarts the affected components
with the updated configuration — without restarting the daemon process. Previously, the
session was resolved once at startup and held statically; new or removed targets were
invisible until a manual daemon restart.

**Deliverables shipped:**

- `Tricorder.Effects.SessionStore` — `SessionStore` effect with `get` as its public
  operation, `withSession` restart helper, `withSubSession` general sub-session restart
  primitive, `Reloader` handle, `runSessionStore`, `runSessionStoreConst`
- `SessionStoreReloaded` event — published after each successful reload
- `Reloader` — a newtype wrapping a `reload` action, passed by `withSubSession` to the
  managed function so it can trigger a session reload by direct call rather than via the
  event bus
- `BuilderSession` — focused projection of `Session` fields relevant to Builder, used to
  avoid unnecessary restarts when unrelated session fields change
- `withBuilderSession` — thin wrapper around `withSubSession`; restarts Builder's core
  listeners when `BuilderSession` changes after a reload
- `WatcherSession` — focused projection of `Session` containing only `watchDirs`
- `withWatcherSession` — thin wrapper around `withSubSession`; re-registers filesystem
  watches when `watchDirs` changes after a reload
- `Session.loadSession` — replaces `runSession`; returns a plain `Session` value usable
  at startup and on each reload
- `Atelier.Effects.Publishing.listenOnce` / `listenOnce_` — await a single event and return
- `Atelier.Effects.Conc.race` — fork two computations, return whichever completes first

---

## Module Map

| Module | Role |
|---|---|
| `Tricorder.Effects.SessionStore` | Effect: `Get` (public); `withSession` restart loop; `withSubSession` sub-session restart primitive; `Reloader`; `runSessionStore`; `runSessionStoreConst` |
| `Tricorder.Session` | `loadSession` — resolves `Session` from config and cabal file |
| `Tricorder.Builder` | `BuilderSession`, `withBuilderSession`, `restartableListeners` |
| `Tricorder.Watcher` | `WatcherSession`, `withWatcherSession`, `watchFiles` — restarts file watches when `watchDirs` changes |
| `Tricorder.Effects.TestRunner` | Reads session via `SessionStore.get` instead of `Reader Session` |
| `Tricorder.BuildState` | Reads session via `SessionStore.get` instead of `Reader Session` |
| `Atelier.Effects.Conc` | Added `race` |
| `Atelier.Effects.Publishing` | Added `listenOnce`, `listenOnce_` |

---

## Background Documents

- [`design.md`](design.md) — problem statement, design decisions, alternatives rejected,
  trade-offs

---

## Classification

- **Nature:** Technical (feature / correctness fix)
- **Status:** Completed
