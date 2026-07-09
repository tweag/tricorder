# Design: Decouple Build State into Cycle and Registers

## Status

Draft. See `README.md` for the work package; low-level contracts land in `spec.md`
(written after the implementation spike). Supersedes the `PostBuildStore` approach
from PR #263 / #265.

---

## Motivation

The current `BuildState` packs everything — lifecycle status, build output, test
output, and (soon) eval output — into a single `BuildPhase` sum type behind a
single `TVar`. This conflation is the root cause of the machinery introduced in
PR #263/#265:

- `PostBuildStore` — a one-method effect whose only job is to safely poke the
  test-results field of `BuildComplete` without disturbing the phase.
- The `other -> other` non-clobber discipline in every `modifyPhase`.
- The `Restarting`-clobber race and its fix.

All of it exists to make it *safe to mutate one field of a shared blob*. The
insight behind this redesign: that blob should never have been a blob.

## The tell: `BuildPhase` is a product wearing a sum's clothing

```haskell
data BuildPhase
    = Restarting                          -- lifecycle tag, no payload
    | Building (Maybe BuildProgress)      -- lifecycle tag ⊗ build progress
    | BuildFailed Text                    -- lifecycle tag ⊗ build error
    | BuildComplete BuildResult PostBuild -- lifecycle tag ⊗ (build output, test output)
```

Every constructor is `(a lifecycle tag) ⊗ (some producer's output)`. It is not a
sum of mutually-exclusive states; it is a *state-machine tag* multiplied by
*output payloads*, collapsed into one type. Because the test output lives
*inside* the lifecycle sum, any post-build task that wants to update test results
must pattern-match the lifecycle and take care not to stomp it. That care is what
`PostBuildStore`, the non-clobber guards, and the race fix are all paying for.

## Two kinds of state, conflated

The design separates two things that have opposite characteristics:

1. **Cycle / workflow state** (`buildId` + `cycle`): genuinely mutable,
   sequenced, and contended. A state machine with exactly one sequencer (the
   Builder lifecycle loop). This is where the real concurrency hazards live — the
   `Restarting` race was a race *on this*. It deserves centralized ownership.

2. **Producer outputs** (`build`, `tests`, `evals`): not dangerous shared state
   at all. Each is a **single-writer register** — one producer writes it, many
   readers read it. The test runner is the *only* writer of `tests`; it never
   needs to touch `build` or `cycle`.

Once separated, "how does a post-build task safely mutate shared state?"
evaporates *structurally*: a setter that only writes `.tests` cannot express a
phase change or clobber another field. There is nothing to guard against, so no
effect to introduce, and the `Restarting` race becomes impossible by
construction rather than fixed by discipline.

## Proposed shape

```haskell
data BuildState = BuildState
    { buildId    :: BuildId
    , cycle      :: CyclePhase       -- the state machine (contended, single sequencer)
    , build      :: BuildOutput      -- register: written by the compile step
    , tests      :: TestOutput       -- register: written by the test runner
 -- , evals      :: EvalOutput       -- register: written by the eval runner (later)
    , daemonInfo :: DaemonInfo
    }

data CyclePhase
    = Restarting
    | Building (Maybe BuildProgress)
    | Settled                        -- the load ran to completion; see `build`
    | Failed Text                    -- GHCi produced no result at all

data BuildOutput
    = NotBuilt
    | Built BuildResult

data TestOutput
    = TestsIdle
    | TestsRunning Test.Suites
    | TestsDone Test.Suites
```

`BuildResult` is unchanged (`completedAt`, `duration`, `moduleCount`,
`diagnostics`). Note the two distinct kinds of "failure":

- A load that **ran and produced error diagnostics** is `Settled` + `Built`
  (`BuildResult` whose `diagnostics` contain `SError`s). The cycle completed; the
  errors live in the build register.
- A load that **never produced a result** — GHCi crashed on startup, or a reload
  threw — is `Failed Text` on the cycle, with no `BuildResult`. This is the old
  `BuildFailed Text` arm, and it belongs on the cycle rather than the build
  register because there is no build output to hold.

## Why one `TVar`, not one per producer

Keep a single `TVar BuildState` and split the *fields*, not the cell. The pain
was never "one TVar" — it was "one sum type." A single record with independent
fields gives us:

- **Structural safety**: each producer touches only its own field via a focused
  setter (`setTests`, `setBuild`), which cannot reach the others.
