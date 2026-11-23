-- | An effect for managing detached daemon processes via PID files.
--
-- A daemon is started by re-executing the current program as a fresh,
-- detached process (see 'daemonize'), rather than by @fork(2)@ing the running
-- one. Programs that can be daemonized must route their entry point through
-- 'withDaemonEntryPoint'.
--
-- PID file inspection and killing are backed by the @daemons@ package.
module Atelier.Effects.Posix.Daemons
    ( Daemons
    , PidFile (..)
    , daemonize
    , withDaemonEntryPoint
    , isRunning
    , forceKillAndWait
    , run
    )
where

import Control.Concurrent (forkIO)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static
    ( SideEffects (..)
    , StaticRep
    , evalStaticRep
    , getStaticRep
    , unsafeEff_
    )
import Effectful.Exception (trySync)
import System.Environment (getArgs, getEnvironment, getExecutablePath, lookupEnv, unsetEnv)
import System.IO (SeekMode (..), openFile)
import System.Posix.Files (stdFileMode)
import System.Posix.IO (LockRequest (..), createFile, fdWrite, setLock)
import System.Posix.Process (getProcessID)
import System.Process (CreateProcess (..), StdStream (..))

import System.Posix.Daemon qualified as Daemons
import System.Process qualified as Process

import Atelier.FileSystem.Path qualified as Path


-- | Effect for managing detached daemon processes.
data Daemons :: Effect


type instance DispatchOf Daemons = Static 'WithSideEffects


data instance StaticRep Daemons = Daemons


-- | The path to a daemon's PID file, used to track and control it.
newtype PidFile = PidFile {getPidFile :: Path.Absolute}


-- | Environment variable through which 'daemonize' tells the re-executed
-- program to act as the daemon. Its value is the PID file path.
daemonPidFileEnv :: String
daemonPidFileEnv = "ATELIER_DAEMON_PID_FILE"


-- | Start the daemon: re-execute the current program, with the same arguments,
-- working directory and environment, as a detached process in its own session
-- with its standard streams on @/dev/null@. The new process runs the daemon
-- program given to 'withDaemonEntryPoint'. Fails if the daemon is already
-- running.
--
-- We deliberately avoid daemonizing by forking the running process (as
-- 'Daemons.runDetached' does). The program is multi-threaded, and on macOS the
-- Objective-C runtime aborts a forked child of a multi-threaded process as soon
-- as it initializes a class (e.g. when the file watcher starts FSEvents),
-- killing the daemon silently. Spawning a fresh process sidesteps fork safety
-- altogether.
daemonize :: (Daemons :> es) => PidFile -> Eff es ()
daemonize (PidFile pidFile) = do
    Daemons <- getStaticRep
    unsafeEff_ do
        let pidPath = Path.toFilePath pidFile
        running <- Daemons.isRunning pidPath
        when running $ fail "already running"
        self <- getExecutablePath
        args <- getArgs
        environment <- getEnvironment
        -- 'Process.createProcess' closes the handles passed with 'UseHandle'.
        devNull <- openFile "/dev/null" ReadWriteMode
        (_, _, _, ph) <-
            Process.createProcess
                (Process.proc self args)
                    { env =
                        Just
                            $ (daemonPidFileEnv, pidPath)
                                : filter ((/= daemonPidFileEnv) . fst) environment
                    , std_in = UseHandle devNull
                    , std_out = UseHandle devNull
                    , std_err = UseHandle devNull
                    , new_session = True
                    , close_fds = True
                    }
        -- The daemon is our child until we exit; reap it should it die first
        -- so it doesn't linger as a zombie (e.g. while the TUI is running).
        void $ forkIO $ void $ Process.waitForProcess ph


-- | Entry point for a program that can be started with 'daemonize'. When the
-- current process was started by 'daemonize', write and lock the PID file and
-- run @daemonMain@; otherwise run @normalMain@.
withDaemonEntryPoint
    :: IO ()
    -- ^ The daemon program
    -> IO ()
    -- ^ The regular program
    -> IO ()
withDaemonEntryPoint daemonMain normalMain =
    lookupEnv daemonPidFileEnv >>= \case
        Nothing -> normalMain
        Just pidPath -> do
            -- Don't leak the marker to the daemon's own subprocesses.
            unsetEnv daemonPidFileEnv
            writePidFile pidPath
            daemonMain


-- | Write our PID to the given file and hold a write lock on it for the rest
-- of the process' life, which is how 'Daemons.isRunning' detects a live
-- daemon. The file descriptor is deliberately never closed, as that would
-- release the lock.
writePidFile :: FilePath -> IO ()
writePidFile pidPath = do
    fd <- createFile pidPath stdFileMode
    setLock fd (WriteLock, AbsoluteSeek, 0, 0)
    pid <- getProcessID
    void $ fdWrite fd (show pid)


-- | Check whether a daemon is running for the provided PID file.
isRunning :: (Daemons :> es) => PidFile -> Eff es Bool
isRunning (PidFile pidFile) = do
    Daemons <- getStaticRep
    unsafeEff_ $ Daemons.isRunning $ Path.toFilePath pidFile


-- | Kill the daemon associated with the provided PID file using `SIGKILL`.
forceKillAndWait :: (Daemons :> es) => PidFile -> Eff es (Either SomeException ())
forceKillAndWait (PidFile pidFile) = do
    Daemons <- getStaticRep
    trySync $ unsafeEff_ $ Daemons.brutalKill $ Path.toFilePath pidFile


run :: (IOE :> es) => Eff (Daemons : es) a -> Eff es a
run = evalStaticRep Daemons
