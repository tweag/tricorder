# Spec: Decouple Build State into Cycle and Registers

## Status

Draft. Read `design.md` first for context and rationale. This document is the
reference during implementation. It consolidates the original spike (full library
+ tests ported green: `354` tricorder + `218` atelier) with three refinements
agreed after it:

1. **Drop the stored `current` field** — derive `currentId` from `history`'s max key.
2. **Extract `daemonInfo`** out of the reduced state into a `Status` wire envelope.
3. **Formalize the post-build phase** — the cycle gains `Analysing` / `Idle`, so
   "done-ness" is a pure `cycle` check instead of register inspection; all output
   data (build included) is written by symmetric setters, and the reducer never
   writes output contents.

The spike branch still reflects the pre-refinement shape; this spec is the target.

---

## 1. Types

### 1.1 Reduced build state

Only what build/test/eval events produce. No `current` (derived, §1.5), no
`daemonInfo` (joined at the edge, §6).

```haskell
data BuildState = BuildState
    { cycle   :: CyclePhase
    , history :: Map BuildId BuildRecord   -- bounded to the last K builds (K = 2)
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState

initialBuildState :: BuildState
initialBuildState = BuildState
    { cycle   = Building Nothing
    , history = Map.singleton (BuildId 0) emptyRecord   -- history is never empty
    }
```

### 1.2 Cycle phase

The full progression a build cycle moves through:

```haskell
data CyclePhase
    = Restarting                    -- session teardown/reload in progress
    | Building (Maybe BuildProgress)-- GHCi load running
    | BuildFailed Text              -- load produced NO result (startup crash / reload threw)
    | Analysing                     -- build produced a result; post-build analyses running
    | Idle                          -- cycle complete; read history[current].build for the result
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically CyclePhase
```

- `Analysing` is **generic** over the downstream task — tests today, eval-comments
  later run in the same phase, each filling its own register. Adding a downstream
  task requires **no** new phase and **no** reducer change.
- `BuildFailed Text` (no result) is distinct from "a build that completed with
  error diagnostics", which is `cycle = Idle` with
  `history[current].build = Built (BuildResult{ diagnostics = …errors… })`.
- `stateLabel` distinguishes `error`/`warning`/`ok` for `Idle` by reading the build
  register's diagnostics (data), but **done-ness never inspects a register** (§5).

### 1.3 Output records

```haskell
data BuildRecord = BuildRecord
    { build :: BuildOutput
    , tests :: TestOutput
 -- , evals :: EvalOutput           -- future: another register, no cycle change
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildRecord

data BuildOutput = NotBuilt | Built BuildResult
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildOutput

data TestOutput = TestsIdle | TestsRunning Test.Suites | TestsDone Test.Suites
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically TestOutput

emptyRecord :: BuildRecord
emptyRecord = BuildRecord { build = NotBuilt, tests = TestsIdle }
```

`BuildResult` is unchanged (`completedAt`, `duration`, `moduleCount`,
`diagnostics`).

### 1.4 Constants

```haskell
historyBound :: Int
historyBound = 2   -- "current + previous"; retention/display only, NOT a correctness knob
```

### 1.5 Derived current build

`current` is not stored. It is always the greatest key present (a new build inserts
at `max+1`; eviction only ever drops the smallest keys, never the max):

```haskell
currentId :: BuildState -> BuildId
currentId = maybe (BuildId 0) fst . Map.lookupMax . history
```

This removes the coherence obligation that a stored `current` equal the map's keys —
it is true by construction.

---

## 2. The cycle reducer