- **Atomic coherent snapshots for free**: readers (UI, socket, `status --wait`)
  see a consistent cross-field view; the `transitions` broadcast and waiter logic
  stay simple (one value to read).

Separate TVars per producer would re-introduce a coordination problem — readers
stitching a coherent view across cells — for no real gain, since write contention
here is negligible.

## The dependency graph this mirrors

Build is upstream; test and eval are siblings that depend only on build, never on
each other:

```
Build ──▶ Test
     └──▶ Eval
```

Orchestration becomes a trivial fan-out: on settle, if the build is clean, kick
the test producer and the eval producer. "What runs post-build" shrinks to a list
of independent producers with no shared write target — so hooks, if we still want
them, get radically simpler: each hook writes its own register, with no capability
to thread and no ordering to coordinate between siblings.

## The trade-off: type-level exclusivity vs. coherence bookkeeping

Today `BuildComplete BuildResult PostBuild` makes "test results only exist when
the build is complete" *unrepresentable*. Flattening lets us represent `Building`
alongside `Just` last-cycle tests. This is the one guarantee we give up — and it
is arguably a **feature**:

- It lets the UI keep showing the last test run (e.g. greyed out) while the next
  build is in flight, instead of results blinking out the instant a file changes.

The obligation it creates: tag each output register with the `buildId` it was
produced for (or reset the register when a new build cycle starts), so a reader
never shows build N's diagnostics next to build N-1's tests. Today that coherence
is handled *implicitly* by "throw everything away on rebuild" — which is exactly
why test progress and results flicker. Making it explicit via `buildId` is a net
improvement, and it is also what lets `status --wait` wake on "build N fully
settled" rather than on a stale leftover.

## What this eliminates / simplifies

- **`PostBuildStore` deleted** — not replaced by a helper, just gone. There is no
  shared blob left to safely poke.
- **The `Restarting` race becomes structural** — a test write and a `Restarting`
  write touch different fields and cannot interleave destructively.
- **`stateLabel` / `isBuilding` become pure derivations** over independent fields
  (`cycle == Settled && tests settled && ...`) instead of reaching into a nested
  sum.
- **`reportTestProgress`** (which today bypasses `PostBuildStore` and pokes
  `BuildComplete` via raw `modifyPhase`) becomes an ordinary `setTests` /
  `modifyTests` on the test register — the current leak in the containment story
  disappears.
- **Hooks become a clean fan-out** of single-writer producers, to be introduced
  when eval-comments actually lands and there is a concrete second consumer.

## Cost

The `buildId`-coherence bookkeeping (tagging outputs / resetting on new cycle) is
the real new cost. It buys cross-cycle result retention we likely want anyway, and
replaces an implicit "wipe on rebuild" behavior that is already the source of UI
flicker.

## State-machine representation: an event + reducer for the cycle

The sections above leave the cycle as a bare `CyclePhase` sum mutated by scattered
`enterPhase` / `setPhase` / `modifyPhase` calls. That scattering is exactly where
the `Restarting`-clobber bug was able to hide. A representation that fits the two
hazards we actually have — transition legality *under concurrency*, and
`buildId`/register coherence — is to model the cycle's *inputs* as events and put
its dynamics in one reducer.

We surveyed the alternatives (indexed GADTs, phantom-typed smart constructors,
indexed/parameterized monads and session types). They all encode transition
legality in the *types*, but this state is (a) held in a shared `TVar` and
observed concurrently, and (b) serialized across the socket — so the type index is
existentially erased at both boundaries and buys almost nothing here, while
costing `Generic`/JSON derivation and `Some*` wrapping (which this repo has
already been bitten by). The value-level event+reducer keeps all the leverage
where it survives those boundaries.

### Ownership

- The reducer owns `buildId`, `cycle`, and the `build` register. The build result
  *is* the cycle's product, so "settle the cycle" and "publish the result" are a
  single atomic step under the same `buildId`.
- `tests` and `evals` are downstream registers written directly by their producers
  (`setTests` / `modifyTests`), which read the current `buildId` for tagging. They
  do **not** emit cycle events — a test finishing never moves the cycle.

### Events

```haskell
data CycleEvent
    = SourceChanged                 -- debounced source edit: begin a new build
    | CabalChanged                  -- .cabal/package.yaml edit: restart the session
    | SessionStarted                -- a fresh GHCi session came up post-restart
    | BuildProgressed BuildProgress -- [N of M] Compiling … during a load
    | BuildFinished BuildResult     -- load completed and produced a result
    | BuildAborted Text             -- GHCi produced no result (startup crash / reload threw)
```

