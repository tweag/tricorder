# Spec: Decouple Build State into Cycle and Registers

## Status

Draft. Read `design.md` first for context and rationale. This document is the
reference during implementation and reflects an end-to-end implementation spike:
full library + tests ported, compiler-clean, `354` tricorder + `218` atelier tests
passing, `/tricorder` reporting `All good. (148 modules)`. Shapes below are the
ones the spike locked in; deviations from `design.md` are called out inline.

---

## 1. Types

### 1.1 Reduced build state

`daemonInfo` is **not** part of the reduced state (§6). `BuildState` holds only
what build/test/eval events produce:

```haskell
data BuildState = BuildState
    { current :: BuildId                  -- the latest build cycle
    , cycle   :: CyclePhase               -- phase of `current`
    , history :: Map BuildId BuildRecord  -- bounded to the last K builds (K = 2)
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildState
```

### 1.2 Cycle phase

```haskell
data CyclePhase
    = Restarting
    | Building (Maybe BuildProgress)
    | Settled                 -- the load ran to completion; see history[current].build
    | Failed Text             -- GHCi produced no result (startup crash / reload threw)
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically CyclePhase
```

`Failed Text` is the old `BuildFailed Text` and is distinct from "a build that
completed with error diagnostics" — the latter is `cycle = Settled` with
`history[current].build = Built (BuildResult{ diagnostics = …errors… })`.

### 1.3 Producer outputs

```haskell
data BuildRecord = BuildRecord
    { build :: BuildOutput
    , tests :: TestOutput
 -- , evals :: EvalOutput           -- future: another register, no cycle change
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildRecord

data BuildOutput
    = NotBuilt
    | Built BuildResult
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically BuildOutput

data TestOutput
    = TestsIdle
    | TestsRunning Test.Suites
    | TestsDone Test.Suites
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Generically TestOutput
```

`BuildResult` is unchanged (`completedAt`, `duration`, `moduleCount`,
`diagnostics`).

### 1.4 Constants

```haskell
historyBound :: Int
historyBound = 2   -- "current + previous"; retention only, NOT a correctness knob
```

---

## 2. The cycle reducer

### 2.1 Events (exactly six — no seventh was needed)

```haskell
data CycleEvent
    = SourceChanged                 -- debounced source edit: begin a new build
    | CabalChanged                  -- .cabal/package.yaml edit: restart the session
    | SessionStarted                -- a fresh GHCi session came up post-restart
    | BuildProgressed BuildProgress -- [N of M] Compiling … during a load
    | BuildFinished BuildResult     -- load completed and produced a result
    | BuildAborted Text             -- GHCi produced no result (startup crash / reload threw)
```

### 2.2 `step`

```haskell
step :: BuildState -> CycleEvent -> BuildState
step s = \case
    CabalChanged      -> s { cycle = Restarting }               -- wins over stale finishes
    SessionStarted    -> beginBuild s
    SourceChanged     -> beginBuild s
    BuildProgressed p -> case s.cycle of
        Building _ -> s { cycle = Building (Just p) }
        _          -> s                                          -- never resurrect a settled cycle
    BuildFinished r   -> case s.cycle of
        Restarting -> s                                          -- drop a result that lost to a restart
        _          -> settle r s
    BuildAborted msg  -> case s.cycle of
        Restarting -> s
        _          -> s { cycle = Failed msg }
```

Invariants (all covered by pure `step` tests):

- `Restarting` absorbs a stale `BuildFinished` / `BuildAborted` (this replaces the
  old scattered `other -> other` clobber guards; it is the entire race fix).
- `BuildProgressed` only advances a live `Building`; a late progress line never
  resurrects `Settled` / `Restarting` / `Failed`. (This also fixes a latent bug:
  the old GhciSession progress callback did `modifyPhase \_ -> Building`, ignoring
  the current phase.)

### 2.3 `beginBuild`, `settle`, eviction

