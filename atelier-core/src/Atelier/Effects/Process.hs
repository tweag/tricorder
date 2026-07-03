-- | Effect for spawning and interacting with external processes.
--
-- Unifies @typed-process@ (configuration, lifecycle and stream capture) and the
-- process-group signalling that @process@ provides behind a single effect, so
-- callers never depend on either package directly.
--
-- Build a 'ProcessConfig' with the re-exported @typed-process@ DSL ('proc',
-- 'shell', 'setStdin', …), then run it with 'withProcessGroup', which runs the
-- process in its own group and guarantees the /whole group/ is torn down on
-- exit. Callers never manage pids or process groups themselves.
module Atelier.Effects.Process
    ( -- * Effect
      Process

      -- * Building process configs (re-exported from @typed-process@)
    , ProcessConfig
    , RunningProcess
    , proc
    , shell
    , setStdin
    , setStdout
    , setStderr
    , setWorkingDir
    , createPipe
    , getStdin
    , getStdout
    , getStderr

      -- * Operations
    , readProcessStdout
    , readProcess
    , runProcess
    , readProcessSafe
    , withProcessGroup
    , terminateProcessGroup
    , interruptProcessGroup
    , waitExitCode
    , getExecutablePath

      -- * Interpreters
    , runProcessIO
    ) where

import Control.Exception (IOException, catch)
import Effectful (Effect, IOE)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Exception (bracket, trySync)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))
import System.Posix.Signals (sigTERM, signalProcessGroup)
import System.Process (Pid, getPid, interruptProcessGroupOf)
import System.Process.Typed
    ( ProcessConfig
    , createPipe
    , proc
    , setCreateGroup
    , setStderr
    , setStdin
    , setStdout
    , setWorkingDir
    , shell
    )

import System.Environment qualified as Env
import System.Process.Typed qualified as TP

import Atelier.Effects.Process.Internal (RunningProcess (..))


-- | The process's stdin stream (its type set by the 'ProcessConfig').
getStdin :: RunningProcess i o e -> i
getStdin (RunningProcess p) = TP.getStdin p


-- | The process's stdout stream.
getStdout :: RunningProcess i o e -> o
getStdout (RunningProcess p) = TP.getStdout p


-- | The process's stderr stream.
getStderr :: RunningProcess i o e -> e
getStderr (RunningProcess p) = TP.getStderr p


data Process :: Effect where
    -- | Run a process to completion, returning its exit code and captured stdout.
    ReadProcessStdout :: ProcessConfig i o e -> Process m (ExitCode, LByteString)
    -- | Run a process to completion, capturing both stdout and stderr along with
    -- its exit code.
    ReadProcess :: ProcessConfig i o e -> Process m (ExitCode, LByteString, LByteString)
    -- | Run a process to completion, returning only its exit code. Unlike
    -- 'ReadProcessStdout' this does not capture stdout.
    RunProcess :: ProcessConfig i o e -> Process m ExitCode
    -- | The absolute path of the currently running executable, for re-invoking
    -- this program as a subprocess.
    GetExecutablePath :: Process m FilePath
    -- | Spawn a process and return its handle. Internal; callers use 'withProcessGroup'.
    StartProcess :: ProcessConfig i o e -> Process m (RunningProcess i o e)
    -- | Terminate the leader and close its streams. Internal; does not reach the
    -- rest of the group.
    StopProcess :: RunningProcess i o e -> Process m ()
    -- | Block until the process exits and return its exit code.
    WaitExitCode :: RunningProcess i o e -> Process m ExitCode
    -- | Send SIGINT to the process's group. Requires @'setCreateGroup' True@.
    InterruptProcessGroup :: RunningProcess i o e -> Process m ()
    -- | Look up the OS process id, or 'Nothing' if it has already exited. Internal.
    GetProcessId :: RunningProcess i o e -> Process m (Maybe Pid)
    -- | Send SIGTERM to the given process group. Internal.
    SignalProcessGroupTerm :: Pid -> Process m ()


makeEffect ''Process


-- | Run a process in its own process group, terminating the /whole group/ — the
-- process and every descendant it spawned — when the body returns or throws.
--
-- Cleanup is guaranteed even if the process has already exited. The body may
-- share the handle so another thread can 'terminateProcessGroup' it early.
withProcessGroup
    :: (Process :> es)
    => ProcessConfig i o e
    -> (RunningProcess i o e -> Eff es a)
    -> Eff es a
withProcessGroup cfg body =
    bracket acquire release (\(p, _) -> body p)
  where
    acquire = do
        p <- startProcess (setCreateGroup True cfg)
        pgid <- getProcessId p
        pure (p, pgid)
    release (p, pgid) = tearDownGroup pgid p


-- | Terminate a running process and its /whole group/ immediately. Use this to
-- abort a process started with 'withProcessGroup' from another thread — for
-- children that trap SIGINT, where 'interruptProcessGroup' is not enough.
terminateProcessGroup :: (Process :> es) => RunningProcess i o e -> Eff es ()
terminateProcessGroup p = do
    pgid <- getProcessId p
    tearDownGroup pgid p


-- | SIGTERM the group (if its id is known), then best-effort reap the leader.
tearDownGroup :: (Process :> es) => Maybe Pid -> RunningProcess i o e -> Eff es ()
tearDownGroup pgid p = do
    maybe (pure ()) signalProcessGroupTerm pgid
    void $ trySync $ stopProcess p


-- | Run @cmd@ with @args@ and return its stdout as 'Text', or 'Nothing' on any
-- error (non-zero exit, the executable not being found, etc.).
readProcessSafe :: (Process :> es) => FilePath -> [String] -> Eff es (Maybe Text)
readProcessSafe cmd args = do
    result <- trySync $ readProcessStdout (proc cmd args)
    pure $ case result of
        Right (ExitSuccess, out) -> Just (decodeUtf8 out)
        _ -> Nothing


runProcessIO :: (IOE :> es) => Eff (Process : es) a -> Eff es a
runProcessIO = interpret_ \case
    ReadProcessStdout cfg -> liftIO $ TP.readProcessStdout cfg
    ReadProcess cfg -> liftIO $ TP.readProcess cfg
    RunProcess cfg -> liftIO $ TP.runProcess cfg
    GetExecutablePath -> liftIO Env.getExecutablePath
    StartProcess cfg -> liftIO $ RunningProcess <$> TP.startProcess cfg
    StopProcess (RunningProcess p) -> liftIO $ TP.stopProcess p
    WaitExitCode (RunningProcess p) -> liftIO $ TP.waitExitCode p
    InterruptProcessGroup (RunningProcess p) -> liftIO $ interruptProcessGroupOf (TP.unsafeProcessHandle p)
    GetProcessId (RunningProcess p) -> liftIO $ getPid (TP.unsafeProcessHandle p)
    SignalProcessGroupTerm pid ->
        liftIO $ signalProcessGroup sigTERM pid `catch` \(_ :: IOException) -> pure ()
