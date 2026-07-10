module Tricorder.Effects.PostBuildStore
    ( PostBuildStore
    , modifyPostBuild
    , runPostBuildStore
    , runPostBuildState
    , runPostBuildCapture
    )
where

import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpose_, interpret_)
import Effectful.State.Static.Shared (State, get, modify)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)

import Tricorder.BuildState (BuildPhase (..), BuildResult, BuildState (..), PostBuild (..))
import Tricorder.Effects.BuildStore (BuildStore)

import Tricorder.Effects.BuildStore qualified as BuildStore


data PostBuildStore :: Effect where
    ModifyPostBuild :: (PostBuild -> PostBuild) -> PostBuildStore m ()


makeEffect ''PostBuildStore


-- | Ensures actions that rely on 'PostBuildStore' have access to a 'PostBuild'
-- to modify and update.
--
-- This interpreter ensures that the 'BuildState''s @phase@ is @BuildComplete@
-- once this interpreter finishes.
runPostBuildStore
    :: (BuildStore :> es)
    => BuildResult
    -> Eff (PostBuildStore : es) a
    -> Eff es a
runPostBuildStore initialBuildResult = do
    interpret_ \case
        ModifyPostBuild f -> do
            BuildStore.modifyPhase \s -> case s.phase of
                BuildComplete buildResult postBuild ->
                    BuildComplete buildResult $ f postBuild
                _ ->
                    BuildComplete initialBuildResult
                        $ f
                        $ PostBuild
                            { testSuites = mempty
                            , evalComments = mempty
                            }


runPostBuildState :: (State PostBuild :> es) => Eff (PostBuildStore : es) a -> Eff es a
runPostBuildState = interpret_ \case
    ModifyPostBuild f -> modify f


runPostBuildCapture
    :: ( PostBuildStore :> es
       , State PostBuild :> es
       , Writer [PostBuild] :> es
       )
    => Eff es a -> Eff es a
runPostBuildCapture = interpose_ \case
    ModifyPostBuild f -> do
        curr <- get
        tell [f curr]
        modifyPostBuild f
