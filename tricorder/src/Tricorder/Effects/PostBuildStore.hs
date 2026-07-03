module Tricorder.Effects.PostBuildStore
    ( PostBuildStore (..)
    , setTestPhase
    , updateBuildResult
    , runPostBuildStoreState
    , runPostBuildStoreCapture
    ) where

import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpose_, interpret_)
import Effectful.State.Static.Shared (State, gets, modify)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)

import Tricorder.BuildState (BuildResult, PostBuild (..), TestPhase)


data PostBuildStore :: Effect where
    SetTestPhase :: TestPhase -> PostBuildStore m ()
    UpdateBuildResult :: (BuildResult -> BuildResult) -> PostBuildStore m ()


makeEffect ''PostBuildStore


-- | For testing. Run a 'PostBuildStore' with a 'PostBuild' state.
runPostBuildStoreState
    :: (State PostBuild :> es)
    => Eff (PostBuildStore : es) a -> Eff es a
runPostBuildStoreState = interpret_ \case
    SetTestPhase tp -> modify \pb -> pb {testPhase = tp}
    UpdateBuildResult f -> modify \pb -> pb {result = f pb.result}


-- | For testing. Augment another 'PostBuildStore' interpreter by noting down
-- the various stages of the 'PostBuild'.
runPostBuildStoreCapture
    :: ( PostBuildStore :> es
       , State PostBuild :> es
       , Writer [PostBuild] :> es
       )
    => Eff es a -> Eff es a
runPostBuildStoreCapture = interpose_ @PostBuildStore \case
    SetTestPhase tp -> do
        pb <- gets \pb -> pb {testPhase = tp}
        tell [pb]
        setTestPhase tp
    UpdateBuildResult f -> do
        pb <- gets \pb -> pb {result = f pb.result}
        tell [pb]
        updateBuildResult \_ -> pb.result
