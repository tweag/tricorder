module Tricorder.Effects.SessionStore
    ( SessionStore (..)
    , SessionStoreReloaded (..)
    , get
    , rawReload
    , withSession
    , withSubSession
    , ActiveSession (..)
    , Reloader (..)
    , runSessionStore
    , runSessionStoreConst
    ) where

import Atelier.Config (LoadedConfig)
import Atelier.Effects.Chan (Chan)
import Atelier.Effects.Conc (Conc)
import Atelier.Effects.FileSystem (FileSystem)
import Atelier.Effects.Log (Log)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)
import Effectful (Effect)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpret_, reinterpretWith_)
import Effectful.Reader.Static (Reader)
import Effectful.TH (makeEffect)
import Relude.Extra.Tuple (dup)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Iterator qualified as Iter
import Atelier.Effects.Publishing.Pub qualified as Pub
import Atelier.Effects.Publishing.Sub qualified as Sub
import Effectful.State.Static.Shared qualified as State

import Tricorder.Runtime (ProjectRoot)
import Tricorder.Session (CabalFile, Session, loadSession)


data SessionStore :: Effect where
    Get :: SessionStore m Session
    RawReload :: SessionStore m ()


makeEffect ''SessionStore


data ActiveSession es = ActiveSession
    { session :: Session
    , reloader :: Reloader es
    }


newtype Reloader es = Reloader {reload :: Eff es ()}


-- | Operate on the most recent 'Session' stored. Whenever the session is
-- reloaded, the passed action is cancelled, and started again with the new
-- 'Session'.
withSession
    :: ( Conc :> es
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => (ActiveSession es -> Eff es a)
    -> Eff es Void
withSession act =
    Conc.restartableForkWith (void $ Sub.listenOnce_ @SessionStoreReloaded) get \session ->
        act ActiveSession {session, reloader = Reloader rawReload}


-- | Tracks the parts of 'Session' that the caller cares about, and restarts
-- the passed function whenever those parts change based on the 'subSession's
-- 'Eq' instance.
withSubSession
    :: forall subSession es a
     . ( Chan :> es
       , Conc :> es
       , Concurrent :> es
       , Eq subSession
       , SessionStore :> es
       , Sub SessionStoreReloaded :> es
       )
    => (Session -> subSession)
    -> Session
    -> (Reloader es -> subSession -> Eff es a)
    -> Eff es Void
withSubSession mkSubSession initialSession action =
    Iter.fromEvents @SessionStoreReloaded \iter ->
        let initialSubSession = mkSubSession initialSession
            subIter =
                Iter.changes
                    initialSubSession
                    (fmap (\(SessionStoreReloaded s) -> mkSubSession s) iter)
        in  Conc.restartableForkLoop
                initialSubSession
                (Iter.next subIter)
                \cfg -> action (Reloader rawReload) cfg


data SessionStoreReloaded = SessionStoreReloaded Session


runSessionStore
    :: ( FileSystem :> es
       , Log :> es
       , Pub SessionStoreReloaded :> es
       , Reader LoadedConfig :> es
       , Reader ProjectRoot :> es
       , Reader [CabalFile] :> es
       )
    => Eff (SessionStore : es) a -> Eff es a
runSessionStore act = do
    initialSession <- loadSession
    reinterpretWith_ (State.evalState initialSession) act \case
        Get -> State.get
        RawReload -> do
            session <- State.stateM (\_ -> dup <$> loadSession)
            Pub.publish $ SessionStoreReloaded session


runSessionStoreConst :: Session -> Eff (SessionStore : es) a -> Eff es a
runSessionStoreConst session = interpret_ \case
    Get -> pure session
    RawReload -> pure ()
