module Unit.Tricorder.Effects.ReplSpec (spec_Repl) where

import Atelier.Effects.Conc (runConc)
import Atelier.Effects.Delay (runDelay)
import Atelier.Effects.File (runFile)
import Atelier.Effects.Process (runProcessIO, terminateProcessGroup, withProcessGroup)
import Atelier.Effects.Process.Internal (RunningProcess (..))
import Atelier.Effects.Timeout (runTimeout)
import Atelier.Time (Millisecond)
import Control.Concurrent (threadDelay)
import Control.Concurrent.STM (newTVarIO)
import Control.Exception (IOException, catch)
import Data.Char (isDigit)
import Data.IORef (newIORef, readIORef, writeIORef)
import Data.Time.Units (Second)
import Effectful (runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Exception (trySync)
import System.IO (hGetLine)
import System.Posix.Signals (nullSignal, sigKILL, signalProcess)
import System.Process.Typed
    ( createPipe
    , getStderr
    , getStdin
    , getStdout
    , setCreateGroup
    , setStderr
    , setStdin
    , setStdout
    , shell
    , startProcess
    , stopProcess
    , waitExitCode
    )
import Test.Hspec

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Delay qualified as Delay
import Atelier.Effects.File qualified as File
import Atelier.Effects.Process qualified as AProc
import Data.Text qualified as T
import System.Process qualified as Process
import System.Timeout qualified

import Tricorder.Effects.Repl
    ( InterruptDecision (..)
    , Repl (..)
    , ReplError (..)
    , SessionState (..)
    , decideInterrupt
    , exec
    , waitForBannerOrFail
    )


spec_Repl :: Spec
spec_Repl = do
    describe "decideInterrupt" testDecideInterrupt
    describe "exec" testExecGhciScope
    describe "exec (stale marker desync)" testExecGhciStaleMarker
    describe "exec (sync marker scope independence)" testSyncMarkerScopeIndependent
    describe "waitForBannerOrFail" testWaitForBannerOrFail
    describe "withProcessGroup (process group)" testWithProcessGroupCleanup
    describe "terminateProcessGroup (process group)" testTerminateProcessGroup


-- | Regression for the touch-during-reload desync. Interrupting a *Busy* GHCi
-- (a reload in flight) leaves a stale sync marker in the stdout/stderr buffers
-- ahead of the next command's real output. Because 'drainUntil' used to stop on
-- ANY marker-prefix line, the next 'exec' matched that stale marker and
-- returned *before its command ran* — surfacing as @All good. (0 modules)@ (or,
-- on the other timing, a hang). 'exec' must skip markers that aren't its
-- own and stop only on the marker it is waiting for.
testExecGhciStaleMarker :: Spec
testExecGhciStaleMarker =
    it "skips a stale leftover marker and returns the command's real output" do
        (stdinR, stdinW) <- Process.createPipe
        (stdoutR, stdoutW) <- Process.createPipe
        (stderrR, stderrW) <- Process.createPipe
        -- A dummy process handle to fill the record; 'exec' never uses it.
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 9)
        let gp =
                Repl
                    { stdin = stdinW
                    , stdout = stdoutR
                    , stderr = stderrR
                    , handle = RunningProcess p
                    , stateVar
                    }
            -- Mirrors 'markerFor': "#~TRI-FINISH-<n>~#".
            marker n = "#~TRI-FINISH-" <> show (n :: Int) <> "~#" :: Text
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ do
                    -- A stale 'marker 5' (left by a prior interrupted reload)
                    -- precedes the fresh command's real output + its 'marker 9'
                    -- (state is 'Idle 9', so 'exec' waits for marker 9).
                    for_ [marker 5, "out-line", marker 9] (File.hPutTextLn stdoutW)
                    for_ [marker 5, "err-line", marker 9] (File.hPutTextLn stderrW)
                    File.hClose stdoutW
                    File.hClose stderrW
                    -- Keep the stdin read-end alive across the write inside
                    -- 'exec' (otherwise it is GC-finalised → broken pipe).
                    r <- exec gp "reload" (\_ -> pure ())
                    File.hClose stdinR
                    pure r
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        result `shouldBe` ["out-line", "err-line"]