The reducer owns **phase** and **history structure** (which build ids exist). It
**never writes output contents** (that is the setters' job, §3).

### 2.1 Events

```haskell
data CycleEvent
    = SourceChanged                 -- debounced source edit: begin a new build
    | CabalChanged                  -- .cabal/package.yaml edit: restart the session
    | SessionStarted                -- a fresh GHCi session came up post-restart
    | BuildProgressed BuildProgress -- [N of M] Compiling … during a load
    | EnterAnalysis                 -- Building -> Analysing (clean build; analyses will run)
    | AnalysisComplete              -- (Building | Analysing) -> Idle (cycle finished)
    | BuildAborted Text             -- -> BuildFailed (GHCi produced no result)
```

### 2.2 `step`

```haskell
step :: BuildState -> CycleEvent -> BuildState
step s = \case
    CabalChanged      -> s { cycle = Restarting }            -- wins over a just-finished build
    SessionStarted    -> beginBuild s
    SourceChanged     -> beginBuild s
    BuildProgressed p -> case s.cycle of
        Building _ -> s { cycle = Building (Just p) }         -- only advance a live build
        _          -> s
    EnterAnalysis     -> case s.cycle of
        Restarting -> s                                       -- restart wins
        _          -> s { cycle = Analysing }
    AnalysisComplete  -> case s.cycle of
        Restarting -> s                                       -- restart wins
        _          -> s { cycle = Idle }
    BuildAborted msg  -> case s.cycle of
        Restarting -> s
        _          -> s { cycle = BuildFailed msg }
```

Invariants (all covered by pure `step` tests):

- **`Restarting` absorbs every stale terminal transition** (`EnterAnalysis` /
  `AnalysisComplete` / `BuildAborted`). This single pattern is the entire
  `Restarting`-clobber fix; it replaces the old scattered `other -> other` guards.
- `BuildProgressed` only advances a live `Building`; a late progress line never
  resurrects `Analysing` / `Idle` / `Restarting` / `BuildFailed`. (This also fixes
  a latent bug: the old GhciSession progress callback did `modifyPhase \_ -> Building`.)
- The reducer touches `history` **only** for slot lifecycle (`beginBuild`), never
  to fill an output value.

### 2.3 `beginBuild` and eviction

```haskell
-- Start a new cycle: reset the phase, seed an empty record under the next id,
-- evict to K. Total construction; no mempty (no lawful Monoid — history must be
-- carried, and the next id is a bump, not a reset).
beginBuild :: BuildState -> BuildState
beginBuild s =
    let next = maybe (BuildId 0) ((+ 1) . fst) (Map.lookupMax s.history)
    in  s { cycle   = Building Nothing
          , history = evictHistory historyBound (Map.insert next emptyRecord s.history)
          }

-- Insert-then-keep-last-K. Keys are BuildId (ordered); keep the K greatest.
evictHistory :: Int -> Map BuildId BuildRecord -> Map BuildId BuildRecord
evictHistory k m
    | Map.size m <= k = m
    | otherwise       = Map.fromDistinctAscList . drop (Map.size m - k) . Map.toAscList $ m
```

---

## 3. Output writes and the straggler invariant

### 3.1 Setters (symmetric — build is not special)

All output *contents* are written by setters targeting `history[currentId]`:

```haskell
setBuild    :: BuildStore :> es => BuildOutput -> Eff es ()
setTests    :: BuildStore :> es => TestOutput -> Eff es ()
modifyTests :: BuildStore :> es => (TestOutput -> TestOutput) -> Eff es ()
-- future: setEvals / modifyEvals

overHistoryAt :: BuildId -> (BuildRecord -> BuildRecord) -> BuildState -> BuildState
overHistoryAt bid f s = s { history = Map.adjust f bid s.history }   -- no-op if bid evicted
```

`reportTestProgress` is a `modifyTests` (`TestsRunning suites -> …; other -> other`)
and needs **no** access to `currentId`.

### 3.2 Load-bearing invariant (do not break without §3.3)

`history[currentId]` is the correct target because **no output write outlives its
cycle**: `watchSourceChanges` runs a single sequential worker (build N's
`onSourceChange` completes before build N+1 bumps the id), and each cycle's
progress/drain fibers are `Conc.scoped`-awaited before the cycle returns. So the max
key never advances while a write for the current build is in flight. Safety is a
property of the **sequential-worker + enclosed-drain** structure — not the map key,
and not the interrupt/abort discipline (which governs promptness and stale-progress
gating only).

`overHistoryAt` additionally **drops a write whose build has been evicted**
(`Map.adjust` is a no-op on a missing key) — a clean sink for any pathological late
write.

### 3.3 Sanctioned escalation (only if §3.2 is broken)

If a future change lets a producer fiber outlive its cycle (fire-and-forget runs,
parallel siblings), bind the captured id ambiently and target it in the setters:

```haskell
data ActiveBuild = ActiveBuild BuildId              -- distinct from currentId
Reader.local (const (ActiveBuild bid)) (<cycle body>)   -- centralized at the ONE worker entry
modifyTests f = do { ActiveBuild bid <- ask; BuildStore.overHistoryAt bid f }
```

Proven by the spike (`Conc.fork` inherits the binding). **Do not adopt
pre-emptively** — under §3.2 it is behaviourally identical and adds a silent-failure
mode (a forgotten `local` wrap mis-files to a default build).

---

## 4. `BuildStore` effect surface

Replaces the old `setPhase` / `modifyPhase` writers.

```haskell
data BuildStore :: Effect where
    Emit             :: CycleEvent -> BuildStore m ()          -- the only cycle/structure mutator
    SetBuild         :: BuildOutput -> BuildStore m ()
    SetTests         :: TestOutput -> BuildStore m ()
    ModifyTests      :: (TestOutput -> TestOutput) -> BuildStore m ()
    GetState         :: BuildStore m BuildState
    WaitUntilDone    :: BuildStore m BuildState
    WaitForNext      :: BuildId -> BuildStore m BuildState
    WaitForAnyChange :: BuildState -> BuildStore m BuildState
    MarkDirty        :: ChangeKind -> BuildStore m ()
    WaitDirty        :: BuildStore m ChangeKind
    HasWaiters       :: BuildStore m Bool
```

- Production interpreter: each mutator updates the `TVar` (via `step` /
  `overHistoryAt`) **and** broadcasts the new `BuildState` on the `transitions`
  channel in one STM transaction. **No `daemonInfo <- input` re-stamp** (§6).
- `WaitForNext bid` predicate: `isDone s && currentId s /= bid`. Because the id
  bumps **per build**, this resolves the old buildId-granularity open decision.
- The transient-terminal-not-missed guarantee (the `dupTChan`-before-read waiter) is
  unchanged; keep the ported STM regression test.

---

## 5. Readers — done-ness is a pure cycle check

The point of §1.2: no reader inspects a register to decide "are we done / what phase":

```haskell
isDone :: BuildState -> Bool                       -- what `status --wait` blocks on
isDone s = case s.cycle of
    Idle          -> True
    BuildFailed _ -> True
    _             -> False

stateLabel :: BuildState -> Text
stateLabel s = case s.cycle of
    Restarting    -> "restarting"
    Building _    -> "building"
    Analysing     -> "checking"                    -- generic: tests + evals
    BuildFailed _ -> "error"
    Idle          -> classify (currentBuild s)      -- error/warning/ok, from diagnostics only
```

Selection helpers return the **output types**, so readers never dot into
`BuildRecord`'s fields (avoids a `DuplicateRecordFields` + `HasField` import trap the
spike hit):

