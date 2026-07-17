# atelier-observe

Side-channel observation of **oblivious** [Effectful](https://github.com/haskell-effectful/effectful) programs. Instrument a program from the outside, watch it run as a stream of moments, and fold that stream however you like — without the program ever knowing it is watched. Part of the **atelier** toolkit.

## The shape

Three stages, kept deliberately apart:

- **Produce** — a `Tap` interposes on one oblivious effect to emit signals on each region boundary (and a `Sampler` brackets each region to read a resource like wall-clock or allocation). A `Plan` assembles taps and samplers; merge with `<>`.
- **Stream** — discharging a `Plan` over a run turns it into a `Moment` stream: `Entered` / `Exited` / `Failed` / `Measured`. This is the one artifact at the centre, and it maps onto OpenTelemetry as span-start / span-end / span-end-with-error / span-metric.
- **Fold** — a `Consumer` is a left fold (`Control.Foldl.FoldM`) over that stream into a harvest. What the harvest *is* is entirely the consumer's business: an event log, an aggregate, a streaming exporter.

```haskell
(result, harvest) <- observe someConsumer somePlan program
```

The discharge is a side channel: a `Consumer` is *only* a fold, so it can never change what the program computes. `observe` brackets the consumer's start/stop, so an exporter still flushes when the program throws.

## A worked example

Say we have a `Db` effect with two operations — one that brackets a block, one that runs a statement:

```haskell
data Db :: Effect where
    WithTransaction :: m a -> Db m a       -- higher-order: carries a block
    Execute         :: Sql -> Db m ()      -- first-order: a point
```

We name our own observation vocabulary — the regions we want to see, and what a signal is:

```haskell
data Region = Transaction | Query    deriving (Eq, Ord, Show)  -- the span-like scopes
data Signal = Attr Text Text                                   -- one key/value attribute
```

### Two taps — one higher-order, one first-order

A **first-order** tap watches an operation as a *point*: `Execute` happens, emit an attribute. A **higher-order** tap wraps the *action an operation carries*: `WithTransaction` hands you a block, and `wrap` turns it into a region everything inside nests under.

```haskell
-- the block becomes a Transaction region; everything inside nests under it
txnTap = nesting SeqUnlift (const Transaction) $ \wrap -> \case
    WithTransaction action -> WithTransaction (wrap action)
    other                  -> other

-- each statement is its own Query region, tagged with the SQL
execTap = watch (const Query)
    & entering (\(Execute (Sql s)) -> [Attr "db.sql" s])
```

### Building a tap: `tapping` is the preferred surface

`execTap` above uses the `watch` / `entering` setter chain — each setter pattern-matches the effect once, per lane. That reads fine for a one-operation effect, but for a bigger effect every lane repeats the same `\case`, and it is easy to leave one non-exhaustive. **`tapping` is the preferred way to build a first-order tap:** match the operation *once* and declare all its facets together in a `do` block. The operation's result type is refined by the match, so `exitWith` reads the result directly — no re-match, no catch-all:

```haskell
kvTap = tapping \case
    Put k v -> do
        atRegion  (Region "put")
        enterWith [Attr "key" k, Attr "val" v]
    Get k -> do
        atRegion  (Region "get")
        enterWith [Attr "key" k]
        exitWith  \mv -> [Attr "hit" (maybe "miss" (const "hit") mv)]   -- result refined to Maybe here
    Wipe -> pure ()                                                     -- no atRegion ⇒ opens no region
```

The commands mirror the setters — `atRegion` (region), `underTrace` (trace), `linkTo` (links), `enterWith` / `exitWith` / `failWith` / `tagWith` (the signal lanes) — and a branch that omits `atRegion` opens no region, the mixed-effect case (an untapped barrier operation). `tapping` compiles to exactly the same record a setter chain does, so it merges with `<>` and composes with `nesting` / `rerooting` like any tap. It is a **first-order** surface: the higher-order wrapping (`nesting` / `rerooting`) stays a separate tap, combined via `<>`.

### Scope signals: tag a whole subtree

`enterWith` / `exitWith` / `failWith` (and the `entering` / `leaving` / `failing` setters) attach a signal to **this region's own moment**. A **scope signal** — `tagWith`, or the `tagging` setter — is different: it is in effect over the region *and every region nested inside it*, riding the `MomentCtx.tags` of every descendant moment. It is the seam for tagging a whole subtree with something a consumer can then filter or attribute by — a component name, a request id, a tenant:

```haskell
componentTap = tapping \case
    RunSupervised name _ -> do
        atRegion (Component name)
        tagWith  [Attr "component" name]   -- rides every moment the component produces
```

Every span the component emits then carries `component = name`, so a backend query (or a `Control.Foldl.prefilter` over the `Moment` stream on `tags`) selects the whole subtree. Scope signals never change control flow — like every other lane, they are pure observation.

### The program is oblivious

```haskell
program = withTransaction $ do
    execute "insert into orders …"
    execute "update stock …"
```

No taps, no `observe`, no `Region` — plain business code. It compiles and runs identically with the observation stripped out.

### A consumer, and the run

```haskell
trace = eachMoment \case
    Entered ctx _ sigs -> liftIO $ putStrLn ("→ " <> render ctx sigs)
    Exited  ctx _      -> liftIO $ putStrLn ("← " <> show (path ctx))
    _                  -> pure ()
  where render ctx sigs = show (path ctx) <> " " <> show [ (k, v) | Attr k v <- sigs ]

run = observe trace (tap txnTap <> tap execTap) program
--                    ^^^^^^^^^^^^^^^^^^^^^^^^^ the Plan: both effects, merged with <>
```

Running it prints the nesting the taps produced — each `Query`'s `path` carries `Transaction` as its parent, for free:

```
→ [Transaction] []
→ [Transaction,Query] [("db.sql","insert into orders …")]
← [Transaction,Query]
→ [Transaction,Query] [("db.sql","update stock …")]
← [Transaction,Query]
← [Transaction]
```

The only line that mentions observation is `run`. To change *what* you observe, swap the consumer — not a line of `program`: `eachMoment` for live logging, `foldMoments` to accumulate a summary returned beside the result as `(a, harvest)`, or a streaming exporter to ship the same `Moment` stream to OpenTelemetry, where `[Transaction, Query]` becomes a parent/child span pair. Same `program`, same `Plan`, different fold.

## Modules

- **`Atelier.Observe`** — the irreducible core: `Tap`, `Plan`, `Consumer`, `Moment`, and the `observe` / `observeInto` / `silent` discharges.
- **`Atelier.Observe.Aggregate`** — one summary *policy*: a `Region` trie of two-laned `Report`s keyed into `Traces`, with the `collecting` consumer. It is a pure function of the public `Moment` stream, so the core never depends on it — a flat log or a streaming exporter pulls in none of it.

## Part of atelier

- [`atelier-prelude`](https://github.com/atelier-hub/tricorder/tree/main/atelier-prelude) — relude-based custom prelude adapted for Effectful
- [`atelier-core`](https://github.com/atelier-hub/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-observe`](https://github.com/atelier-hub/tricorder/tree/main/atelier-observe) — this package
- [`atelier-db`](https://github.com/atelier-hub/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/atelier-hub/tricorder/tree/main/atelier-testing) — database-backed test utilities

## License

MIT — see [LICENSE](LICENSE).
