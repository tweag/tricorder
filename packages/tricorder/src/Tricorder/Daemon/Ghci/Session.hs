module Tricorder.Daemon.Ghci.Session
    ( -- * Effect
      Session
    , with

      -- * Interpreters
    , run
    , runScripted
    )
where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Timeout (Timeout)
import Data.Default (def)
import Effectful
    ( Effect
    , Limit (..)
    , Persistence (..)
    , UnliftStrategy (..)
    )
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic
    ( interpret
    , localLift
    , localSeqLift
    , localSeqUnlift
    , localUnlift
    , reinterpret
    )
import Effectful.Exception (throwIO)
import Effectful.State.Static.Shared (State, evalState, state)
import Effectful.TH (makeEffect)

import Tricorder.Build (BuildProgress (..))
import Tricorder.Daemon.Ghci.Controls (Controls (..))
import Tricorder.Daemon.Ghci.LoadResult (LoadResult)
import Tricorder.Daemon.Ghci.Loading (Loading (..))
import Tricorder.Runtime.ProjectRoot (ProjectRoot (..))
import Tricorder.Session.Command.RenderedCommand (RenderedCommand)
import Tricorder.Session.Stage (Stage (..))

import Tricorder.Daemon.Ghci.Controls qualified as Controls
import Tricorder.Daemon.Ghci.Process qualified as Ghci.Process
import Tricorder.Daemon.Ghci.Process qualified as Process


data Session :: Effect where
    -- | Start a new GHCi session and run the handler with that session active.
    -- The handler is also provided an action to reload the GHCi session,
    -- returning new messages with module counts. The GHCi session is closed
    -- when the handler returns.
    With
        :: (BuildProgress -> m ())
        -- ^ Action to run when reporting progress
        -> RenderedCommand 'Build
        -> ProjectRoot
        -> (LoadResult -> Controls m -> m a)
        -> Session m a


makeEffect ''Session


-- | Scripted interpreter for testing.
--
-- Each call to 'startGhci' or 'reloadGhci' pops the next result from the
-- pre-loaded list. 'Left' results are re-thrown as exceptions, simulating
-- GHCi crashes. 'stopGhci' is always a no-op.
runScripted
    :: forall es a. [Either SomeException LoadResult] -> Eff (Session : es) a -> Eff es a
runScripted results = reinterpret (evalState results) $ \env ->
    let popResult :: Eff (State [Either SomeException LoadResult] : es) LoadResult
        popResult = do
            x <- state \case
                x : xs -> (x, xs)
                [] -> error "GhciSessionScripted: no more results in queue"
            case x of
                Left ex -> throwIO ex
                Right r -> pure r
    in  \case
            With _ _ _ handler -> do
                initial <- popResult
                localSeqLift env \liftEff ->
                    localSeqUnlift env \unlift ->
                        unlift
                            $ handler
                                initial
                                Controls
                                    { reload = liftEff popResult
                                    , interrupt = pure ()
                                    , add = \_ -> liftEff popResult
                                    , unadd = \_ -> liftEff popResult
                                    }


-- | GHCi session manager backed by 'Tricorder.Daemon.GhciSession.GhciProcess'
-- and 'Tricorder.Daemon.GhciSession.GhciParser'.
run
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Timeout :> es
       )
    => Eff (Session : es) a -> Eff es a
run = interpret $ \env -> \case
    With onProgress cmd (ProjectRoot dir) handler -> do
        localLift env (ConcUnlift Persistent Unlimited) \liftEff ->
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                let reportProgress loading =
                        unlift
                            $ onProgress
                            $ BuildProgress
                                { compiled = loading.index
                                , total = loading.total
                                }
                Process.with def cmd dir reportProgress (\_ -> pure ()) \process startupLines -> do
                    initialResult <- Ghci.Process.collectResult process startupLines dir
                    unlift
                        $ handler initialResult
                        $ Controls.lift liftEff
                        $ Controls
                            { reload = Ghci.Process.reload process dir reportProgress
                            , interrupt = Ghci.Process.interruptGhci process
                            , add = \fp -> Ghci.Process.add process fp dir reportProgress
                            , unadd = \mn -> Ghci.Process.unadd process mn dir reportProgress
                            }
