module Tricorder.Effects.BuildStore
    ( -- * Effect
      BuildStore (..)
    , getState
    , modifyPhase
    , waitUntilDone
    , waitForNext
    , waitForAnyChange
    , setPhase
    , markDirty
    , waitDirty
    , hasWaiters

      -- * Intermediate interpreters
    , withPostBuildPhase

      -- * Interpreters
    , runBuildStoreScripted
    , runBuildStore
    , runBuildStoreState
    ) where

import Atelier.Effects.Input (Input, input)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.STM
    ( TChan
    , TVar
    , atomically
    , dupTChan
    , modifyTVar
    , newBroadcastTChan
    , newTVar
    , readTChan
    , readTVar
    , retry
    , writeTChan
    , writeTVar
    )
import Effectful.Dispatch.Dynamic (interpretWith_, interpret_, reinterpret)
import Effectful.Exception (bracket_)
import Effectful.State.Static.Shared (State, evalState, get, modify, put)
import Effectful.TH (makeEffect)

import Tricorder.BuildState
    ( BuildId
    , BuildPhase (..)
    , BuildResult
    , BuildState (..)
    , ChangeKind (..)
    , DaemonInfo (..)
    , EvalPhase (..)
    , PostBuild (..)
    , TestPhase (..)
    , initialBuildState
    )
import Tricorder.Effects.PostBuildStore (PostBuildStore (..))


data BuildStore :: Effect where
    -- | Read the current build state without blocking.
    GetState :: BuildStore m BuildState
    -- | Atomically update the phase of the current build, keeping its
    -- 'BuildId'. The function sees the live state, so a progress update can
    -- inspect the current phase and leave it untouched if it has moved on.
    ModifyPhase :: (BuildState -> BuildPhase) -> BuildStore m ()
    -- | Block until the current build cycle completes (phase transitions to Done).
    WaitUntilDone :: BuildStore m BuildState
    -- | Block until a completed build with a different 'BuildId' is available.
    WaitForNext :: BuildId -> BuildStore m BuildState
    -- | Block until the build state changes from the given state (any field).
    WaitForAnyChange :: BuildState -> BuildStore m BuildState
    -- | Update the build id and phase without touching other fields (e.g. daemonInfo).
    SetPhase :: BuildId -> BuildPhase -> BuildStore m ()
    -- | Signal that files have changed and a rebuild is needed.
    -- 'CabalChange' upgrades a pending 'SourceChange' but never downgrades.
    MarkDirty :: ChangeKind -> BuildStore m ()
    -- | Block until dirty, atomically clear the flag, and return the change kind.
    WaitDirty :: BuildStore m ChangeKind
    -- | Return True if any callers are currently blocked in 'waitUntilDone'.
    HasWaiters :: BuildStore m Bool


makeEffect ''BuildStore


withPostBuildPhase :: (BuildStore :> es) => BuildResult -> Eff (PostBuildStore : es) a -> Eff es a
withPostBuildPhase initialBuildResult =
    interpret_ \case
        SetTestPhase tp -> modifyPhase \state -> case state.phase of
            BuildComplete pb ->
                BuildComplete pb {testPhase = tp}
            _ ->
                BuildComplete
                    PostBuild
                        { testPhase = tp
                        , evalPhase = EvaluatingComments
                        , result = initialBuildResult
                        }
        SetEvalPhase ep -> modifyPhase \state -> case state.phase of
            BuildComplete pb -> BuildComplete pb {evalPhase = ep}
            _ ->
                BuildComplete
                    PostBuild
                        { testPhase = Testing
                        , evalPhase = ep
                        , result = initialBuildResult
                        }
        UpdateBuildResult f -> modifyPhase \state -> case state.phase of
            BuildComplete pb ->
                BuildComplete pb {result = f pb.result}
            _ ->
                BuildComplete
                    PostBuild
                        { testPhase = Testing
                        , evalPhase = EvaluatingComments
                        , result = f initialBuildResult
                        }


-- | Mutable state shared between the production interpreters and writers
-- (e.g. 'GhciSession'). Internal to this module.
data BuildStateRef = BuildStateRef
    { stateRef :: TVar BuildState
    , dirtyRef :: TVar (Maybe ChangeKind)
    , waitersRef :: TVar Int
    , transitions :: TChan BuildState
    -- ^ Broadcast channel of every phase transition. Writers (setPhase /
    -- modifyPhase) atomically update 'stateRef' AND broadcast on this chan in
    -- the same STM transaction; waiters 'dupTChan' it on entry and consume
    -- every transition. A transient 'Done' followed immediately by
    -- 'Building (N+1)' is therefore observable as two messages on the
    -- channel — the waiter can't be woken on the 'Done' and then miss it
    -- because the 'Building' overwrote 'stateRef' before the waiter re-ran.
    }


