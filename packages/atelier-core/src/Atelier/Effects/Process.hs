{-# OPTIONS_GHC -Wno-redundant-constraints #-}

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
    , run
    )
where

import Control.Exception (IOException, catch)
import Effectful (Dispatch (..), DispatchOf, Effect, IOE)
import Effectful.Dispatch.Static (SideEffects (..), StaticRep, evalStaticRep, unsafeEff_)
import Effectful.Exception (bracket, trySync)
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


data Process :: Effect


type instance DispatchOf Process = Static 'WithSideEffects


data instance StaticRep Process = Process


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


-- | Run a process to completion, returning its exit code and captured stdout.
readProcessStdout :: (Process :> es) => ProcessConfig i o e -> Eff es (ExitCode, LByteString)
readProcessStdout = unsafeEff_ . TP.readProcessStdout


-- | Run a process to completion, capturing both stdout and stderr along with
-- its exit code.
readProcess :: (Process :> es) => ProcessConfig i o e -> Eff es (ExitCode, LByteString, LByteString)
readProcess = unsafeEff_ . TP.readProcess


runProcess :: (Process :> es) => ProcessConfig i o e -> Eff es ExitCode
runProcess = unsafeEff_ . TP.runProcess


-- | The absolute path of the currently running executable, for re-invoking
-- this program as a subprocess.
getExecutablePath :: (Process :> es) => Eff es FilePath
getExecutablePath = unsafeEff_ Env.getExecutablePath


-- | Spawn a process and return its handle. Internal; callers use 'withProcessGroup'.
startProcess :: (Process :> es) => ProcessConfig i o e -> Eff es (RunningProcess i o e)
startProcess = unsafeEff_ . fmap RunningProcess . TP.startProcess


-- | Terminate the leader and close its streams. Internal; does not reach the
-- rest of the group.
stopProcess :: (Process :> es) => RunningProcess i o e -> Eff es ()
stopProcess = unsafeEff_ . TP.stopProcess . getRunningProcess


-- | Block until the process exits and return its exit code.
waitExitCode :: (Process :> es) => RunningProcess i o e -> Eff es ExitCode
waitExitCode = unsafeEff_ . TP.waitExitCode . getRunningProcess


-- | Send SIGINT to the process's group. Requires @'setCreateGroup' True@.
interruptProcessGroup :: (Process :> es) => RunningProcess i o e -> Eff es ()
interruptProcessGroup = unsafeEff_ . interruptProcessGroupOf . TP.unsafeProcessHandle . getRunningProcess


-- | Look up the OS process id, or 'Nothing' if it has already exited. Internal.
getProcessId :: (Process :> es) => RunningProcess i o e -> Eff es (Maybe Pid)
getProcessId = unsafeEff_ . getPid . TP.unsafeProcessHandle . getRunningProcess


-- | Send SIGTERM to the given process group. Internal.
signalProcessGroupTerm :: (Process :> es) => Pid -> Eff es ()
signalProcessGroupTerm pid =
    unsafeEff_ $ signalProcessGroup sigTERM pid `catch` \(_ :: IOException) -> pure ()


run :: (IOE :> es) => Eff (Process : es) a -> Eff es a
run = evalStaticRep Process