```haskell
-- Total construction: every field named, so a new field forces a decision here.
-- daemonInfo is absent by design (§6); no mempty (no lawful Monoid; history must
-- be carried, buildId bumped not zeroed).
beginBuild :: BuildState -> BuildState
beginBuild prev =
    let next = prev.current + 1
    in  BuildState
            { current = next
            , cycle   = Building Nothing
            , history = evictHistory historyBound
                          (Map.insert next emptyRecord prev.history)
            }

settle :: BuildResult -> BuildState -> BuildState
settle r s = s
    { cycle   = Settled
    , history = Map.adjust (\rec -> rec { build = Built r }) s.current s.history
    }

emptyRecord :: BuildRecord
emptyRecord = BuildRecord { build = NotBuilt, tests = TestsIdle }

-- Insert-then-keep-last-K. Keys are BuildId (ordered), so keep the K greatest.
evictHistory :: Int -> Map BuildId BuildRecord -> Map BuildId BuildRecord
evictHistory k m
    | Map.size m <= k = m
    | otherwise       = Map.fromDistinctAscList . drop (Map.size m - k) . Map.toAscList $ m
```

---

## 3. Output writes and the straggler invariant

### 3.1 Contract

Test (and future eval) producers write only their register in `history[current]`:

```haskell
setTests    :: BuildStore :> es => TestOutput -> Eff es ()
modifyTests :: BuildStore :> es => (TestOutput -> TestOutput) -> Eff es ()
```

The interpreter targets `history[current]` and **drops the write if that build is
absent** (already evicted), never recreating it:

```haskell
overHistoryAt :: BuildId -> (BuildRecord -> BuildRecord) -> BuildState -> BuildState
overHistoryAt bid f s = s { history = Map.adjust f bid s.history }   -- Map.adjust is a no-op if absent
```

`reportTestProgress` is a `modifyTests` (`TestsRunning suites -> …; other -> other`)
and needs **no** access to `current` — confirmed clean by the spike.

### 3.2 Load-bearing invariant (do not break without §3.3)

`history[current]` is the correct target because **no test-state write outlives its
cycle**:

- `watchSourceChanges` runs a **single sequential worker**; build N's
  `onSourceChange` completes before build N+1 starts and bumps `current`.
- Each cycle's progress/drain fibers are `Conc.scoped`-awaited (in
  `execGhci` / `setupGhciProcess`) before the cycle returns.

Therefore `current` never advances while a write for the current build is still in
flight. Safety is a property of the **sequential-worker + enclosed-drain**
structure — not of the map key, and not of the interrupt/abort discipline (which
governs promptness and stale-progress gating only). Any change that lets a producer
fiber outlive its cycle (fire-and-forget test runs, parallel siblings) breaks this
and requires §3.3.

### 3.3 Sanctioned escalation (only if §3.2 is broken)

Bind the captured build id ambiently and target it in the setters:

```haskell
data ActiveBuild = ActiveBuild BuildId          -- distinct from BuildState.current

-- centralized at the single worker entry, so it cannot be silently omitted:
Reader.local (const (ActiveBuild newBid)) (<reload + afterLoad + tests>)

modifyTests f = do { ActiveBuild bid <- ask; BuildStore.overHistoryAt bid f }
```

Proven by the spike: `Conc.fork` inherits the `Reader.local` binding, and an
`ask`-bound write files under the captured build even after `current` bumps. **Do
not adopt this pre-emptively** — under §3.2 it is behaviourally identical to the
`current`-based setter and introduces a silent-failure mode (a forgotten `local`
wrap mis-files to a default build).

---

## 4. `BuildStore` effect surface

Replaces the old `setPhase` / `modifyPhase` writers.

```haskell
data BuildStore :: Effect where
    Emit             :: CycleEvent -> BuildStore m ()            -- the only cycle/build mutator
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
  channel in one STM transaction. No `daemonInfo <- input` re-stamp (§6).
- `WaitForNext bid` predicate becomes `s.current /= bid` (and settled). Because
  `current` bumps **per build** (not per GHCi session), this resolves the
  `design.md` "buildId granularity" open decision in favour of per-build ids.
- The transient-`Settled`-not-missed guarantee is preserved unchanged (the
  `dupTChan`-before-read waiter); re-proven by the ported STM regression test.

Blocking predicates derive from `cycle` + `currentRecord` (§5), e.g.:

```haskell
isBuilding :: BuildState -> Bool
isBuilding s = case s.cycle of
    Building _ -> True
    Restarting -> True
    Failed _   -> False
    Settled    -> anyRunningTests (currentSuites s)