-- | Allocate the shared STM state, seeding the build state from @di@. The
-- record's field types pin the otherwise-polymorphic 'newTVar' and
-- 'newBroadcastTChan' results.
newBuildStateRef :: (Concurrent :> es) => DaemonInfo -> Eff es BuildStateRef
newBuildStateRef di =
    atomically
        $ BuildStateRef
            <$> newTVar (initialBuildState di)
            <*> newTVar Nothing
            <*> newTVar 0
            <*> newBroadcastTChan


isBuilding :: BuildState -> Bool
isBuilding s = case s.phase of
    Building _ -> True
    Restarting -> True
    BuildComplete (PostBuild Testing _ _) -> True
    BuildComplete (PostBuild _ EvaluatingComments _) -> True
    BuildComplete (PostBuild DoneTesting DoneEvaluatingComments _) -> False
    BuildFailed _ -> False


-- | Block until the build state satisfies @predicate@, then return it.
--
-- Subscribes to 'transitions' before reading the current state, so every
-- subsequent state change is observable as a discrete message even if the
-- TVar value is overwritten before the waiter is rescheduled. This is what
-- prevents a transient 'Done' from being missed when 'Building (N+1)'
-- follows it within the scheduler's wake-up latency.
waitForState
    :: (Concurrent :> es)
    => TVar BuildState
    -> TChan BuildState
    -> (BuildState -> Bool)
    -> Eff es BuildState
waitForState ref transitions predicate = do
    myChan <- atomically (dupTChan transitions)
    -- Snapshot AFTER subscribing so we don't race past a transition: any
    -- state change that happens between subscribing and reading 'ref' also
    -- lands on 'myChan', so the loop will pick it up.
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
-- operations. Useful for testing components that read build state without
-- needing a real 'TVar' or concurrency.
--
-- * 'getState' peeks at the head of the list without consuming it.
-- * 'modifyPhase' rewrites the head's phase in place.
-- * 'waitUntilDone' pops states until it finds one where @phase /= Building@.
-- * 'waitForNext' pops states until it finds a Done state with a different 'BuildId'.
runBuildStoreScripted :: [BuildState] -> Eff (BuildStore : es) a -> Eff es a
runBuildStoreScripted states = reinterpret (evalState states) $ \_ -> \case
    GetState ->
        get >>= \case
            [] -> error "BuildStoreScripted: getState called on empty state list"
            s : _ -> pure s
    ModifyPhase f ->
        get >>= \case
            [] -> pure ()
            s : rest -> put (s {phase = f s} : rest)
    WaitUntilDone -> advance (not . isBuilding)
    WaitForNext bid -> advance \s -> not (isBuilding s) && s.buildId /= bid
    WaitForAnyChange prev -> advance (/= prev)
    SetPhase bid phase -> do
        get >>= \case
            [] -> pure ()
            s : rest -> put (s {buildId = bid, phase = phase} : rest)
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
-- writers (e.g. 'GhciSession'). Seeds the state with 'initialBuildState' for
-- the current 'DaemonInfo' and refreshes it on every phase change.
--
-- Blocking operations use STM @retry@ rather than polling, so a transient
-- 'Done' state cannot be missed by a poll cycle landing on the surrounding
-- 'Building' phases. 'atomically' is interruptible, so async exceptions
-- (e.g. Ki's @ScopeClosing@) propagate during daemon shutdown.
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
        ModifyPhase f -> do
            daemonInfo <- input
            atomically do
                modifyTVar refs.stateRef \bs -> bs {phase = f bs, daemonInfo}
                readTVar refs.stateRef >>= writeTChan refs.transitions
        WaitUntilDone ->
            bracket_
                (atomically (modifyTVar refs.waitersRef (+ 1)))
                (atomically (modifyTVar refs.waitersRef (subtract 1)))
                (waitForState refs.stateRef refs.transitions (not . isBuilding))
        WaitForNext bid ->
            waitForState refs.stateRef refs.transitions \s -> not (isBuilding s) && s.buildId /= bid
        WaitForAnyChange prev -> waitForState refs.stateRef refs.transitions (/= prev)
        SetPhase bid phase -> do
            daemonInfo <- input
            atomically do
                modifyTVar refs.stateRef \bs -> bs {buildId = bid, phase = phase, daemonInfo}
                readTVar refs.stateRef >>= writeTChan refs.transitions
        MarkDirty ck -> atomically (modifyTVar refs.dirtyRef (max (Just ck)))
        WaitDirty -> takeDirty refs.dirtyRef
        HasWaiters -> fmap (> 0) $ atomically (readTVar refs.waitersRef)


runBuildStoreState :: (State BuildState :> es) => Eff (BuildStore : es) a -> Eff es a
runBuildStoreState = interpret_ \case
    GetState -> get
    ModifyPhase f -> modify \s -> s {phase = f s}
    WaitUntilDone -> get
    WaitForNext _ -> get
    WaitForAnyChange _ -> get
    SetPhase buildId phase -> modify \s -> s {buildId, phase}
    MarkDirty _ -> pure ()
    WaitDirty -> error "runBuildStoreState: waitDirty not supported"
    HasWaiters -> pure False