### The reducer

```haskell
-- Owns buildId, cycle, and the build register. Never touches tests/evals.
step :: BuildState -> CycleEvent -> BuildState
step s = \case
    -- A .cabal change wins over everything, including a build that finished a
    -- moment ago. This single clause is the entire Restarting-clobber fix.
    CabalChanged      -> s { cycle = Restarting }

    -- New build cycle. `beginBuild` bumps the id, resets the phase, and
    -- deliberately carries daemonInfo + the bounded history forward (retention).
    SessionStarted    -> beginBuild s
    SourceChanged     -> beginBuild s

    -- Progress only advances a live build; a late line never resurrects a
    -- Settled / Restarting / Failed cycle.
    BuildProgressed p -> case s.cycle of
        Building _ -> s { cycle = Building (Just p) }
        _          -> s

    -- Completing a load flips to Settled AND publishes the result atomically,
    -- under the same buildId. A result arriving after a restart began is dropped.
    BuildFinished r   -> case s.cycle of
        Restarting -> s
        _          -> s { cycle = Settled, build = Built r }

    -- GHCi produced no result at all (startup crash, reload threw).
    BuildAborted msg  -> case s.cycle of
        Restarting -> s
        _          -> s { cycle = Failed msg }
```

The clobber fix stops being a defensive `other -> other` guard sprinkled across
every writer and becomes two obvious clauses: `Restarting` absorbs a stale
`BuildFinished` / `BuildAborted`.

### Beginning a cycle: total construction, not `mempty` or record-update

```haskell
-- The single definition of "what a new build cycle looks like". Every field is
-- named, so adding a field to BuildState forces a decision HERE at compile time
-- rather than being silently carried by a record update or blanked by mempty.
beginBuild :: BuildState -> BuildState
beginBuild prev = BuildState
    { buildId = prev.buildId + 1
    , cycle   = Building Nothing
    , history = evictBeyondK (prev.buildId + 1) prev.history  -- carried, bounded
    }
```

(`daemonInfo` is deliberately absent — see "`DaemonInfo` is configuration, not
state" below. It is joined onto the wire response, not carried in the reduced
state.)

Two temptations to avoid:

- **Bare record-update `s { buildId = …, cycle = … }`** silently carries every
  *other* field, including any field added later — a footgun as the record grows.
- **`mempty { buildId = … }`** doesn't fit either: `history` must be *carried*
  (bounded), not blanked — emptying it throws away the cross-cycle retention it
  exists to provide — and `buildId` is a counter to bump, not reset to zero. A new
  cycle is not an empty state; it is the previous state with the phase reset, the
  id bumped, and the bounded history threaded through.

`beginBuild` states that totally and in one place, and collapses the
`SessionStarted` / `SourceChanged` clauses to a single call each. The only genuine
monoid in the state is `history` (map union, last-write-wins) — not the whole
`BuildState`, which mixes accumulation (`history`), a state machine (`cycle`), and
a carried counter (`buildId`).

### Every scattered transition collapses to an `emit`

`emit ev = atomically (modifyTVar ref (`step` ev) >> broadcast)`. The current call
sites map directly:

```
preRestart:                enterPhase Restarting             -> emit CabalChanged
onRestart:                 bump id + Building Nothing         -> emit SessionStarted
reloadOnSourceChange:      enterPhase (Building Nothing)      -> emit SourceChanged
  on success (afterLoad):  setPhase … BuildComplete result    -> emit (BuildFinished result)
  on error:                enterPhase (BuildFailed msg)       -> emit (BuildAborted msg)
recoverFromStartupFailure: enterPhase (BuildFailed msg)       -> emit (BuildAborted msg)
build progress:            modifyPhase … Building progress    -> emit (BuildProgressed p)
test progress / results:   modifyPhase … BuildComplete tests  -> setTests / modifyTests   (NOT a cycle event)
```

### Derived views are pure functions over independent fields

```haskell
isSettled :: BuildState -> Bool            -- what `status --wait` blocks on
isSettled s = case s.cycle of
    Settled  -> testsSettled s.tests && evalsSettled s.evals
    Failed _ -> True
    _        -> False

stateLabel :: BuildState -> Text
stateLabel s = case s.cycle of
    Restarting -> "restarting"
    Building _ -> "building"
    Failed _   -> "error"
    Settled
        | anyError s.build     -> "error"
        | anyWarning s.build   -> "warning"
        | testsRunning s.tests -> "testing"
        | otherwise            -> "ok"
```

