-- | Properties of the observation framework in "Atelier.Observe". Signals ride the region boundaries:
-- a 'Tap' has 'onEnter'\/'onLeave'\/'onError', and they fire into 'Entered'\/'Exited'\/'Failed'. The
-- taps are built with the 'watch'\/'leaving'\/'tracedBy' setters. One property pins the headline win —
-- input captured on entry survives an operation that throws, which then closes as 'Failed' carrying
-- its 'onError' signals. 'rollUp' is checked to roll the observation lane while leaving the inclusive
-- measurement lane.
module Unit.ObserveFrameworkSpec (spec_ObserveFramework) where

import Control.Concurrent.MVar (MVar, newEmptyMVar, tryReadMVar)
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.Map.Monoidal (MonoidalMap)
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, IOE, UnliftStrategy (SeqUnlift), runEff, runPureEff)
import Effectful.Concurrent (Concurrent, forkIO, runConcurrent)
import Effectful.Concurrent.Chan (newChan, readChan, writeChan)
import Effectful.Concurrent.MVar (putMVar, readMVar)
import Effectful.Dispatch.Dynamic (interpose, interpret, localSeqUnlift, send)
import Effectful.Error.Static (Error, runErrorNoCallStack, throwError)
import Effectful.State.Static.Local (runState)
import Effectful.Writer.Static.Local (Writer, runWriter, tell)
import Test.Hspec (Spec, describe, it, shouldBe)
import Prelude hiding (trace)

import Control.Exception qualified as E
import Data.Map.Monoidal qualified as MMap
import Data.Set qualified as Set
import Data.Text qualified as Text

import Atelier.Observe
    ( Consumer
    , Link (..)
    , Moment (..)
    , MomentCtx (MomentCtx)
    , Observed
    , Observes
    , OverActions
    , Path
    , Plan
    , Sampler
    , Tap (..)
    , atRegion
    , consumer
    , eachMoment
    , enterWith
    , entering
    , exitWith
    , failWith
    , failing
    , foldMoments
    , gauge
    , interposing
    , leaving
    , linkedTo
    , nesting
    , observe
    , observeInto
    , rerootLinked
    , sampling
    , silent
    , tagWith
    , tagging
    , tap
    , tapping
    , teeC
    , tracedBy
    , watch
    )
import Atelier.Observe.Aggregate
    ( Region (..)
    , Report (..)
    , Traces
    , collapse
    , collectMoment
    , collecting
    , cumulative
    , digest
    , reportAt
    , rollUp
    , subtreeAt
    , traceOf
    )
import Observe.Test (Obs (..), Res (..), Signal (..), reduce)
import ServerExample (Serve (..), runServe, workload)


-- A generic two-stage pipeline standing in for an oblivious program: 'StageA' splits a source string
-- into tokens, 'StageB' reverses them back into a string. Two sibling regions, so an instrumented run
-- harvests a two-child trie.
data Region2 = RegionA | RegionB
    deriving stock (Eq, Ord, Show)


newtype Tokens = Tokens [Text]
    deriving stock (Show)


newtype Output = Output Text
    deriving stock (Eq, Show)


data StageA :: Effect where
    StageA :: Text -> StageA m Tokens


type instance DispatchOf StageA = Dynamic


data StageB :: Effect where
    StageB :: Tokens -> StageB m Output


type instance DispatchOf StageB = Dynamic


runStageA :: Eff (StageA : es) a -> Eff es a
runStageA = interpret \_ -> \case
    StageA src -> pure (Tokens (Text.words src))


runStageB :: Eff (StageB : es) a -> Eff es a
runStageB = interpret \_ -> \case
    StageB (Tokens ws) -> pure (Output (Text.unwords (reverse ws)))


-- The pipeline carries no observation constraint — it is oblivious.
pipeline :: (StageA :> es, StageB :> es) => Text -> Eff es Output
pipeline src = send (StageA src) >>= \toks -> send (StageB toks)


-- The instrumentation over the pipeline: one 'Tap' per effect, merged with '<>'.
instruments :: forall i s es. (Observes es StageA i Region2 Signal, Observes es StageB i Region2 Signal) => Plan es i Region2 Signal s
instruments = tap stageATap <> tap stageBTap


-- All signals here are result-derived, so they sit on 'onLeave' (the 'leaving' setter); 'onEnter'
-- stays at its 'watch' default. Built left-to-right with the setters rather than a full record.
stageATap :: Tap StageA i Region2 Signal
stageATap =
    watch (\case StageA _ -> RegionA)
        & leaving
            ( \(StageA _) (Tokens ws) ->
                [ Golden "catalog" (Text.pack (show ws))
                , Check "nonempty" (not (null ws))
                , Tally "tokens" (length ws)
                ]
            )


stageBTap :: Tap StageB i Region2 Signal
stageBTap =
    watch (\case StageB _ -> RegionB)
        & leaving (\(StageB _) (Output t) -> [Golden "ir" t])