```

---

## 5. Readers and selection helpers

Expose helpers that return the **output types**, so readers never dot into
`BuildRecord`'s fields (avoids a real `DuplicateRecordFields` + `HasField` import
trap the spike hit):

```haskell
currentRecord  :: BuildState -> BuildRecord           -- lookup current, default emptyRecord
previousRecord :: BuildState -> Maybe BuildRecord
atBuild        :: BuildId -> BuildState -> Maybe BuildRecord
currentBuild   :: BuildState -> BuildOutput            -- readers use these …
currentTests   :: BuildState -> TestOutput             -- … not `.build` / `.tests`
```

`stateLabel`, `isSettled`, `isBuilding` are pure folds over `cycle` +
`currentRecord`:

```haskell
stateLabel :: BuildState -> Text
stateLabel s = case s.cycle of
    Restarting -> "restarting"
    Building _ -> "building"
    Failed _   -> "error"
    Settled
        | any ((== SError)   . (.severity)) diags -> "error"
        | any ((== SWarning) . (.severity)) diags -> "warning"
        | anyRunningTests (currentSuites s)        -> "testing"
        | otherwise                                -> "ok"
      where diags = currentDiagnostics s
```

`UI/View.hs`, `Socket/Server.hs`, `CLI.hs` migrate off `.phase` pattern-matching
onto `.cycle` + these helpers. Churn is mechanical (confirmed by spike).

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
-- BuildId is the Map key; JSON object keys are strings.
newtype BuildId = BuildId Int
    deriving newtype (FromJSON, ToJSON, FromJSONKey, ToJSONKey)
```

Breaking-change checklist:

- Top-level `buildId` / `phase` are **gone** (→ `current` / `cycle` / `history`),
  and `daemonInfo` moves under `Status.daemon`. Every client breaks: `status`,
  `status --json`, `watch`, and the **plugin skill's documented JSON schema**.
- The daemon/client version check is gitHash-based and only **warns**, so a stale
  client silently gets a decode failure. Bump/gate the protocol explicitly.
- Payload scales with `K`: a full `BuildResult` (diagnostics) + suites are
  duplicated per history entry, broadcast on every transition. `K = 2` is fine;
  this is the concrete reason not to raise it.
- `initialBuildState` loses its `DaemonInfo` argument.

---

## 7. Removals

- `Tricorder.Effects.PostBuildStore` — deleted (module + all interpreters). Nothing
  else imports it once Builder is migrated.
- `Builder`: `enterPhase`, `setNewPhase`, `EnteringNewPhase`, and the post-test
  non-clobber dance in `afterLoad` (`case curr.phase of Restarting … BuildComplete …`)
  — all gone. `afterLoad` emits `BuildFinished` immediately and lets tests populate
  the register.
- `State BuildId` in the Builder is now **vestigial** — the reducer owns `current`,
  and the old `State BuildId` only fed log lines and *diverged* (session-scoped vs
  per-build). **Recommendation: drop it.** If a session counter is wanted for logs,
  introduce a separately named `SessionId` rather than overloading `BuildId` (see
  §8).

---

## 8. Open questions

- **`daemonInfo` → `Status` split is recommended but NOT spiked.** The spike kept
  `daemonInfo` in `BuildState` (it already compiled). Validate the reader churn and
  confirm no aeson friction from the `Status` envelope during implementation.
- **`State BuildId` disposition:** drop entirely, or reintroduce a named `SessionId`
  for the "session #N" log lines? Recommendation: drop; add `SessionId` only if the
  logs are deemed worth it.
- **Client protocol versioning:** the wire break is silent for stale clients (warn
  only). Decide hard-fail vs graceful negotiation, and update the plugin skill's
  documented schema.
- **`cycle` field name** is safe only because `atelier-prelude` does not export
  `cycle`; add a comment so it is not re-exported later.
