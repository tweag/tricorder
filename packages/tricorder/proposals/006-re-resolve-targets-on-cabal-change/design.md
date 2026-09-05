# Design: Re-Resolve Targets on Cabal Change

## Status

Implemented. See `README.md` for the module map.

---

## Problem

Tricorder resolved the active `Session` (targets, GHCi command, watch directories,
test targets) once at daemon startup and stored it statically in a `Reader Session`
context. When a `.cabal` file changed, GHCi was restarted but the session was not
re-read — new or removed targets were silently ignored until the daemon process was
manually restarted.

---

## Approach

### SessionStore effect

A new `SessionStore` effect owns the live `Session` value. Its only public operation is
`get :: SessionStore m Session`, which reads the current session. Session reloads are
triggered through the `Reloader` handle that `withSubSession` passes to managed functions
(see below); the underlying reload effect operation is internal to the module and not
exported.

`runSessionStore` backs the effect with a `State Session` thread. All previous uses of
`Reader Session` across `Builder`, `Watcher`, `TestRunner`, and `BuildState` were
replaced with `SessionStore.get`.

`Session.runSession` (which combined session resolution with `runReader`) was split into
`Session.loadSession`, a plain function that returns a `Session`. This is called both at
startup (to seed `runSessionStore`) and on each reload.

### withSession

`withSession :: (ActiveSession es -> Eff es a) -> Eff es Void` runs a caller-supplied
action in a loop. Each iteration:

1. Fetches the current session via `get`.
2. Forks the action, passing an `ActiveSession` value that carries the session and a
   `reloadSession` handle.
3. Waits for a `SessionStoreReloaded` event via `listenOnce_`.
4. Ends the scope (cancelling the forked action) and repeats from step 1.

This provides a uniform restart primitive for any component that needs to react to
session reloads without each component having to manage its own reload loop.

### Sub-session projections and Reloader

Not every component cares about the whole `Session`. `withSubSession` generalises the
restart pattern into a single primitive in `SessionStore`:

```
withSubSession
    :: forall subSession es
     . (Eq subSession, ...)
    => (Session -> subSession)
    -> Session
    -> (Reloader es -> subSession -> Eff es Void)
    -> Eff es Void
```

It takes a projection from `Session` to a smaller record, an initial session, and the
function to restart on change. Internally it maintains a `State subSession` and only
signals a restart when the projected value actually changes — a reload that touches
`testTimeout` does not interrupt a running GHCi session.

`withSubSession` passes a `Reloader` handle to the managed function:

```
newtype Reloader es = Reloader { reload :: Eff es () }
```

Calling `reloader.reload` triggers a session reload.

Two concrete projections use this primitive:

- **`BuilderSession`** (`command`, `targets`, `testTargets`, `watchDirs`) — projection
  used by Builder. `withBuilderSession` calls `withSubSession` and threads the `Reloader`
  down through `restartableListeners`, `buildWithGhciOnChange`, `rebuildOnChange`, and
  into `restartOnCabalChange`, which calls `reloader.reload` when a cabal change is
  detected.

- **`WatcherSession`** (`watchDirs`) — projection used by Watcher. `withWatcherSession`
  calls `withSubSession` and the managed function ignores the `Reloader` (`\_ session ->`),
  since Watcher never requests a reload independently — it only re-registers watches when
  `watchDirs` actually changes in the reloaded session.

### Reload flow

1. `Watcher` detects a `.cabal` file change and publishes `CabalChangeDetected`.
2. Builder's `restartOnCabalChange` increments the build ID, publishes
   `EnteringNewPhase buildId (Building Nothing)`, and calls `reloader.reload` (the
   `Reloader` handle threaded in from `withBuilderSession`).
3. `reloader.reload` re-runs `loadSession`, stores the new `Session`, and publishes
   `SessionStoreReloaded`.
4. `withSubSession` inside `withBuilderSession` observes the `SessionStoreReloaded`
   event via `withSession`. It compares the new `BuilderSession` projection against the
   stored one. If anything changed, it updates the state and signals the restart
   semaphore, ending the scope that contains `restartableListeners` (and therefore the
   GHCi process), then re-forks with the fresh config.
5. `withSubSession` inside `withWatcherSession` observes the same `SessionStoreReloaded`
   event. It compares the new `WatcherSession` projection; if `watchDirs` changed, it
   signals `watchFiles` to restart and re-register filesystem watches.

### listenOnce and race

Two utilities were added to support the session-management loops:

- `Publishing.listenOnce` / `listenOnce_` — subscribe to an event, block until one
  arrives, then return. Used internally by `withSession` to detect each
  `SessionStoreReloaded` event, which in turn drives the restart logic in both
  `withSubSession` instances.
- `Conc.race` — fork two computations and return whichever completes first, cancelling
  the other. Enables future patterns where a component needs to react to whichever of
  two events arrives first.

---

## Alternatives Considered

### Keep `Reader Session`; re-run `runSession` on cabal change

Re-running `runSession` would require threading it through every component that held a
`Reader Session` context, or rebuilding the entire effect stack on each reload. Either
option is invasive. `SessionStore` centralises the mutable session in one place and
lets all consumers call `get` without structural changes to their own effect rows.

### Restart the daemon process on cabal change

Simple but too blunt: daemon startup is not free (config loading, socket setup, GHC
package cache queries), and any in-flight build state would be lost. A live reload is
strictly better.

### Reload the session on every `get` call

Eager reload on every read would hit the filesystem and cabal-file parser on every
build cycle. The event-driven approach amortises the cost: reload only when a
`CabalChangeDetected` event says there is something new to read.

---

## Trade-offs

**Projection staleness.** `BuilderSession` and `WatcherSession` are snapshots of the
session fields each component cares about. If a field is added to `Session` that a
component should respond to, both the sub-session record and its `mkSubSession` projection
must be updated manually. The explicit projection makes the dependency visible, which is
preferable to silent drift.

**Reloader threading.** The `Reloader` handle is passed through several call sites in
`Builder` (`restartableListeners` → `buildWithGhciOnChange` → `rebuildOnChange` →
`restartOnCabalChange`). This is more explicit than the previous event-based approach
but adds a parameter to each internal function. The alternative — publishing a
`RequestSessionReload` event and subscribing to it inside `withSubSession` — required
a type-level parameter, an extra constraint, and an internal listener thread, at the
cost of making the control flow less direct.