-- A tracing 'Tap' over "ServerExample"'s worker: each request files under the one region
-- "serve", under the trace named by the request id it carried.
serveTap :: Tap Serve Int Text Signal
serveTap =
    watch (\case Serve _ _ -> "serve")
        & tracedBy (\case Serve rid _ -> Just rid)
        & leaving (\(Serve _ payload) n -> [Tally "tokens" n, Golden "payload" payload])


-- A pure sampler that records one tick of allocation per region entry.
tickSampler :: Sampler es Res
tickSampler = gauge (pure ()) (\_ _ -> mempty {bytes = Sum 1})


-- A small trivial effect for the direct tests.
data Note :: Effect where
    Note :: Text -> Note m ()


type instance DispatchOf Note = Dynamic


note :: (Note :> es) => Text -> Eff es ()
note = send . Note


runNote :: Eff (Note : es) a -> Eff es a
runNote = interpret \_ -> \case
    Note _ -> pure ()


-- A Note interpreter that throws inside the operation when handed "boom" — the failure-path
-- fixture.
runNoteThrowing :: (IOE :> es) => Eff (Note : es) a -> Eff es a
runNoteThrowing = interpret \_ -> \case
    Note t -> when (t == "boom") (liftIO (E.throwIO (E.ErrorCall "boom")))


-- The short-circuit a 'Note' raises through an effectful 'Error' (rather than an IO throw) — the
-- recoverable kind a discharge can turn into a 'Left'. The 'observeInto' failure-path fixture.
data Stop = Stop
    deriving stock (Eq, Show)


-- A Note interpreter that short-circuits via 'Error' when handed "boom".
runNoteStopping :: (Error Stop :> es) => Eff (Note : es) a -> Eff es a
runNoteStopping = interpret \_ -> \case
    Note t -> when (t == "boom") (throwError Stop)


-- The single 'Tap' the IO tier reuses, built with 'watch' and the 'leaving' setter — the documented
-- defaulting idiom. Every note files under one region, yielding one tally on leave.
oneTap :: Tap Note () Region2 Signal
oneTap = watch (const RegionA) & leaving (\_ _ -> [Tally "x" 1])


-- A nesting fixture: two effects where 'Outer'\'s interpreter calls 'Inner'. When both are
-- tapped, the 'Inner' operation runs inside 'Outer'\'s region body, so its region nests one level
-- deeper — a real run that yields a depth-2 path. 'Outer' emits nothing, so its node is a /spine/.
data Outer :: Effect where
    Outer :: Outer m ()


type instance DispatchOf Outer = Dynamic


outerOp :: (Outer :> es) => Eff es ()
outerOp = send Outer


data Inner :: Effect where
    Inner :: Inner m ()


type instance DispatchOf Inner = Dynamic


innerOp :: (Inner :> es) => Eff es ()
innerOp = send Inner


runInner :: Eff (Inner : es) a -> Eff es a
runInner = interpret \_ -> \case
    Inner -> pure ()


-- The whole point of the fixture: discharging an 'Outer' performs an 'Inner'.
runOuter :: (Inner :> es) => Eff (Outer : es) a -> Eff es a
runOuter = interpret \_ -> \case
    Outer -> innerOp


-- A pure spine: 'watch' alone, no signals at all.
outerTap :: Tap Outer i Text Signal
outerTap = watch (const "outer")


innerTap :: Tap Inner i Text Signal
innerTap = watch (const "inner") & leaving (\_ _ -> [Tally "tok" 1])


nestTaps :: (Observes es Inner i Text Signal, Observes es Outer i Text Signal) => Plan es i Text Signal s
nestTaps = tap outerTap <> tap innerTap


-- A higher-order fixture for 'nesting': 'Bracketed' carries an action its interpreter runs inline.
-- A 'nesting' tap should turn that carried action into a region nested under the current scope —
-- the inline (bracket\/scope) analog of 'concForkLinks''s detached 'rerooting'.
data Bracketed :: Effect where
    Around :: m a -> Bracketed m a


type instance DispatchOf Bracketed = Dynamic


around :: (Bracketed :> es) => Eff es a -> Eff es a
around = send . Around


runBracketed :: Eff (Bracketed : es) a -> Eff es a
runBracketed = interpret \env -> \case
    Around act -> localSeqUnlift env \unlift -> unlift act


-- The sole per-effect knowledge a higher-order tap needs: where the carried actions are.
overAround :: OverActions Bracketed
overAround wrap = \case
    Around act -> Around (wrap act)


-- A multi-constructor fixture for 'tapping': three operations of differing result type — 'Get'
-- returns @Maybe Text@, 'Put'\/'Wipe' return @()@ — so a per-lane setter chain would need three
-- \\case scrutinees, while 'describe' matches once and refines the result type per branch.
data Kv :: Effect where
    Put :: Text -> Text -> Kv m ()
    Get :: Text -> Kv m (Maybe Text)
    Wipe :: Kv m ()


type instance DispatchOf Kv = Dynamic