```haskell
currentRecord :: BuildState -> BuildRecord           -- history[currentId], default emptyRecord
currentBuild  :: BuildState -> BuildOutput
currentTests  :: BuildState -> TestOutput
atBuild       :: BuildId -> BuildState -> Maybe BuildRecord
```

`UI/View.hs`, `Socket/Server.hs`, `CLI.hs` migrate off `.phase` matching onto
`.cycle` + these helpers.

---

## 6. Wire format — **BREAKING CHANGE**

`daemonInfo` is joined onto the response at the edge, not stored in state:

```haskell
data Status = Status
    { daemon :: DaemonInfo
    , build  :: BuildState
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically Status

handleStatus = Status <$> input @DaemonInfo <*> BuildStore.getState
```

Required instance (the only serialization addition):

```haskell
newtype BuildId = BuildId Int
    deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey)   -- Map key: JSON keys are strings
```

Breaking-change checklist:

- Top-level `buildId` / `phase` are **gone** (→ `cycle` / `history`); `daemonInfo`
  moves under `Status.daemon`. Every client breaks: `status`, `status --json`,
  `watch`, and the **plugin skill's documented JSON schema**.
- The daemon/client version check is gitHash-based and only **warns**, so a stale
  client silently gets a decode failure. Bump/gate the protocol explicitly.
