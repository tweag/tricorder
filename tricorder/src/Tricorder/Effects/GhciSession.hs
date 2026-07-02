module Tricorder.Effects.GhciSession
    ( -- * Effect
      GhciSession
    , Controls (..)
    , withGhci

      -- * Types
    , LoadResult (..)
    , LoadedModule (..)

      -- * Interpreters
    , runGhciSession
    , runGhciSessionScripted
    ) where

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

import Tricorder.BuildState (BuildPhase (..), BuildProgress (..))
import Tricorder.Effects.BuildStore (BuildStore, modifyPhase)
import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoading (..)
    , LoadResult (..)
    , LoadedModule (..)
    )
import Tricorder.Runtime (ProjectRoot (..))
import Tricorder.Session (Command)

import Tricorder.Effects.GhciSession.Load qualified as Load
import Tricorder.Effects.Repl qualified as Repl


data GhciSession :: Effect where
    -- | Start a new GHCi session and run the handler with that session active.
    -- The handler is also provided an action to reload the GHCi session,
    -- returning new messages with module counts. The GHCi session is closed
    -- when the handler returns.
    WithGhci :: Command -> ProjectRoot -> (LoadResult -> Controls m -> m a) -> GhciSession m a


data Controls m = Controls
    { reload :: m LoadResult
    , interrupt :: m ()
    , add :: FilePath -> m LoadResult
    , unadd :: Text -> m LoadResult
    }


makeEffect ''GhciSession


-- | Scripted interpreter for testing.
--
-- Each call to 'WithGhci' or the resulting 'reload' pops the next result from
-- the pre-loaded list. 'Left' results are re-thrown as exceptions, simulating
-- GHCi crashes. 'stopGhci' is always a no-op.
runGhciSessionScripted :: forall es a. [Either SomeException LoadResult] -> Eff (GhciSession : es) a -> Eff es a
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
            WithGhci _ _ handler -> do
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


-- | GHCi session manager backed by 'Tricorder.Effects.Repl' and the load
-- interpretation in 'Tricorder.Effects.GhciSession.Load'.
runGhciSession
    :: ( BuildStore :> es
       , Conc :> es
       , Concurrent :> es
       , File :> es
       , Log :> es
       , Process :> es
       , Timeout :> es
       )
    => Eff (GhciSession : es) a -> Eff es a
runGhciSession = interpret $ \env -> \case
    WithGhci cmd (ProjectRoot dir) handler -> do
        let onProgress loading =
                modifyPhase \_ ->
                    Building
                        $ Just
                        $ BuildProgress {compiled = loading.index, total = loading.total}
        Repl.withRepl def cmd dir onProgress (\_ -> pure ()) \repl startupLines ->
            localLift env (ConcUnlift Persistent Unlimited) \liftEff ->
                localUnlift env (ConcUnlift Persistent Unlimited) \unlift -> do
                    let doReload = liftEff $ Load.reload repl dir onProgress
                    initialResult <- unlift $ liftEff $ Load.collectLoadResult repl startupLines dir
                    unlift
                        $ handler
                            initialResult
                            Controls
                                { reload = doReload
                                , interrupt = liftEff (Repl.interrupt repl)
                                , add = \fp -> liftEff $ Load.add repl fp dir onProgress
                                , unadd = \mn -> liftEff $ Load.unadd repl mn dir onProgress
                                }