-- "known" resolves; anything else misses. Enough for a result-derived exit signal on 'Get'.
runKv :: Eff (Kv : es) a -> Eff es a
runKv = interpret \_ -> \case
    Put _ _ -> pure ()
    Get k -> pure (if k == "known" then Just "v" else Nothing)
    Wipe -> pure ()


-- The inverted tap: one exhaustive \\case, all facets of each operation declared together. 'Get'\'s
-- 'exitWith' reads the refined @Maybe Text@ result directly; 'Wipe' omits 'atRegion', so it opens no
-- region (an untapped operation of a tapped effect).
kvTap :: Tap Kv () Text Signal
kvTap = tapping \case
    Put k v -> do
        atRegion "put"
        enterWith [Golden "key" k, Golden "val" v]
    Get k -> do
        atRegion "get"
        enterWith [Golden "key" k]
        exitWith \mv -> [Golden "hit" (maybe "miss" (const "hit") mv)]
    Wipe -> pure ()


-- Puts once, gets a hit and a miss, wipes in between (the untapped op).
kvProg :: (Kv :> es) => Eff es ()
kvProg = do
    send (Put "a" "1")
    _ <- send (Get "known")
    send Wipe
    _ <- send (Get "missing")
    pure ()


-- The constructor a 'Moment' fell on, as a tag the log consumer records.
momentName :: Moment i r e s -> String
momentName = \case
    Entered {} -> "enter"
    Exited {} -> "exit"
    Failed {} -> "fail"
    Measured {} -> "measure"


-- An async-worker exporter: the realistic OpenTelemetry shape, built on "Effectful.Concurrent".
-- @start@ forks a drain over a 'Chan'; @step@ enqueues each moment; @stop@ sends the end marker
-- and blocks on @result@ until the worker has flushed. 'observe' brackets @start@\/@stop@, so the
-- drain-and-join runs on the failure path too.
asyncExporter
    :: (Concurrent :> es)
    => MVar [String]
    -> (Moment i r e s -> String)
    -> Consumer es i r e s [String]
asyncExporter result render = consumer start step stop
  where
    start = do
        queue <- newChan
        _ <- forkIO (worker queue [])
        pure queue
    step queue m = queue <$ writeChan queue (Push (render m))
    stop queue = do
        writeChan queue Eof
        readMVar result -- blocks until the worker has flushed: the join
    worker queue acc =
        readChan queue >>= \case
            Eof -> putMVar result (reverse acc)
            Push s -> worker queue (s : acc)


-- The queue protocol between the discharge thread and the exporter's worker.
data Drain = Push String | Eof


-- Two pure consumers of the moment stream, pinned to the pipeline's vocabulary.

-- An aggregate: count region exits per path.
counting :: Consumer es () Region2 Signal Res (MonoidalMap (Path Region2) (Sum Int))
counting = foldMoments \case
    Exited (MomentCtx _ path _ _ _ _) _ -> MMap.singleton path (Sum 1)
    _ -> mempty


-- An event log: the constructor tag of every moment, in program order.
logTags :: Consumer es () Region2 Signal Res [String]
logTags = foldMoments \m -> [momentName m]