-- | Root-cause regression for the "stuck Building…" stall. A SIGINT-interrupted
-- ':reload' empties GHCi's interactive scope — it drops the implicit
-- @import Prelude@ (verified against ghci 9.10). A sync marker built from bare
-- Prelude names then fails to run instead of printing: @putStrLn@ is no longer
-- in scope, and neither is the @>>@ operator. The marker never appears, so
-- 'drainUntil' blocks until the watchdog fires. The marker must therefore use
-- only fully-qualified 'System.IO.hPutStrLn' statements (which survive the
-- emptied scope), one per stream, with no bare names or operators.
--
-- We assert on exactly what 'exec' writes to GHCi's stdin.
testSyncMarkerScopeIndependent :: Spec
testSyncMarkerScopeIndependent =
    it "writes the finish marker using only fully-qualified names (no bare putStrLn / >>)" do
        (stdinR, stdinW) <- Process.createPipe
        (stdoutR, stdoutW) <- Process.createPipe
        (stderrR, stderrW) <- Process.createPipe
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 9)
        let gp =
                Repl
                    { stdin = stdinW
                    , stdout = stdoutR
                    , stderr = stderrR
                    , handle = RunningProcess p
                    , stateVar
                    }
            marker = "#~TRI-FINISH-9~#" :: Text
        written <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ do
                    -- Pre-seed the marker on both streams so the drain returns
                    -- immediately; we only care about what was written to stdin.
                    File.hPutTextLn stdoutW marker
                    File.hPutTextLn stderrW marker
                    File.hClose stdoutW
                    File.hClose stderrW
                    _ <- exec gp ":reload" (\_ -> pure ())
                    File.hClose stdinW
                    let readAll acc =
                            trySync (File.hGetLine stdinR) >>= \case
                                Left (_ :: SomeException) -> pure (reverse acc)
                                Right l -> readAll (l : acc)
                    readAll []
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        let blob = T.intercalate "\n" written
        (" >> " `T.isInfixOf` blob) `shouldBe` False
        ("System.IO.hPutStrLn System.IO.stdout" `T.isInfixOf` blob) `shouldBe` True
        ("System.IO.hPutStrLn System.IO.stderr" `T.isInfixOf` blob) `shouldBe` True


-- | Regression: when the build command exits before printing a GHCi banner,
-- 'waitForBannerOrFail' must surface the *complete* stderr output in the
-- 'StartupFailed' error. The original implementation snapshotted the captured
-- lines as soon as the process exited (it waited on 'waitExitCode'), racing
-- the concurrent stderr drain — so a burst of error lines still buffered in
-- the pipe was truncated, and the real cabal/build failure was lost.
testWaitForBannerOrFail :: Spec
testWaitForBannerOrFail =
    it "captures the full stderr output when the command exits before the banner" do
        let lineCount = 200 :: Int
            lastLine = "err line " <> show lineCount
        -- The banner and error streams are pipes we drive ourselves, so the
        -- timing is deterministic rather than a race against the OS pipe buffer.
        (bannerOut, bannerOutW) <- Process.createPipe
        (errR, errW) <- Process.createPipe
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ do
                    -- No banner will ever arrive: close the write end so the
                    -- wait sees EOF at once and takes the "command exited"
                    -- failure branch.
                    File.hClose bannerOutW
                    -- Producer: pause long enough that a snapshot-at-exit reads
                    -- an empty buffer, THEN stream the whole error log and
                    -- close so the drain sees EOF. A correct implementation
                    -- awaits that drain before reading the captured lines.
                    _ <- Conc.fork do
                        Delay.wait (30 :: Millisecond)
                        for_ [1 .. lineCount] \i ->
                            File.hPutTextLn errW ("err line " <> show i :: Text)
                        File.hClose errW
                    trySync (waitForBannerOrFail (5 :: Second) bannerOut errR)
        case result of
            Right () -> expectationFailure "expected waitForBannerOrFail to throw a startup error"
            Left ex -> case fromException ex of
                Just (StartupFailed msg) ->
                    (lastLine `T.isInfixOf` msg) `shouldBe` True
                other ->
                    expectationFailure ("expected StartupFailed, got: " <> show other)


