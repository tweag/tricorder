module Tricorder.Daemon.GhciSession
    ( -- * Effect
      GhciSession
    , Controls (..)
    , transformControls
    , withGhciWith
    , withGhci

      -- * Types
    , LoadResult (..)
    , LoadedModule (..)

      -- * Interpreters
    , runGhciSession
    , runGhciSessionScripted
    )
where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process)
import Atelier.Effects.Publishing.Pub (Pub)
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

import Atelier.Effects.Publishing.Pub qualified as Pub

import Tricorder.Build (BuildProgress (..))
import Tricorder.Daemon.GhciSession.GhciParser
    ( GhciLoading (..)
    , LoadResult (..)
    , LoadedModule (..)
    )
import Tricorder.Daemon.GhciSession.GhciProcess
    ( addGhci
    , collectGhciResult
    , interruptGhci
    , reloadGhci
    , unaddGhci
    , withGhciProcess
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session.Command (Command)


data GhciSession :: Effect where
    -- | Start a new GHCi session and run the handler with that session active.
    -- The handler is also provided an action to reload the GHCi session,
    -- returning new messages with module counts. The GHCi session is closed
    -- when the handler returns.
    WithGhciWith
        :: (BuildProgress -> m ())
        -- ^ Action to run when reporting progress
        -> Command
        -> ProjectRoot
        -> (LoadResult -> Controls m -> m a)
        -> GhciSession m a


data Controls m = Controls
    { reload :: m LoadResult
    , interrupt :: m ()
    , add :: FilePath -> m LoadResult
    , unadd :: Text -> m LoadResult
    }


makeEffect ''GhciSession


transformControls :: (forall a. m a -> n a) -> Controls m -> Controls n
transformControls f ctrls =
    Controls
        { reload = f ctrls.reload
        , interrupt = f ctrls.interrupt
        , add = f . ctrls.add
        , unadd = f . ctrls.unadd
        }


withGhci
    :: (GhciSession :> es, Pub BuildProgress :> es)
    => Command
    -> ProjectRoot
    -> (LoadResult -> Controls (Eff es) -> Eff es a)
    -> Eff es a
withGhci cmd root handler = do
    withGhciWith Pub.publish cmd root handler


-- | Scripted interpreter for testing.
--
-- Each call to 'startGhci' or 'reloadGhci' pops the next result from the
-- pre-loaded list. 'Left' results are re-thrown as exceptions, simulating
-- GHCi crashes. 'stopGhci' is always a no-op.
runGhciSessionScripted
    :: forall es a. [Either SomeException LoadResult] -> Eff (GhciSession : es) a -> Eff es a
runGhciSessionScripted results = reinterpret (evalState results) $ \env ->
    let popResult :: Eff (State [Either SomeException LoadResult] : es) LoadResult
        popResult = do
            x <- state \case
                x : xs -> (x, xs)
                [] -> error "GhciSessionScripted: no more results in queue"
            case x of
                Left ex -> throwIO ex
                Right r -> pure r
    in  \case
            WithGhciWith _ _ _ handler -> do
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
runGhciSession
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Timeout :> es
       )
    => Eff (GhciSession : es) a -> Eff es a
runGhciSession = interpret $ \env -> \case
    WithGhciWith onProgress cmd (ProjectRoot dir) handler -> do
        localLift env (ConcUnlift Persistent Unlimited) \liftEff ->
            localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                let reportProgress loading =
                        unlift
                            $ onProgress
                            $ BuildProgress
                                { compiled = loading.index
                                , total = loading.total
                                }
                withGhciProcess def cmd dir reportProgress (\_ -> pure ()) \process startupLines -> do
                    initialResult <- collectGhciResult process startupLines dir
                    unlift
                        $ handler initialResult
                        $ transformControls liftEff
                        $ Controls
                            { reload = reloadGhci process dir reportProgress
                            , interrupt = interruptGhci process
                            , add = \fp -> addGhci process fp dir reportProgress
                            , unadd = \mn -> unaddGhci process mn dir reportProgress
                            }