spec_ObserveFramework :: Spec
spec_ObserveFramework = describe "Atelier.Observe framework" do
    let src = "the quick brown fox"
        expectedOutput = Output "fox brown quick the"

    it "the discharge cannot change the program's result (side-channel guarantee)" do
        let quiet = runPureEff . runStageA . runStageB $ silent instruments (pipeline src)
            (collected, _ :: Traces () Region2 Obs Res) = runPureEff . runStageA . runStageB $ observe (collecting reduce) instruments (pipeline src)
            (logged, _ :: [String]) = runPureEff . runStageA . runStageB $ observe logTags instruments (pipeline src)
        quiet `shouldBe` expectedOutput
        collected `shouldBe` quiet
        logged `shouldBe` quiet

    it "drives one Plan into several independent consumers" do
        let (_, traces :: Traces () Region2 Obs Res) =
                runPureEff . runStageA . runStageB $ observe (collecting reduce) instruments (pipeline src)
            (_, counts) =
                runPureEff . runStageA . runStageB $ observe counting instruments (pipeline src)
            (_, logged) =
                runPureEff . runStageA . runStageB $ observe logTags instruments (pipeline src)
            summary = collapse traces
        -- collecting: a full Traces harvest, the two regions as top-level children of the trie
        MMap.keys (children summary) `shouldBe` [RegionA, RegionB]
        MMap.lookup "tokens" (reportAt [RegionA] summary).observations.counts `shouldBe` Just (Sum 4)
        MMap.lookup "ir" (reportAt [RegionB] summary).observations.goldens `shouldBe` Just (Set.singleton "fox brown quick the")
        -- counting: one exit per region
        counts `shouldBe` MMap.fromList [([RegionA], Sum 1), ([RegionB], Sum 1)]
        -- logging: signals now ride the brackets, so the stream is just enter/exit per region
        logged `shouldBe` ["enter", "exit", "enter", "exit"]

    it "runs several consumers in one pass with teeC" do
        let (_, (traces, counts)) =
                runPureEff . runStageA . runStageB
                    $ observe (collecting reduce `teeC` counting) instruments (pipeline src)
        MMap.keys (children (collapse (traces :: Traces () Region2 Obs Res))) `shouldBe` [RegionA, RegionB]
        counts `shouldBe` MMap.fromList [([RegionA], Sum 1), ([RegionB], Sum 1)]

    it "observeInto matches observe's harvest on a run that completes" do
        -- the two discharges fold the same moments the same way; observeInto just threads the
        -- accumulator through a caller-run State instead of observe's private one.
        let (_, viaObserve :: Traces () Region2 Obs Res) =
                runPureEff . runStageA . runStageB
                    $ observe (collecting reduce) instruments (pipeline src)
            (_, viaInto) =
                runPureEff . runState mempty . runStageA . runStageB
                    $ observeInto (collectMoment reduce) instruments (pipeline src)
        viaInto `shouldBe` viaObserve

    it "observeInto preserves the harvest across an effectful short-circuit" do
        -- the headline of issue 3: discharge the accumulator State OUTSIDE the Error, so a
        -- short-circuit becomes a Left without unwinding the harvest. The note "boom" aborts the
        -- run, but everything observed before the abort survives.
        let prog = note "ok" >> note "boom" >> note "unreached"
            (result, traces :: Traces () Region2 Obs Res) =
                runPureEff . runState mempty . runErrorNoCallStack . runNoteStopping
                    $ observeInto (collectMoment reduce) (tap oneTap <> sampling tickSampler) prog
            summary = collapse traces
        -- the program short-circuited…
        result `shouldBe` (Left Stop :: Either Stop ())
        -- …yet "ok" was harvested before the abort: its onLeave tally survived, and "unreached"
        -- never ran (else this would be Sum 2)…
        MMap.lookup "x" (reportAt [RegionA] summary).observations.counts `shouldBe` Just (Sum 1)
        -- …and the failing "boom" was entered and sampled before it threw — the bracketed sampler
        -- fired for both notes (Sum 2), so the failing region is in the harvest too.
        (reportAt [RegionA] summary).measurements.bytes `shouldBe` Sum 2

    it "digest flattens the whole run into one region-blind Report" do
        let (_, traces :: Traces () Region2 Obs Res) =
                runPureEff . runStageA . runStageB
                    $ observe (collecting reduce) instruments (pipeline src)
            report = digest traces
        -- both seams' observations land in the one merged report: elaborate's token tally…
        MMap.lookup "tokens" report.observations.counts `shouldBe` Just (Sum 4)
        -- …and lower's Output golden
        MMap.lookup "ir" report.observations.goldens `shouldBe` Just (Set.singleton "fox brown quick the")

    it "merging taps on one effect (Tap <>) collapses to one region; separate taps nest it" do
        -- two instrumentations of the SAME Note operation, filing under the same region
        let golden, tally :: Tap Note () Region2 Signal
            golden = watch (const RegionA) & leaving (\_ _ -> [Golden "g" "v"])
            tally = watch (const RegionA) & leaving (\_ _ -> [Tally "t" 1])
            harvest :: Plan '[Note] () Region2 Signal Res -> Region Region2 (Report Obs Res)
            harvest plan = collapse (snd (runPureEff (runNote (observe (collecting reduce) plan (note "x")))))
            -- merged into ONE tap → ONE interpose → ONE Scope carrying both signals
            merged = harvest (tap (golden <> tally))
            -- installed as SEPARATE taps → two interposes → the region nests inside itself
            nested = harvest (tap golden <> tap tally)
        -- merged: a single RegionA node, no child, holding BOTH signals
        MMap.null (children (subtreeAt [RegionA] merged)) `shouldBe` True
        MMap.lookup "g" (reportAt [RegionA] merged).observations.goldens `shouldBe` Just (Set.singleton "v")
        MMap.lookup "t" (reportAt [RegionA] merged).observations.counts `shouldBe` Just (Sum 1)
        -- nested: RegionA ⊃ RegionA, splitting the signals across two depths. The
        -- innermost-installed tap (tally) sits nearest the send, so its region is the outer one.
        MMap.keys (children (subtreeAt [RegionA] nested)) `shouldBe` [RegionA]
        MMap.lookup "t" (reportAt [RegionA] nested).observations.counts `shouldBe` Just (Sum 1)
        MMap.lookup "g" (reportAt [RegionA, RegionA] nested).observations.goldens `shouldBe` Just (Set.singleton "v")

    it "folds a sampling resource into the region under a collecting consumer" do
        let (_, traces :: Traces () Region2 Obs Res) =
                runPureEff . runStageA . runStageB
                    $ observe (collecting reduce) (instruments <> sampling tickSampler) (pipeline src)
            summary = collapse traces
        (reportAt [RegionA] summary).measurements.bytes `shouldBe` Sum 1
        (reportAt [RegionB] summary).measurements.bytes `shouldBe` Sum 1

    it "streams each moment for effect with eachMoment, in program order" do
        let oneNoteTap :: Tap Note () Region2 Signal
            oneNoteTap = watch (const RegionA) & leaving (\_ _ -> [Tally "x" 1])
            sink :: (Writer [String] :> es) => Consumer es () Region2 Signal Res ()
            sink = eachMoment \m -> tell [momentName m]
            (_, logged) =
                runPureEff . runWriter . runNote
                    $ observe sink (tap oneNoteTap) (note "x")
        logged `shouldBe` ["enter", "exit"]

    it "a tracing Tap keeps each request's trace apart under a collecting consumer" do
        -- ServerExample's workload: ids 1, 2, 1 — id 1 served twice (4 + 3 tokens), id 2 once (2)
        let (_, traces :: Traces Int Text Obs Res) =
                runPureEff . runServe $ observe (collecting reduce) (tap serveTap) workload
            tokensOf tid =
                MMap.lookup "tokens" (reportAt ["serve"] (traceOf (Just tid) traces)).observations.counts
        MMap.keys traces `shouldBe` [Just 1, Just 2]
        tokensOf 1 `shouldBe` Just (Sum 7)
        tokensOf 2 `shouldBe` Just (Sum 2)
        -- collapse forgets the trace dimension: every request's tokens sum at the one region
        MMap.lookup "tokens" (reportAt ["serve"] (collapse traces)).observations.counts `shouldBe` Just (Sum 9)

    it "never forces a signal payload under the silent discharge (entry, exit, or error)" do
        -- every boundary carries a diverging Check; silent must force none of them, and must not
        -- even force the unused onError function
        let checkTap :: Tap Note () Region2 Signal
            checkTap =
                watch (const RegionA)
                    & entering (\_ -> [Check "enter" (error "entry forced!")])
                    & leaving (\_ _ -> [Check "leave" (error "leave forced!")])
                    & failing (\_ _ -> [Check "error" (error "error forced!")])
        runPureEff (runNote (silent (tap checkTap) (note "x"))) `shouldBe` ()

    it "a linkedTo Tap surfaces its link targets on Entered" do
        -- links ride the new [i] lane on Entered, untouched by the trie consumer but available to an
        -- exporter; a Tap declares them with the 'linkedTo' setter.
        seen <- newIORef []
        let linkTap :: Tap Note Int Region2 Signal
            linkTap = watch (const RegionA) & linkedTo (\(Note _) -> [7, 9])
            sink :: (IOE :> es) => Consumer es Int Region2 Signal Res ()
            sink = eachMoment \case
                Entered _ links _ -> liftIO (modifyIORef' seen (links :))
                _ -> pure ()
        (_, ()) <- runEff . runNote $ observe sink (tap linkTap) (note "x")
        recorded <- readIORef seen
        recorded `shouldBe` [[LinkTrace (7 :: Int), LinkTrace 9]]

    it "rerootLinked reroots a child region to a fresh root and links it to the parent region" do
        seen <- newIORef []
        let spawnInner :: (Inner :> es, Observed es () Text Signal, Outer :> es) => Eff es x -> Eff es x
            spawnInner = interpose \_ op -> case op of
                Outer -> rerootLinked (innerOp)
            plan = tap innerTap <> interposing spawnInner <> tap outerTap
            sink :: (IOE :> es) => Consumer es () Text Signal Res ()
            sink = eachMoment \case
                Entered (MomentCtx _ p _ _ _ _) links _ -> liftIO (modifyIORef' seen ((p, links) :))
                _ -> pure ()
        (_, ()) <- runEff . runInner . runOuter $ observe sink plan outerOp
        recorded <- reverse <$> readIORef seen
        recorded
            `shouldBe` [ (["outer"], [])
                       , (["inner"], [LinkRegion Nothing ["outer"]])
                       ]

    it "nesting wraps a carried action as a region nested under the current scope" do
        -- the inline higher-order case: 'around' carries an action; a 'nesting' tap files it under a
        -- region "around" in the SAME trace, and the inner op's own region nests one level deeper —
        -- contrast 'rerooting' (concForkLinks), which would start the carried action in a fresh trace.
        seen <- newIORef []
        let plan = tap innerTap <> tap (nesting SeqUnlift (const "around") overAround)
            sink :: (IOE :> es) => Consumer es () Text Signal Res ()
            sink = eachMoment \case
                Entered (MomentCtx _ p _ _ _ _) _ _ -> liftIO (modifyIORef' seen (p :))
                _ -> pure ()
        (_, ()) <- runEff . runInner . runBracketed $ observe sink plan (around innerOp)
        recorded <- reverse <$> readIORef seen
        -- no region for the 'Around' operation itself; "around" is its carried action, "inner" nests
        recorded `shouldBe` [["around"], ["around", "inner"]]

    it "captures input on entry and the exception on Failed when the operation throws (failure-path)" do
        -- the headline: onEnter fires into Entered before the work, so a throwing
        -- operation still records its input — onLeave (which needs a result) never runs, and the
        -- region closes as Failed carrying the exception plus the onError signals.
        seen <- newIORef []
        let inputTap :: Tap Note () Region2 Signal
            inputTap =
                watch (const RegionA)
                    & entering (\case Note t -> [Golden "input" t])
                    & leaving (\_ _ -> [Tally "done" 1])
                    & failing (\_ e -> [Golden "error" (Text.pack (show e))])
            sigTag = \case
                Golden k v -> "golden " <> Text.unpack k <> "=" <> Text.unpack v
                Check k _ -> "check " <> Text.unpack k
                Tally k n -> "tally " <> Text.unpack k <> "=" <> show n
            entry :: Moment () Region2 Signal Res -> (String, [String])
            entry = \case
                Entered _ _ es -> ("enter", map sigTag es)
                Exited _ es -> ("exit", map sigTag es)
                Failed _ es _ -> ("fail", map sigTag es)
                Measured {} -> ("measure", [])
            sink :: (IOE :> es) => Consumer es () Region2 Signal Res ()
            sink = eachMoment \m -> liftIO (modifyIORef' seen (entry m :))
        _ <-
            E.try (runEff . runNoteThrowing $ observe sink (tap inputTap) (note "boom"))
                :: IO (Either E.SomeException ((), ()))
        recorded <- reverse <$> readIORef seen
        -- input survived the throw on entry; onLeave's "done" tally never fired; Failed carries
        -- the exception text from onError (and the original exception, dropped by this matcher)
        recorded `shouldBe` [("enter", ["golden input=boom"]), ("fail", ["golden error=boom"])]

    it "streams each moment to an IO sink with eachMoment (base-row IO)" do
        sink <- newIORef []
        let exporter :: (IOE :> es) => Consumer es () Region2 Signal Res ()
            exporter = eachMoment \m -> liftIO (modifyIORef' sink (momentName m :))
        (_, ()) <- runEff . runNote $ observe exporter (tap oneTap) (note "x")
        logged <- reverse <$> readIORef sink
        logged `shouldBe` ["enter", "exit"]

    it "exports each moment in program order through an async worker (Effectful.Concurrent)" do
        result <- newEmptyMVar
        let exporter :: (Concurrent :> es) => Consumer es () Region2 Signal Res [String]
            exporter = asyncExporter result momentName
        (_, harvest) <- runEff . runConcurrent . runNote $ observe exporter (tap oneTap) (note "x")
        harvest `shouldBe` ["enter", "exit"]

    it "still flushes through stop when the program throws (exception-safe)" do
        result <- newEmptyMVar
        let exporter :: (Concurrent :> es) => Consumer es () Region2 Signal Res [String]
            exporter = asyncExporter result momentName
            prog = note "ok" >> note "boom"
        outcome <-
            E.try (runEff . runConcurrent . runNoteThrowing $ observe exporter (tap oneTap) prog)
                :: IO (Either E.SomeException ((), [String]))
        isLeft outcome `shouldBe` True
        flushed <- tryReadMVar result
        -- the first note exits cleanly; the throwing second note closes as Failed ("fail")
        flushed `shouldBe` Just ["enter", "exit", "enter", "fail"]

    it "tapping builds a Tap equivalent to the setter-chain form" do
        -- the two surfaces compile to the same record: same region, same enter/leave signals, so the
        -- same harvest. 'describe' matches the operation once; the setters match it per lane.
        let viaSetters :: Tap Note () Region2 Signal
            viaSetters =
                watch (const RegionA)
                    & entering (\(Note t) -> [Golden "in" t])
                    & leaving (\_ _ -> [Tally "done" 1])
            viaDescribe :: Tap Note () Region2 Signal
            viaDescribe = tapping \case
                Note t -> do
                    atRegion RegionA
                    enterWith [Golden "in" t]
                    exitWith \_ -> [Tally "done" 1]
            harvest :: Tap Note () Region2 Signal -> Region Region2 (Report Obs Res)
            harvest tp =
                collapse (snd (runPureEff (runNote (observe (collecting reduce) (tap tp) (note "hi")))))
        harvest viaDescribe `shouldBe` harvest viaSetters

    it "tapping drives a multi-constructor effect from one exhaustive match" do
        let (_, traces :: Traces () Text Obs Res) =
                runPureEff . runKv $ observe (collecting reduce) (tap kvTap) kvProg
            summary = collapse traces
        -- 'Wipe' omitted 'atRegion', so it opened no region: only "get" and "put" appear
        MMap.keys (children summary) `shouldBe` ["get", "put"]
        -- 'Get' ran twice; its result-derived exit signal recorded both a hit and a miss
        MMap.lookup "hit" (reportAt ["get"] summary).observations.goldens
            `shouldBe` Just (Set.fromList ["hit", "miss"])
        -- 'Put'\'s entry signals landed at its own region
        MMap.lookup "key" (reportAt ["put"] summary).observations.goldens
            `shouldBe` Just (Set.singleton "a")

    it "tapping captures input on entry and the exception on Failed (failure path)" do
        -- the failure lanes through the builder: 'enterWith' fires before the work (so input survives
        -- a throw), 'exitWith' never runs, and the region closes as Failed carrying 'failWith'.
        seen <- newIORef []
        let inputTap :: Tap Note () Region2 Signal
            inputTap = tapping \case
                Note t -> do
                    atRegion RegionA
                    enterWith [Golden "input" t]
                    exitWith \_ -> [Tally "done" 1]
                    failWith \e -> [Golden "error" (Text.pack (show e))]
            sigTag = \case
                Golden k v -> "golden " <> Text.unpack k <> "=" <> Text.unpack v
                Check k _ -> "check " <> Text.unpack k
                Tally k n -> "tally " <> Text.unpack k <> "=" <> show n
            entry :: Moment () Region2 Signal Res -> (String, [String])
            entry = \case
                Entered _ _ es -> ("enter", map sigTag es)
                Exited _ es -> ("exit", map sigTag es)
                Failed _ es _ -> ("fail", map sigTag es)
                Measured {} -> ("measure", [])
            sink :: (IOE :> es) => Consumer es () Region2 Signal Res ()
            sink = eachMoment \m -> liftIO (modifyIORef' seen (entry m :))
        _ <-
            E.try (runEff . runNoteThrowing $ observe sink (tap inputTap) (note "boom"))
                :: IO (Either E.SomeException ((), ()))
        recorded <- reverse <$> readIORef seen
        recorded `shouldBe` [("enter", ["golden input=boom"]), ("fail", ["golden error=boom"])]

    it "a scope signal (tagging) rides its region and every moment nested inside it" do
        -- 'Outer'\'s interpreter performs 'Inner', so "inner" nests under "outer". A scope signal set
        -- on "outer" must appear in the ambient 'tags' of both "outer"\'s own moment and the nested
        -- "inner"\'s — unlike an entry signal, which would land only on "outer".
        seen <- newIORef []
        let taggedOuter :: Tap Outer () Text Signal
            taggedOuter = watch (const "outer") & tagging (const [Golden "component" "svc"])
            plan = tap innerTap <> tap taggedOuter
            sink :: (IOE :> es) => Consumer es () Text Signal Res ()
            sink = eachMoment \case
                Entered (MomentCtx _ p tgs _ _ _) _ _ ->
                    liftIO (modifyIORef' seen ((p, [(k, v) | Golden k v <- tgs]) :))
                _ -> pure ()
        (_, ()) <- runEff . runInner . runOuter $ observe sink plan outerOp
        recorded <- reverse <$> readIORef seen
        recorded
            `shouldBe` [ (["outer"], [("component", "svc")]) -- the region it is set on carries it…
                       , (["outer", "inner"], [("component", "svc")]) -- …and the nested child inherits it
                       ]

    it "tapping's tagWith sets the same inherited scope signal as the tagging setter" do
        -- the builder command and the setter feed the same 'onScope' facet, so both taps produce the
        -- same ambient tags on every moment.
        let viaSetter, viaBuilder :: Tap Outer () Text Signal
            viaSetter = watch (const "outer") & tagging (const [Golden "component" "svc"])
            viaBuilder = tapping \case
                Outer -> do
                    atRegion "outer"
                    tagWith [Golden "component" "svc"]
            tagsOf tp = do
                ref <- newIORef []
                let sink :: (IOE :> es) => Consumer es () Text Signal Res ()
                    sink = eachMoment \case
                        Entered (MomentCtx _ p tgs _ _ _) _ _ ->
                            liftIO (modifyIORef' ref ((p, [(k, v) | Golden k v <- tgs]) :))
                        _ -> pure ()
                _ <- runEff . runInner . runOuter $ observe sink (tap innerTap <> tap tp) outerOp
                reverse <$> readIORef ref
        fromSetter <- tagsOf viaSetter
        fromBuilder <- tagsOf viaBuilder
        fromBuilder `shouldBe` fromSetter

    describe "the trie" do
        -- A hand-built nested harvest: region "a" is a spine (entered, never observed) whose child
        -- "a/b" holds 2 tokens; sibling "c" holds 5; "d" is a fully-empty subtree.
        let toks n = Report (mempty {counts = MMap.singleton "tok" (Sum n)}) mempty :: Report Obs Res
            tree :: Region Text (Report Obs Res)
            tree =
                Region
                    mempty
                    ( MMap.fromList
                        [ ("a", Region mempty (MMap.singleton "b" (Region (toks 2) mempty)))
                        , ("c", Region (toks 5) mempty)
                        , ("d", Region mempty mempty)
                        ]
                    )

        it "reportAt reads the exact region, not its descendants" do
            -- the spine node holds nothing of its own…
            reportAt ["a"] tree `shouldBe` mempty
            -- …while the leaf beneath it holds its report
            reportAt ["a", "b"] tree `shouldBe` toks 2
            reportAt ["c"] tree `shouldBe` toks 5

        it "subtreeAt scopes the prefix query; fold rolls a whole subtree up" do
            -- the subtree under the spine "a" aggregates to its descendants' reports
            fold (subtreeAt ["a"] tree) `shouldBe` toks 2
            -- the whole harvest rolls every report together (2 + 5 = 7)
            fold tree `shouldBe` toks 7

        it "cumulative (the comonad extend) rolls every node up to its own subtree" do
            -- one pass: each node's payload becomes the fold of the subtree rooted at it
            let c = cumulative tree
            reportAt [] c `shouldBe` toks 7 -- the root sees the whole tree
            reportAt ["a"] c `shouldBe` toks 2 -- the spine now carries its subtree's rollup…
            reportAt ["a", "b"] c `shouldBe` toks 2 -- …while the leaf is unchanged
            reportAt ["c"] c `shouldBe` toks 5
            -- the shape is untouched: only payloads changed
            (() <$ c) `shouldBe` (() <$ tree)

        it "rollUp rolls the observation lane but leaves the inclusive measurement lane" do
            -- a parent "p" carrying its own (inclusive) measurement, over a child "p/q" holding both
            -- an observation and a measurement — the lanes a real sampled run produces
            let obsToks n = mempty {counts = MMap.singleton "tok" (Sum n)} :: Obs
                bytesN n = mempty {bytes = Sum n} :: Res
                tree2 :: Region Text (Report Obs Res)
                tree2 =
                    Region
                        mempty
                        ( MMap.singleton
                            "p"
                            ( Region
                                (Report mempty (bytesN 5))
                                (MMap.singleton "q" (Region (Report (obsToks 2) (bytesN 3)) mempty))
                            )
                        )
                rolled = rollUp tree2
                naive = cumulative tree2
            -- observations roll up: the parent now sees the child's tokens
            MMap.lookup "tok" (reportAt ["p"] rolled).observations.counts `shouldBe` Just (Sum 2)
            -- measurements stay per-node inclusive: the parent keeps its own 5, not 5 + 3
            (reportAt ["p"] rolled).measurements.bytes `shouldBe` Sum 5
            -- the leaf is unchanged
            (reportAt ["p", "q"] rolled).measurements.bytes `shouldBe` Sum 3
            -- whereas naive cumulative double-counts the inclusive measurement down the tree
            (reportAt ["p"] naive).measurements.bytes `shouldBe` Sum 8
            -- the shape is untouched
            (() <$ rolled) `shouldBe` (() <$ tree2)

        it "Functor/Foldable/Traversable range over every node's payload" do
            -- foldMap is the cross-cutting query: every region's tokens merged into one map
            foldMap (\r -> r.observations.counts) tree `shouldBe` MMap.singleton "tok" (Sum 7)
            -- Foldable visits every node — spine, empty subtree, and root included
            length tree `shouldBe` 5
            -- fold is the whole-tree rollup
            fold tree `shouldBe` toks 7
            -- fmap rewrites payloads in place; Foldable then counts the non-empty regions
            length (filter not (toList (fmap (\r -> MMap.null r.observations.counts) tree))) `shouldBe` 2
            -- traverse threads an effect through every node (here the tuple writer collects them),
            -- leaving the tree's shape intact
            let (visited, shape) = traverse (\r -> ([r], ())) tree
            length visited `shouldBe` 5
            shape `shouldBe` (() <$ tree)

        it "nests regions from a real run: Inner's region descends inside Outer's" do
            -- a genuine run (not a hand-built trie): Outer's interpreter performs Inner, so the
            -- discharge sees Scope "inner" dynamically inside Scope "outer" — a depth-2 path.
            let (_, traces :: Traces () Text Obs Res) =
                    runPureEff . runInner . runOuter $ observe (collecting reduce) nestTaps outerOp
                summary = collapse traces
            -- "outer" is the sole top-level region; "inner" descends inside it
            MMap.keys (children summary) `shouldBe` ["outer"]
            MMap.keys (children (subtreeAt ["outer"] summary)) `shouldBe` ["inner"]
            -- "outer" is a spine produced by a real run: entered, but it emitted nothing itself
            reportAt ["outer"] summary `shouldBe` mempty
            MMap.lookup "tok" (reportAt ["outer", "inner"] summary).observations.counts `shouldBe` Just (Sum 1)
            -- the rollup reaches the inner observation through the spine
            MMap.lookup "tok" (fold (subtreeAt ["outer"] summary)).observations.counts `shouldBe` Just (Sum 1)

        it "the recursive monoid coalesces overlapping tries field-wise" do
            -- two harvests that both file under "a/b" merge their reports at that node
            let node n = Region (toks n) mempty :: Region Text (Report Obs Res)
                left = Region mempty (MMap.singleton "a" (Region mempty (MMap.singleton "b" (node 2))))
                right = Region mempty (MMap.singleton "a" (Region (toks 1) (MMap.singleton "b" (node 4))))
                merged = left <> right
            reportAt ["a", "b"] merged `shouldBe` toks 6 -- 2 + 4 at the shared leaf
            reportAt ["a"] merged `shouldBe` toks 1 -- only right filed at the spine