-- | Regression for orphaned/zombie build subprocesses on restart and shutdown.
--
-- The original leak was on the /graceful/ path: GHCi exits cleanly on @:quit@,
-- so its leader is reaped, yet the build subprocesses sharing its group linger.
-- 'withProcessGroup' must still sweep the whole group even after the leader has
-- gone. We simulate it with a leader that forks a long-lived child sharing its
-- group and exits on stdin input (mirroring @:quit@); after 'withProcessGroup'
-- returns, the child must be gone.
testWithProcessGroupCleanup :: Spec
testWithProcessGroupCleanup =
    it "terminates the whole group on exit, even after the leader has exited" do
        childPidRef <- newIORef (Nothing :: Maybe Int)
        let scenario =
                runEff
                    . runConcurrent
                    . runTimeout
                    . runDelay
                    . runFile
                    . runConc
                    . runProcessIO
                    $ withProcessGroup procConfig \p -> do
                        -- First stdout line is the long-lived child's pid.
                        line <- File.hGetLine (AProc.getStdout p)
                        liftIO $ writeIORef childPidRef (parsePid (T.unpack line))
                        -- Let the leader exit and reap it, so the cleanup runs
                        -- with the leader already gone — the path the bug needed.
                        File.hPutTextLn (AProc.getStdin p) ""
                        File.hFlush (AProc.getStdin p)
                        void $ AProc.waitExitCode p
        -- Hard wall-clock bound: a regression must surface as a failed
        -- assertion, never as a hang that stalls the whole suite.
        outcome <- System.Timeout.timeout (8_000_000) scenario
        case outcome of
            Nothing -> expectationFailure "test timed out (process did not settle)"
            Just () ->
                readIORef childPidRef >>= \case
                    Nothing -> expectationFailure "could not capture the child pid"
                    Just childPid -> do
                        died <- waitForProcessDeath childPid
                        -- Never leak the child if the assertion fails.
                        ignoring (signalProcess sigKILL (fromIntegral childPid))
                        died `shouldBe` True
  where
    procConfig =
        setStdin createPipe
            $ setStdout createPipe
            $ setStderr createPipe
            $ shell "sleep 30 & echo \"$!\"; read _quit"


-- | 'terminateProcessGroup' must kill the whole group when called mid-flight
-- (the leader still alive) — the explicit early-termination path the test
-- runner uses to abort a one-shot @cabal repl test:…@ from another thread.
testTerminateProcessGroup :: Spec
testTerminateProcessGroup =
    it "kills the whole group, not just the leader, mid-flight" do
        outcome <- System.Timeout.timeout (8_000_000) do
            p <-
                startProcess
                    $ setStdin createPipe
                    $ setStdout createPipe
                    $ setStderr createPipe
                    $ setCreateGroup True
                    $ shell "sleep 30 & echo \"$!\"; read _quit"
            childLine <- hGetLine (getStdout p)
            case parsePid childLine of
                Nothing -> do
                    ignoring (stopProcess p)
                    expectationFailure ("could not parse child pid from: " <> show childLine)
                    pure False
                Just childPid -> do
                    runEff . runProcessIO $ terminateProcessGroup (RunningProcess p)
                    died <- waitForProcessDeath childPid
                    -- Never leak the child if the assertion fails.
                    ignoring (signalProcess sigKILL (fromIntegral childPid))
                    pure died
        outcome `shouldBe` Just True


-- | Parse a pid printed on its own line (tolerating surrounding whitespace).
parsePid :: String -> Maybe Int
parsePid = readMaybe . takeWhile isDigit . dropWhile (not . isDigit)


-- | Swallow any exception from a best-effort cleanup action.
ignoring :: IO () -> IO ()
ignoring act = act `catch` \(_ :: SomeException) -> pure ()


-- | Poll for up to ~3s for the given pid to disappear from the process table.
-- @signalProcess nullSignal@ is a liveness probe: it throws once the process is
-- gone (and reaped by init after being orphaned).
waitForProcessDeath :: Int -> IO Bool
waitForProcessDeath pid = go (60 :: Int)
  where
    go 0 = not <$> alive
    go n = do
        a <- alive
        if not a then pure True else threadDelay 50_000 >> go (n - 1)
    alive =
        (signalProcess nullSignal (fromIntegral pid) >> pure True)
            `catch` \(_ :: IOException) -> pure False


