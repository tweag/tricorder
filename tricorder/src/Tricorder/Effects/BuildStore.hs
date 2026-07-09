module Tricorder.Effects.BuildStore
    ( -- * Effect
      BuildStore (..)
    , getState
    , emit
    , setTests
    , modifyTests
    , writeTestsAt
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

import Atelier.Effects.Input (Input, input)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM (TChan, TVar, atomically, dupTChan, modifyTVar, newBroadcastTChan, newTVar, readTChan, readTVar, retry, writeTChan, writeTVar)
import Effectful.Dispatch.Dynamic (interpretWith_, reinterpret)
import Effectful.Exception (bracket_)
import Effectful.State.Static.Shared (State, evalState, get, put)
import Effectful.TH (makeEffect)

import Tricorder.BuildState
    ( BuildId
    , BuildState (..)
    , ChangeKind (..)
    , CycleEvent
    , DaemonInfo (..)
    , TestOutput
    , initialBuildState
    , isBuilding
    , overCurrentTests
    , overHistoryAt
    , step
    )


data BuildStore :: Effect where
    -- | Read the current build state without blocking.
    GetState :: BuildStore m BuildState
    -- | Drive the cycle state machine. The reducer owns 'current', 'cycle',
    -- and the build register; this is the only way to move them.
    Emit :: CycleEvent -> BuildStore m ()
    -- | Overwrite the current build's test register.
    SetTests :: TestOutput -> BuildStore m ()
    -- | Modify the current build's test register in place.
    ModifyTests :: (TestOutput -> TestOutput) -> BuildStore m ()
    -- | SPIKE (straggler-safety prototype): modify the test register of a
    -- specific build id (targeting 'overHistoryAt'), not @current@.
    WriteTestsAt :: BuildId -> (TestOutput -> TestOutput) -> BuildStore m ()
    -- | Block until the current build cycle completes (settles).
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
    -- 'Settled' followed immediately by 'Building (N+1)' is therefore
    -- observable as two messages — the waiter can't be woken on 'Settled' and
    -- then miss it because 'Building' overwrote 'stateRef' before it re-ran.
    }


-- | Allocate the shared STM state, seeding the build state from @di@.
newBuildStateRef :: (Concurrent :> es) => DaemonInfo -> Eff es BuildStateRef
newBuildStateRef di =
    atomically
        $ BuildStateRef
            <$> newTVar (initialBuildState di)
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
    SetTests t ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (overCurrentTests (const t) s : rest)
    ModifyTests f ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (overCurrentTests f s : rest)
    WriteTestsAt bid f ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (overHistoryAt bid f s : rest)
    WaitUntilDone -> advance (not . isBuilding)
    WaitForNext bid -> advance \s -> not (isBuilding s) && s.current /= bid
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
    :: ( Concurrent :> es
       , Input DaemonInfo :> es
       )
    => Eff (BuildStore : es) a -> Eff es a
runBuildStore eff = do
    di <- input
    refs <- newBuildStateRef di
    interpretWith_ eff \case
        GetState -> atomically (readTVar refs.stateRef)
        Emit ev -> writeState refs (step `flip` ev)
        SetTests t -> writeState refs (overCurrentTests (const t))
        ModifyTests f -> writeState refs (overCurrentTests f)
        WriteTestsAt bid f -> writeState refs (overHistoryAt bid f)
        WaitUntilDone ->
            bracket_
                (atomically (modifyTVar refs.waitersRef (+ 1)))
                (atomically (modifyTVar refs.waitersRef (subtract 1)))
                (waitForState refs.stateRef refs.transitions (not . isBuilding))
        WaitForNext bid ->
            waitForState refs.stateRef refs.transitions \s -> not (isBuilding s) && s.current /= bid
        WaitForAnyChange prev -> waitForState refs.stateRef refs.transitions (/= prev)
        MarkDirty ck -> atomically (modifyTVar refs.dirtyRef (max (Just ck)))
        WaitDirty -> takeDirty refs.dirtyRef
        HasWaiters -> fmap (> 0) $ atomically (readTVar refs.waitersRef)
  where
    -- Apply a pure update to the state (refreshing daemonInfo) and broadcast it
    -- on the transitions channel in one STM transaction.
    writeState refs f = do
        daemonInfo <- input
        atomically do
            modifyTVar refs.stateRef \bs -> (f bs) {daemonInfo}
            readTVar refs.stateRef >>= writeTChan refs.transitions