No reaching into a nested sum; each is a straight fold over the fields.

### Maximally testable

Feed a `[CycleEvent]` and assert the resulting `BuildState` sequence — which is
exactly what `runPostBuildCapture` was reconstructing by hand. `step` is a pure
function, so the cycle's whole behavior (including the clobber-resistance) is
property-testable without a `TVar`, effects, or concurrency.

### API shape

`BuildStore` narrows to three kinds of operation, replacing the raw
`setPhase` / `modifyPhase` surface:

- `emit :: CycleEvent -> Eff es ()` — the only way to move the cycle/build.
- `setTests` / `modifyTests` (and later evals) — write one downstream register.
- read/wait ops (`getState`, `waitForState`, …) — unchanged.

This is capability narrowing (a producer holding only `setTests` cannot touch the
cycle) delivered by plain functions — no per-task effect, and it is what makes the
`PostBuildStore` effect redundant.

### Open decision: `buildId` granularity

The current code bumps `buildId` per *GHCi session* (`onRestart`), not per reload,
so successive in-session builds share an id. Coherence-with-retention — tagging the
`tests` register so build N+1's diagnostics never sit beside build N's tests —
wants a per-*build* identity, i.e. bumping on `SourceChanged` too (as sketched
above). That changes `WaitForNext`'s "different buildId" semantics, so it needs a
deliberate call:

- **(a) Bump per build** and adjust `WaitForNext` accordingly. Preserves
  cross-cycle retention; needs the id semantics revisited.
- **(b) Keep session-scoped `buildId`** and handle coherence by *resetting*
  downstream registers to `…Idle` when a new build starts. Simpler, but sacrifices
  the retention benefit that motivated separate registers in the first place.
- **(c) Accumulate outputs in a `buildId`-keyed map** (see next section). This
  *dissolves* the decision: builds are separated by key regardless of how often
  the id bumps, and stragglers file themselves under the correct build.

## Output as an accumulator keyed by buildId

