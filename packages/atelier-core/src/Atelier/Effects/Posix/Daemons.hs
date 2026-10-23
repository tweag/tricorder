-- | An effect for managing detached daemon processes via PID files.
--
-- Backed by the @daemons@ package.
module Atelier.Effects.Posix.Daemons
    ( Daemons
    , PidFile (..)
    , daemonize
    , isRunning
    , forceKillAndWait
    , run
    )
where

import Data.Default (def)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE, Limit (..), Persistence (..))
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , concUnliftIO
    , evalStaticRep
    , getStaticRep
    , unsafeEff
    , unsafeEff_
    )
import Effectful.Exception (trySync)

import System.Posix.Daemon qualified as Daemons


-- | Effect for managing detached daemon processes.
data Daemons :: Effect


type instance DispatchOf Daemons = Static 'WithSideEffects


data instance StaticRep Daemons = Daemons


-- | The path to a daemon's PID file, used to track and control it.
newtype PidFile = PidFile {getPidFile :: FilePath}


-- | Daemonize the given program, ensuring it is cleanly separated from the
-- spawning process.
daemonize :: (Daemons :> es) => PidFile -> Eff es () -> Eff es ()
daemonize (PidFile pidFile) program = do
    Daemons <- getStaticRep
    unsafeEff \env ->
        concUnliftIO env Persistent Unlimited \unlift -> do
            Daemons.runDetached (Just pidFile) def
                $ unlift program


-- | Check whether a daemon is running for the provided PID file.
isRunning :: (Daemons :> es) => PidFile -> Eff es Bool
isRunning (PidFile pidFile) = do
    Daemons <- getStaticRep
    unsafeEff_ $ Daemons.isRunning pidFile


-- | Kill the daemon associated with the provided PID file using `SIGKILL`.
forceKillAndWait :: (Daemons :> es) => PidFile -> Eff es (Either SomeException ())
forceKillAndWait (PidFile pidFile) = do
    Daemons <- getStaticRep
    trySync $ unsafeEff_ $ Daemons.brutalKill pidFile


run :: (IOE :> es) => Eff (Daemons : es) a -> Eff es a
run = evalStaticRep Daemons
