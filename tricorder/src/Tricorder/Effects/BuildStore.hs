module Tricorder.Effects.BuildStore
    ( -- * Effect
      BuildStore (..)
    , getState
    , emit
    , mergeCurrent
    , recordBuild
    , recordTests
    , waitUntilDone
    , waitForNext
    , waitForAnyChange
    , markDirty
    , waitDirty
    , hasWaiters

      -- * Interpreters
    , runBuildStoreScripted
    , runBuildStore
    ) where

import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TChan, TVar, atomically, dupTChan, modifyTVar, newBroadcastTChan, newTVar, readTChan, readTVar, retry, writeTChan, writeTVar)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (bracket_)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Tricorder.BuildState
    ( BuildId
    , BuildOutput (..)
    , BuildRecord (..)
    , BuildState (..)
    , ChangeKind (..)
    , CycleEvent
    , currentId
    , initialBuildState
    , isDone
    , overCurrent
    , step
    )
import Tricorder.BuildState.Test (Suites)


data BuildStore :: Effect where
    -- | Read the current build state without blocking.
    GetState :: BuildStore m BuildState
    -- | Drive the cycle state machine. The reducer owns 'cycle' and the
    -- structure of the history; this is the only way to move them.
    Emit :: CycleEvent -> BuildStore m ()
    -- | Merge a producer's delta into the current build's record. The single
    -- register write path: each producer touches only its own field, the build
    -- register a 'Last'-like monoid and the test register a per-target monoidal
    -- merge. 'recordBuild' [ref:record_build] and 'recordTests' [ref:record_tests]
    -- are the field-focused wrappers.
    --
    -- Ordering contract for the settle: merge the build delta BEFORE emitting the
    -- terminal phase ('EnterAnalysis' / 'AnalysisComplete'), so a reader woken on
    -- 'Idle' never observes a 'NotBuilt' register — the register write is already
    -- visible when the terminal transition broadcasts.
    MergeCurrent :: BuildRecord -> BuildStore m ()
    -- | Block until the current build cycle completes.
    WaitUntilDone :: BuildStore m BuildState
    -- | Block until a completed build with a different 'BuildId' is available.
    WaitForNext :: BuildId -> BuildStore m BuildState
    -- | Block until the build state changes from the given state (any field).
    WaitForAnyChange :: BuildState -> BuildStore m BuildState
    -- | Signal that files have changed and a rebuild is needed.
    -- 'CabalChange' upgrades a pending 'SourceChange' but never downgrades.
    MarkDirty :: ChangeKind -> BuildStore m ()
    -- | Block until dirty, atomically clear the flag, and return the change kind.
    WaitDirty :: BuildStore m ChangeKind
    -- | Return True if any callers are currently blocked in 'waitUntilDone'.
    HasWaiters :: BuildStore m Bool


makeEffect ''BuildStore


-- | [tag:record_build] Record the compile step's result in the current build's
-- build register.
recordBuild :: (BuildStore :> es) => BuildOutput -> Eff es ()
recordBuild b = mergeCurrent mempty {build = b}


-- | [tag:record_tests] Record a test-suite delta in the current build's test
-- register.
recordTests :: (BuildStore :> es) => Suites -> Eff es ()
recordTests t = mergeCurrent mempty {tests = t}


-- | Mutable state shared between the production interpreters and writers
-- (e.g. 'GhciSession'). Internal to this module.
data BuildStateRef = BuildStateRef
    { stateRef :: TVar BuildState
    , dirtyRef :: TVar (Maybe ChangeKind)
    , waitersRef :: TVar Int
    , transitions :: TChan BuildState
    -- ^ Broadcast channel of every state transition. Writers atomically update
    -- 'stateRef' AND broadcast on this chan in the same STM transaction;
    -- waiters 'dupTChan' it on entry and consume every transition. A transient
    -- 'Tricorder.BuildState.Idle' followed immediately by 'Building' (N+1) is
    -- therefore observable as two messages — the waiter can't be woken on the
    -- terminal phase and then miss it because 'Building' overwrote 'stateRef'
    -- before it re-ran.
    }