The single-latest-value register still leaves a coherence *check*: a straggling
test result for build N-1 arriving after build N has started must be guarded
against (or it clobbers N's register). That guard is the `other -> other`
discipline creeping back one level down. Holding outputs in a **bounded map keyed
by `buildId`** removes it — the key *is* the guarantee:

```haskell
data BuildRecord = BuildRecord
    { build :: BuildOutput
    , tests :: TestOutput
 -- , evals :: EvalOutput
    }

data BuildState = BuildState
    { current    :: BuildId                   -- the in-flight / most recent build
    , cycle      :: CyclePhase                 -- phase of `current`
    , history    :: Map BuildId BuildRecord    -- bounded to the last K builds
    , daemonInfo :: DaemonInfo
    }
```

Each producer writes only `history[current].<its field>`.

> **Correction & resolution (spike).** As written, the key is *not* a
> "no guard to forget" guarantee: a setter that writes `history[s.current]` targets
> `current`-at-arrival, so a write that outran a `current` bump would mis-file.
> **But the spike proved that race is unreachable in this codebase.** The Builder's
> worker is a *single sequential loop* (`watchSourceChanges`' `forever`), and each
> cycle's test-writing drain fibers are `Conc.scoped`-awaited before the cycle
> returns, so `current` never bumps until build N's writes are done —
> `history[current]` therefore always targets the build being written. Safety comes
> from that **sequential-worker + enclosed-drain invariant**, not from the key and
> not from the interrupt/abort discipline (which governs promptness and dropping
> stale progress, not write-targeting). The map key's real job is
> **retention / display**.
>
> If a future refactor ever lets a producer fiber outlive its cycle (fire-and-forget
> runs, parallel test siblings), the sanctioned escalation is ambient captured-id
> via `Reader ActiveBuild` + `Reader.local` — proven to inherit across `Conc.fork`,
> and it keeps producers id-free — but centralized at the single worker entry so the
> wrap cannot be silently omitted (its one failure mode is a forgotten wrap
> mis-filing to a default build). Independently, `overHistoryAt` drops writes whose
> target build has already been evicted, a clean sink for pathological late writes.
> See `spec.md` for the locked contracts.

Obligations this creates:

- **Eviction, not just merge.** A `Map BuildId` grows without bound; a monoid
  gives `<>` but never forgetting. The reducer evicts on `SessionStarted` /
  `SourceChanged`, keeping the last K. K is a single policy knob: **K=2** gives
  "current + previous" (all the greyed-out-retention benefit); **K=∞** would be a
  build-history/timeline *feature* — YAGNI until something asks for it.
- **The per-build value's monoid is last-write-wins, not append.** Within one
  `buildId` the output *evolves* (progress advances; `SuiteRunning → SuiteDone`),
  so the join must let newer states dominate — a `Last`-like merge, not list
  concatenation.
- **Selection policy must stay DRY.** "Let the UI decide what to show" cannot mean
  every reader reinvents build selection. Keep a canonical `current` pointer plus
  `current` / `previous` / `atBuild` helpers, and define `stateLabel` / `isSettled`
  against `history[current]`, so the CLI, TUI, and external clients share one
  selection story.
- **Wire size scales with K.** `BuildState` is serialized on every transition and
  broadcast on the `transitions` channel, so each message now carries K records —
  fine for small K, and a concrete reason not to let K drift to ∞.

**Recommendation:** model it as `Map BuildId BuildRecord` bounded to a small K from
day one (**start K=2**), with the reducer owning insert + eviction + the `current`
pointer, and selection behind helpers. This delivers side-by-side-by-`buildId`
separation, bounds growth and wire size, keeps reader policy in one place, and
grows into a history feature by bumping one constant — no refactor.

**For the spike to decide:** whether threading `current` through every producer
write and every reader stays tidy, or whether the map plumbing out-noises the flat
two-field (`current` / `previous`) version. If the map feels heavy for K=2, fall
back to two fields; the reducer/register split above is unchanged either way.

## `DaemonInfo` is configuration, not state

`daemonInfo` (targets, socket path, watch dirs, metrics port) has been shown
inside `BuildState` above, but it is not *state* in the sense the reducer cares
about: no build / test / eval event ever produces it. It is ambient daemon
configuration, sourced from `Input DaemonInfo` / `loadDaemonInfo`, that only lives
in the state so the `status` response can carry it to the CLI / UI. It is a cache
of an input, parked in the reduced state.

The cost of parking it there is visible in today's interpreter: every
`modifyPhase` / `setPhase` re-reads and re-stamps it into the `TVar`
(`daemonInfo <- input; modifyTVar … \bs -> bs { …, daemonInfo }`) — a refresh that
exists solely to stop the cached copy going stale across a cabal reload. Pure
workaround for keeping ambient config in the reduced state.

Pull it out. The reduced state holds only what build events produce; the daemon
config is joined at the wire boundary:

```haskell
-- Purely reduced state: exactly what `foldl step initial events` produces.
data BuildState = BuildState
    { buildId :: BuildId
    , cycle   :: CyclePhase
    , history :: Map BuildId BuildRecord
    }
    deriving (FromJSON, ToJSON) via Generically BuildState

-- What `status` puts on the wire: state joined with current daemon config.
data Status = Status
    { daemon :: DaemonInfo
    , build  :: BuildState
    }
    deriving (FromJSON, ToJSON) via Generically Status
```

The socket handler reads each from its own source and joins them once, at the edge:

```haskell
handleStatus = Status <$> input @DaemonInfo <*> BuildStore.getState
```

What this improves:

- **`step` / `beginBuild` fold over honest state.** No foreign config to thread;
  `foldl step initial events` is now literally true, because `daemonInfo` — which
  no build event produces — is no longer in the fold. (This is also why it is the
  right move for the event-sourcing question: an input has no place in the log.)
- **The interpreter's write path loses the `input` re-stamp.** `emit` becomes
  `modifyTVar ref (step ev) >> broadcast`, with no `daemonInfo <- input` on every
  transition, and the `Input DaemonInfo` constraint drops off the Builder /
  TestRunner write paths — it is needed only where a response is formed.
- **No stale-config bug class.** Config is read fresh at the edge, so a state
  snapshot can never carry a `daemonInfo` that lagged a cabal reload.
- **Truer change detection.** `WaitForAnyChange` / `Eq` / the transitions channel
  compare build state, not a record that also embeds config.

Cost: the wire gains a `Status` envelope (`{ daemon, build }`), `initialBuildState`
loses its `DaemonInfo` argument, and readers that reached `state.daemonInfo`
(`UI/View`, CLI rendering) switch to `status.daemon` — mechanical, and this
proposal already reshapes the wire. One edge: joining "current" config onto a
possibly-older state snapshot can skew by a config reload, but a cabal reload also
drives the cycle to `Restarting`, so the two move together in practice.

The principle, one more turn: **don't keep in the reduced state anything the
reducer doesn't produce.** `daemonInfo` is an input — join it, don't store it.

## The missing phase: `Settled` is a lie

The sections above still call the cycle `Settled` the instant the build load
finishes. But at that instant the system is not settled — it is about to run, or
running, tests (and soon eval-comments). That "downstream work in progress" state
genuinely exists; the earlier design just never *named* it, so it leaked into the
registers: every "are we done?" reader had to cross-reference
`Settled` with `anyRunningTests (currentSuites s)`. The cycle could not answer
"done?" on its own.

The fix is to name the phase that was always there. The transition is
`build done → analyses running → idle`, and it is **generic over the downstream
task** — tests today, evals tomorrow:

```haskell
data CyclePhase
    = Restarting
    | Building (Maybe BuildProgress)
    | BuildFailed Text          -- no result at all
    | Analysing                 -- build produced a result; post-build analyses running
    | Idle                      -- cycle complete; read the build register for the result
```

`Analysing` deliberately does not mention tests; it is the phase-level home for the
thing PR #263 called "post-build" — which was a real concept, just modelled as an
*effect* (a capability) rather than a *phase* (a state). It is a phase.

### What it simplifies

- **Done-ness becomes a pure `cycle` predicate.** No reader inspects a register to
  decide "are we finished": `isDone = cycle ∈ {Idle, BuildFailed}`. The only
  register a reader still touches is the build register, and only to classify
  `error / warning / ok` — which is inherent (you must read diagnostics to know a
  build errored). Done-ness and classification both peeked before; now only
  classification does.
- **It generalizes to evals for free.** Eval-comments is another register filled
  during `Analysing`: zero new phases, zero reducer changes, zero reader changes.
- **The abort case falls out.** An analysis interrupted by a source change simply
  stays `Analysing` (non-terminal, so no `status --wait` caller wakes) until the
  incoming `SourceChanged` resets the cycle — replacing the spike's manual
  skip-the-transition logic.

### What it costs (and why it's contained)

Materializing done-ness as a phase means the phase and the registers are two
representations that must stay consistent. The mitigation: transitions are
**orchestrator-driven** by the single sequential worker (`afterLoad`), not
auto-detected by the reducer. `afterLoad` fills the register then emits the phase
(`setBuild` before `EnterAnalysis`; the last `setTests` before `AnalysisComplete`),
so `Idle` always implies the outputs are done. The reducer is given **no** counter
and **no** register-scan — that tempting version reintroduces a genuine second
source of truth. The reducer stays a pure phase machine; contents live only in the
registers.

### This subsumes the build/test asymmetry

Because the build result now goes through `setBuild` like every other output, the
reducer never writes output contents — but unlike bare "unify on setters", the
cycle no longer *ignores* downstream work; it honestly represents it. The final
ownership split:

- **Reducer** — phase (incl. `Analysing` / `Idle`) + history *structure*
  (slot insert / evict). Pure; never inspects or writes contents.
- **Setters** — output *contents*: `setBuild` / `setTests` / `setEvals`, symmetric.
- **Orchestrator** (`afterLoad`) — drives the phase transitions and runs analyses.

`BuildFinished BuildResult` was itself a tiny "product wearing a sum's clothing" —
one event carrying both a transition trigger and a data payload. Splitting it into
`EnterAnalysis` (phase) + `setBuild` (contents) finishes the same move we began by
splitting `BuildPhase`.

## Consolidated final shape

Folding the three post-spike refinements together (drop stored `current`; extract
`daemonInfo`; formalize the post-build phase), the reduced state is two fields:

```haskell
data BuildState = BuildState
    { cycle   :: CyclePhase                 -- Restarting | Building | BuildFailed | Analysing | Idle
    , history :: Map BuildId BuildRecord    -- K = 2; currentId = max key
    }
```

- `current` is derived (`currentId = maybe 0 fst . Map.lookupMax . history`), never
  stored — so it cannot disagree with the map keys.
- `daemonInfo` lives on the `Status { daemon, build }` wire envelope, joined at the
  edge from `Input DaemonInfo`.
- The reducer owns phase + which-builds-exist; setters own build/test/eval contents;
  `afterLoad` orchestrates.

`spec.md` holds the locked contracts (event set, `step`, `beginBuild`, setter
semantics, wire format, straggler invariant).