- Payload scales with `K`: a full `BuildResult` + suites are duplicated per history
  entry, broadcast on every transition. `K = 2` is fine; this is the reason not to
  raise it.
- The `Status` DTO **may** expose a derived `current :: BuildId` for client
  convenience (computed from `build.history`), so clients need not reimplement the
  max-key rule.

---

## 7. Orchestration (`afterLoad`)

The single sequential worker owns the phase progression and runs the analyses. It
reads as a script; the reducer just applies the transitions it emits.

```haskell
afterLoad config nlr = do
    r <- compileLoadResultsIntoBuildResults config nlr
    setBuild (Built r)                                   -- data first …
    if noErrors r && hasTargets config.testTargets
        then do
            emit EnterAnalysis                           -- Building -> Analysing
            runTestsForTargets config.testTargets >>= \case
                Aborted    -> pure ()                    -- new build imminent: leave Analysing,
                                                         -- beginBuild will reset it (no stale Idle)
                NotAborted -> emit AnalysisComplete       -- Analysing -> Idle
        else emit AnalysisComplete                        -- Building -> Idle (errors or no targets)
```

Ordering contract: **publish output before signalling the phase that exposes it**
(`setBuild` before `emit`, `setTests` before `emit AnalysisComplete`), so a reader
never sees `Idle` with a stale/absent build result. The abort case relies on
`Analysing` not being terminal: an interrupted analysis stays `Analysing` (so
`isDone` is False and no waiter wakes) until the incoming `SourceChanged` /
`SessionStarted` resets the cycle.

`runTestsForTargets` uses `setTests` / `modifyTests` only — it emits no cycle events.

---

## 8. Removals

- `Tricorder.Effects.PostBuildStore` — deleted (module + all interpreters).
- `Builder`: `enterPhase`, `setNewPhase`, `EnteringNewPhase`, and the post-test
  non-clobber dance in `afterLoad` — gone.
- `State BuildId` in the Builder — now vestigial (the reducer / `currentId` own the
  id; the old state was session-scoped and diverged). **Drop it.** If the "session
  #N" log line is worth keeping, add a separately named `SessionId`, not an overload
  of `BuildId`.

---

## 9. Verification target

- `/tricorder` clean (no warnings); `test:tricorder-test` + `test:atelier-test` green.
- New pure `step` tests: the `Restarting`-absorbs-stale-terminal invariants, the
  `Building → Analysing → Idle` and `Building → Idle` (no-analysis) paths, and
  `beginBuild` id derivation + eviction (K=2).
- New `currentId` / derivation tests (empty-seed, post-evict max-key).
- Ported STM regression: transient terminal phase observed even if a new `Building`
  immediately follows.
- Behaviour parity with pre-refactor on: clean build, error build, test run, cabal
  restart — via `status`, `status --wait`, and the TUI.
- Production quality: fourmolu-formatted, `nix-hpack` clean if any module was added,
  no compiler warnings.

---

## 10. Open questions

- **Client protocol versioning:** the wire break is silent for stale clients (warn
  only). Decide hard-fail vs graceful negotiation, and update the plugin skill's
  documented JSON schema.
- **`Analysing` label text** (`"checking"` vs `"analysing"` vs `"testing"`) — pick
  one that reads well and stays accurate once evals land.
- **`cycle` field name** is safe only because `atelier-prelude` does not export
  `cycle`; add a comment so it is not re-exported later.
- **`ActiveBuild` prototype** (spike branch) — drop unless §3.3 becomes real.