-- | Allocate the shared STM state, seeding the reduced build state.
newBuildStateRef :: (Concurrent :> es) => Eff es BuildStateRef
newBuildStateRef =
    atomically
        $ BuildStateRef
            <$> newTVar initialBuildState
            <*> newTVar Nothing
            <*> newTVar 0
            <*> newBroadcastTChan


-- | Block until the build state satisfies @predicate@, then return it.
--
-- Subscribes to 'transitions' before reading the current state, so every
-- subsequent state change is observable as a discrete message even if the
-- TVar value is overwritten before the waiter is rescheduled.
waitForState
    :: (Concurrent :> es)
    => TVar BuildState
    -> TChan BuildState
    -> (BuildState -> Bool)
    -> Eff es BuildState
waitForState ref transitions predicate = do
    myChan <- atomically (dupTChan transitions)
    s0 <- atomically (readTVar ref)
    if predicate s0 then pure s0 else drainUntilMatch myChan
  where
    drainUntilMatch ch = do
        s <- atomically (readTChan ch)
        if predicate s then pure s else drainUntilMatch ch


-- | Atomically take the dirty marker, blocking until one is set.
takeDirty :: (Concurrent :> es) => TVar (Maybe ChangeKind) -> Eff es ChangeKind
takeDirty dirtyRef = atomically do
    readTVar dirtyRef >>= \case
        Just ck -> writeTVar dirtyRef Nothing >> pure ck
        Nothing -> retry


-- | Scripted interpreter for testing.
--
-- Advances through a pre-loaded list of 'BuildState' values for blocking
-- operations.
runBuildStoreScripted :: [BuildState] -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreScripted states = reinterpret (evalState states) $ \_ -> \case
    GetState ->
        get >>= \case
            [] -> error "BuildStoreScripted: getState called on empty state list"
            s : _ -> pure s
    Emit ev ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (step s ev : rest)
    MergeCurrent delta ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (overCurrent (<> delta) s : rest)
    WaitUntilDone -> advance isDone
    WaitForNext bid -> advance \s -> isDone s && currentId s /= bid
    WaitForAnyChange prev -> advance (/= prev)
    MarkDirty _ -> pure ()
    WaitDirty -> pure SourceChange
    HasWaiters -> pure False
  where
    advance :: (BuildState -> Bool) -> Eff (State [BuildState] : es) BuildState
    advance predicate =
        get >>= \case
            [] -> error "BuildStoreScripted: no matching state in list"
            s : rest
                | predicate s -> put rest >> pure s
                | otherwise -> put rest >> advance predicate


-- | Production interpreter backed by a 'TVar', sharing its STM state with
-- writers (e.g. 'GhciSession').
runBuildStore
    :: (Concurrent :> es)
    => Eff (BuildStore : es) a -> Eff es a
runBuildStore eff = do
    refs <- newBuildStateRef
    interpretWith_ eff \case
        GetState -> atomically (readTVar refs.stateRef)
        Emit ev -> writeState refs (`step` ev)
        MergeCurrent delta -> writeState refs (overCurrent (<> delta))
        WaitUntilDone ->
            bracket_
                (atomically (modifyTVar refs.waitersRef (+ 1)))
                (atomically (modifyTVar refs.waitersRef (subtract 1)))
                (waitForState refs.stateRef refs.transitions isDone)
        WaitForNext bid ->
            waitForState refs.stateRef refs.transitions \s -> isDone s && currentId s /= bid
        WaitForAnyChange prev -> waitForState refs.stateRef refs.transitions (/= prev)
        MarkDirty ck -> atomically (modifyTVar refs.dirtyRef (max (Just ck)))
        WaitDirty -> takeDirty refs.dirtyRef
        HasWaiters -> fmap (> 0) $ atomically (readTVar refs.waitersRef)
  where
    -- Apply a pure update to the state and broadcast it on the transitions
    -- channel in one STM transaction. No daemonInfo re-stamp: config is joined
    -- at the wire edge ('Tricorder.BuildState.Status'), not stored here.
    writeState refs f = atomically do
        modifyTVar refs.stateRef f
        readTVar refs.stateRef >>= writeTChan refs.transitions