testDecideInterrupt :: Spec
testDecideInterrupt = do
    -- Regression: an idle GHCi must not be SIGINT'd, since the matching
    -- sync-marker write would leave a stale marker line in stdout/stderr
    -- that the next 'exec' drain would match instead of the fresh one,
    -- desyncing the protocol and reporting "0 modules" or hanging.
    it "is a no-op when the session is Idle" do
        decideInterrupt (Idle 7) `shouldBe` (Idle 7, NoOpIdle)

    it "preserves the counter for any Idle state" do
        decideInterrupt (Idle 0) `shouldBe` (Idle 0, NoOpIdle)
        decideInterrupt (Idle 42) `shouldBe` (Idle 42, NoOpIdle)

    it "advances to Idle (n+1) and emits SendInterruptFor n when Busy" do
        decideInterrupt (Busy 7) `shouldBe` (Idle 8, SendInterruptFor 7)

    it "advances correctly from Busy 0" do
        decideInterrupt (Busy 0) `shouldBe` (Idle 1, SendInterruptFor 0)


-- | Pins down the 'Conc.scoped' fix in 'exec': when the drain forks
-- raise 'UnexpectedExit' (because the underlying process exited and EOF'd
-- the pipes), the exception must be CONTAINED inside 'exec' and
-- surfaced via the caller's 'trySync' — not propagated to the ambient
-- 'Conc.scoped' that called 'exec'.
--
-- Without the inner 'Conc.scoped' in 'exec', Ki propagates an
-- exception from a forked thread to its owning scope. If 'exec' forks
-- its drains directly into the ambient scope (the original bug), the
-- ambient scope is torn down — siblings die, the whole builder cycle
-- unwinds, and the daemon ends up in the "Restarting builder..." state
-- the user observed.
testExecGhciScope :: Spec
testExecGhciScope =
    -- Spawn a real subprocess that exits immediately ('true'). Its
    -- stdout/stderr pipes EOF as soon as the child exits, which makes
    -- 'drainUntil' inside 'exec' throw 'UnexpectedExit' — exactly the
    -- mid-command termination path the fix exists to handle.
    it "contains drain exceptions inside its own scope so siblings survive" do
        p <-
            startProcess
                $ setStdin createPipe
                $ setStdout createPipe
                $ setStderr createPipe
                $ shell "true"
        -- Wait for the child to actually exit so the pipes are EOF before
        -- 'exec' starts draining (otherwise the drain blocks).
        _ <- waitExitCode p
        stateVar <- newTVarIO (Idle 0)
        let gp =
                Repl
                    { stdin = getStdin p
                    , stdout = getStdout p
                    , stderr = getStderr p
                    , handle = RunningProcess p
                    , stateVar
                    }
        siblingDoneRef <- newIORef False
        result <-
            runEff
                . runConcurrent
                . runTimeout
                . runDelay
                . runFile
                . runConc
                $ Conc.scoped do
                    -- A sibling fork in the SAME ambient scope. If the bug
                    -- regresses, the drain exception will tear this scope
                    -- down and the sibling will be cancelled before it can
                    -- flip the ref.
                    sibling <- Conc.fork do
                        Delay.wait (50 :: Millisecond)
                        liftIO (writeIORef siblingDoneRef True)
                    -- Drive 'exec' on a dead process; the drains should
                    -- raise 'UnexpectedExit', which 'trySync' must catch
                    -- here rather than letting Ki tear down the scope.
                    execResult <- trySync (exec gp "cmd" (\_ -> pure ()))
                    -- Wait for the sibling to run.
                    Conc.await sibling
                    pure execResult
        -- stopProcess flushes the buffered command+marker to a pipe whose
        -- read end is already closed, which raises ResourceVanished. The
        -- subprocess has long since exited; just swallow the cleanup error.
        _ <- (Right <$> stopProcess p) `catch` \(_ :: SomeException) -> pure (Left ())
        siblingDone <- readIORef siblingDoneRef
        siblingDone `shouldBe` True
        case result of
            Left _ -> pure ()
            Right _ -> expectationFailure "expected exec to raise UnexpectedExit"
