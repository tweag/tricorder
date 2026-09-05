-- | An effect for managing detached daemon processes via PID files.
--
-- 'daemonize' forks a program into the background, 'isRunning' checks a daemon's
-- PID file, and 'forceKillAndWait' terminates one. Backed by the @daemons@
-- package.
module Atelier.Effects.Posix.Daemons
    ( Daemons
    , PidFile (..)
    , daemonize
    , isRunning
    , forceKillAndWait
    , runDaemons
    )
where

import Data.Default (def)
import Effectful (Effect, IOE, Limit (..), Persistence (..), UnliftStrategy (..))
import Effectful.Dispatch.Dynamic (interpretWith, localUnliftIO)
import Effectful.Exception (trySync)
import Effectful.TH (makeEffect)

import System.Posix.Daemon qualified as Daemons


-- | Effect for managing detached daemon processes.
data Daemons :: Effect where
    -- | Daemonize the given program, ensuring it is cleanly separated from the
    -- spawning process.
    Daemonize :: PidFile -> m () -> Daemons m ()
    -- | Check whether a daemon is running for the provided PID file.
    IsRunning :: PidFile -> Daemons m Bool
    -- | Kill the daemon associated with the provided PID file using `SIGKILL`.
    ForceKillAndWait :: PidFile -> Daemons m (Either SomeException ())


-- | The path to a daemon's PID file, used to track and control it.
newtype PidFile = PidFile {getPidFile :: FilePath}


makeEffect ''Daemons


-- | Interpret 'Daemons' using the @daemons@ package.
runDaemons :: (IOE :> es) => Eff (Daemons : es) a -> Eff es a
runDaemons act = do
    interpretWith act \env -> \case
        Daemonize (PidFile pidFile) program ->
            localUnliftIO env (ConcUnlift Persistent Unlimited) \unlift -> do
                Daemons.runDetached (Just pidFile) def
                    $ unlift program
        IsRunning (PidFile pidFile) ->
            liftIO $ Daemons.isRunning pidFile
        ForceKillAndWait (PidFile pidFile) ->
            trySync $ liftIO $ Daemons.brutalKill pidFile
