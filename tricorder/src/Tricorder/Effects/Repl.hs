module Tricorder.Effects.Repl
    ( Config (..)
    , Repl (..)
    , ReplError (..)
    , SessionState (..)
    , InterruptDecision (..)
    , decideInterrupt
    , waitForBannerOrFail
    , withRepl
    , spawnPersistentRepl
    , exec
    , interrupt
    , terminate
    ) where

import Atelier.Effects.Conc (Conc, Scope)
import Atelier.Effects.File (BufferMode (..), File, Handle)
import Atelier.Effects.Process
    ( Process
    , RunningProcess
    , createPipe
    , getStderr
    , getStdin
    , getStdout
    , setStderr
    , setStdin
    , setStdout
    , setWorkingDir
    , shell
    )
import Atelier.Effects.Timeout (Timeout, timeout)
import Control.Concurrent.STM (TVar, modifyTVar', readTVar, retry, writeTVar)
import Data.Default (Default (..))
import Data.Time.Units (Second)
import Effectful.Concurrent (Concurrent)
import Effectful.Concurrent.MVar (newEmptyMVar, putMVar, readMVar, takeMVar, tryPutMVar)
import Effectful.Concurrent.STM (atomically, newTVarIO)
import Effectful.Exception (finally, throwIO, trySync)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.File qualified as File
import Atelier.Effects.Process qualified as Process
import Data.Text qualified as T

import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoading (..)
    , parseProgressLine
    , stripAnsi
    )
import Tricorder.Session (Command (..))


-- | Configuration for GHCi process management.
data Config = Config
    { startupTimeout :: Second
    -- ^ How long to wait for the GHCi version banner on startup.
    , shutdownTimeout :: Second
    -- ^ How long to wait for the process to exit gracefully before force-killing.
    , extraSetupCommands :: [Text]
    -- ^ Additional GHCi commands to send after the fixed setup block.
    -- Use this to inject session-wide options such as @:set -XOverloadedStrings@.
    }


instance Default Config where
    def =
        Config
            { startupTimeout = 60
            , shutdownTimeout = 5
            , extraSetupCommands = []
            }


data SessionState = Idle Int | Busy Int
    deriving stock (Eq, Show)


-- | The outcome of consulting the 'SessionState' when an interrupt arrives.
--
-- 'NoOpIdle' means the GHCi session is at the prompt — sending SIGINT and a
-- sync marker would dirty the buffers and desync the next 'exec'.
-- 'SendInterruptFor n' means a command was in flight (state 'Busy n') and
-- the caller should SIGINT the process group and re-write @markerFor n@ (that
-- command's own marker) to unblock the in-progress 'drainUntil'.
data InterruptDecision
    = NoOpIdle
    | SendInterruptFor Int
    deriving stock (Eq, Show)


-- | Pure state machine for 'interrupt'. Returns the new 'SessionState'
-- to install along with the 'InterruptDecision' the caller should act on.
decideInterrupt :: SessionState -> (SessionState, InterruptDecision)
decideInterrupt s@(Idle _) = (s, NoOpIdle)
decideInterrupt (Busy n) = (Idle (n + 1), SendInterruptFor n)


-- | A handle to a running GHCi subprocess.
data Repl = Repl
    { stdin :: Handle
    , stdout :: Handle
    , stderr :: Handle
    , handle :: RunningProcess Handle Handle Handle
    , stateVar :: TVar SessionState
    }


-- | Errors that can occur during GHCi process management.
data ReplError
    = StartupTimeout
    | UnexpectedExit Text (Maybe Text)
    | -- | The build command exited (or printed nothing parseable) before GHCi
      -- produced its version banner. The 'Text' is the captured stderr+stdout
      -- output so callers can surface a useful error (e.g. cabal's dependency
      -- resolution failure).
      StartupFailed Text
    deriving stock (Eq, Show)


instance Exception ReplError


-- | Set up the GHCi protocol on an already-started process and return its
-- handle together with the output captured during startup.
--
-- The spawn and group teardown are owned by 'withRepl'.
setupRepl
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Timeout :> es
       )
    => Config
    -> RunningProcess Handle Handle Handle
    -> (GhciLoading -> Eff es ())
    -- ^ Called as each @[N of M] Compiling …@ line is streamed during the
    -- initial-build drain, so the UI can update the progress bar live
    -- instead of replaying everything once compilation finishes.
    -> (Repl -> Eff es ())
    -- ^ @onReady@. Called once the 'Repl' is constructed but before the
    -- banner wait and initial-build drain — so callers can register the process
    -- for interruption while the slow @cabal repl@ startup (dependency build
    -- and recompilation) is still in progress.
    -> Eff es (Repl, [Text])
setupRepl config p onProgress onReady = do
    let inp = getStdin p
        out = getStdout p
        err = getStderr p
    File.hSetBuffering inp LineBuffering
    File.hSetBuffering out LineBuffering
    File.hSetBuffering err LineBuffering

    -- Register the process for interruption before the (possibly slow) banner
    -- wait, so an interrupt during @cabal repl@ startup can terminate it.
    stateVar <- newTVarIO (Idle 0)
    let repl =
            Repl
                { stdin = inp
                , stdout = out
                , stderr = err
                , handle = p
                , stateVar = stateVar
                }
    onReady repl

    -- Send a blank line to kick GHCi into producing output
    File.hPutTextLn inp ""
    File.hFlush inp

    -- Wait for the version banner. We concurrently capture stderr so that if
    -- the build command exits before printing a banner (e.g. cabal's
    -- dependency resolution fails) we can surface its error output.
    waitForBannerOrFail config.startupTimeout out err

    -- Send fixed setup commands (protocol requirements)
    File.hPutTextLn inp ":set prompt \"\""
    File.hPutTextLn inp ":set prompt-cont \"\""
    File.hPutTextLn inp ":set +c"
    -- Send any caller-supplied extra setup commands
    for_ config.extraSetupCommands \c ->
        File.hPutTextLn inp c
    File.hFlush inp

    -- Sync: drain until marker 1 seen, then set counter to 2.
    -- Capture lines from both streams — the stderr output contains the initial
    -- compilation progress and any startup diagnostics. The line hook fires
    -- 'onProgress' for each "[N of M] Compiling …" line as it arrives, so the
    -- UI can update the progress bar live during the initial build.
    let marker1 = markerFor 1
        hook = progressLineHook onProgress
    sendSyncCommand inp marker1
    initialLines <- Conc.scoped do
        stdoutThread <- Conc.fork $ drainUntil out marker1 hook
        stderrThread <- Conc.fork $ drainUntil err marker1 hook
        stdoutLines <- Conc.await stdoutThread
        stderrLines <- Conc.await stderrThread
        pure (stdoutLines ++ stderrLines)
    atomically $ writeTVar stateVar (Idle 2)

    pure (repl, initialLines)


-- | Run a GHCi @cabal repl@ session for the duration of @action@.
--
-- The session runs in its own process group, so the whole group is torn down on
-- exit; 'quitRepl' first asks GHCi to @:quit@ for a graceful shutdown. The
-- action receives the process handle and the output captured during startup.
-- See 'setupRepl' for the @onProgress@ and @onReady@ callbacks.
withRepl
    :: (Conc :> es, Concurrent :> es, File :> es, Process :> es, Timeout :> es)
    => Config
    -> Command
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> (Repl -> Eff es ())
    -> (Repl -> [Text] -> Eff es a)
    -> Eff es a
withRepl config cmd dir onProgress onReady action =
    Process.withProcessGroup (replProcessConfig cmd dir) \p -> do
        (repl, initialLines) <- setupRepl config p onProgress onReady
        action repl initialLines `finally` quitRepl config repl


-- | The @typed-process@ config for a @cabal repl@ session: all three streams
-- piped and the working directory pinned to the project root.
replProcessConfig :: Command -> FilePath -> Process.ProcessConfig Handle Handle Handle
replProcessConfig cmd dir =
    setStdin createPipe
        $ setStdout createPipe
        $ setStderr createPipe
        $ setWorkingDir dir
        $ shell (toString cmd.getCommand)


-- | Start a GHCi session that outlives a single command, for reuse across many
-- 'exec' calls (turbo test mode). Where 'withRepl' brackets one short-lived
-- session, this returns the live 'Repl' plus a @stop@ action that tears its
-- process group down and blocks until it is fully reaped.
--
-- The session is held open by a background thread forked into @scope@ — a
-- long-lived 'Conc' scope captured by the caller (via 'Conc.currentScope').
-- Because the thread lives in that scope rather than the transient one this is
-- called from, it survives the per-build-cycle scopes it is spawned under, yet
-- is still structurally cancelled when @scope@ closes (daemon shutdown) — so it
-- cannot leak. @stop@ evicts it early: it is idempotent and awaits the
-- teardown, so a caller that evicts-then-respawns in a shared @--builddir@
-- never races the dying process.
spawnPersistentRepl
    :: (Conc :> es, Concurrent :> es, File :> es, Process :> es, Timeout :> es)
    => Scope
    -> Config
    -> Command
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> (Repl -> Eff es ())
    -> Eff es (Repl, [Text], Eff es ())
spawnPersistentRepl scope config cmd dir onProgress onReady = do
    readyVar <- newEmptyMVar
    stopVar <- newEmptyMVar
    doneVar <- newEmptyMVar
    void $ Conc.forkIn scope $ (`finally` putMVar doneVar ()) do
        outcome <- trySync $ Process.withProcessGroup (replProcessConfig cmd dir) \p -> do
            replAndLines <- setupRepl config p onProgress onReady
            putMVar readyVar (Right replAndLines)
            -- Park until stopped; then quit GHCi gracefully before the
            -- enclosing 'withProcessGroup' reaps the group.
            takeMVar stopVar `finally` quitRepl config (fst replAndLines)
        -- Setup threw before the session became ready: hand the error back so
        -- the caller can surface it. If setup succeeded 'readyVar' is already
        -- full and this 'tryPutMVar' is a no-op.
        case outcome of
            Left e -> void $ tryPutMVar readyVar (Left e)
            Right () -> pure ()
    let stop = do
            void $ tryPutMVar stopVar ()
            readMVar doneVar
    takeMVar readyVar >>= \case
        Left e -> readMVar doneVar >> throwIO e
        Right (repl, initialLines) -> pure (repl, initialLines, stop)


-- | Execute a command in GHCi and return the combined stdout+stderr output
-- lines. The @onProgress@ callback fires for each @[N of M] Compiling …@ line
-- as it arrives, so reload/add/unadd progress is streamed live to the UI.
-- Pass @\\_ -> pure ()@ for commands that do not trigger compilation.
exec
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       )
    => Repl -> Text -> (GhciLoading -> Eff es ()) -> Eff es [Text]
exec repl command onProgress = do
    n <- atomically do
        readTVar repl.stateVar >>= \case
            Idle n -> writeTVar repl.stateVar (Busy n) $> n
            Busy _ -> retry
    doExec n `finally` atomically (writeTVar repl.stateVar (Idle (n + 1)))
  where
    doExec n = do
        let marker = markerFor n
            hook = progressLineHook onProgress
        File.hPutTextLn repl.stdin command
        File.hFlush repl.stdin
        sendSyncCommand repl.stdin marker
        -- Scoped so that an exception from one drain (e.g. 'UnexpectedExit'
        -- when the underlying process is terminated mid-command) is
        -- contained here, re-raised by 'await', and caught by the caller's
        -- 'trySync'. Without 'scoped', Ki propagates the exception to the
        -- \*ambient* scope — typically the builder's listener scope — which
        -- tears down the whole builder loop instead of just failing this
        -- one command.
        (stdoutLines, stderrLines) <- Conc.scoped do
            stdoutThread <- Conc.fork $ drainUntil repl.stdout marker hook
            stderrThread <- Conc.fork $ drainUntil repl.stderr marker hook
            (,) <$> Conc.await stdoutThread <*> Conc.await stderrThread
        pure (stdoutLines ++ stderrLines)


-- | Interrupt the currently running GHCi command (if any).
--
-- If a command is in progress (state 'Busy n'), sends SIGINT to the GHCi
-- process group and re-writes /that command's own/ sync marker (@markerFor n@)
-- so the in-progress 'drainUntil', which is waiting for exactly that marker,
-- unblocks. The next command runs as @n + 1@ and waits for @markerFor (n + 1)@,
-- so any duplicate @markerFor n@ left in the buffers is skipped by 'drainUntil'
-- rather than mistaken for the next command's marker.
--
-- When GHCi is 'Idle' this is a true no-op: sending SIGINT and a sync marker to
-- an idle GHCi leaves leftover marker output in the buffers.
interrupt :: (Concurrent :> es, File :> es, Process :> es) => Repl -> Eff es ()
interrupt repl = do
    decision <- atomically do
        s <- readTVar repl.stateVar
        let (s', d) = decideInterrupt s
        writeTVar repl.stateVar s'
        pure d
    case decision of
        NoOpIdle -> pure ()
        SendInterruptFor n -> do
            Process.interruptProcessGroup repl.handle
            sendSyncCommand repl.stdin (markerFor n)


-- | Forcefully terminate a GHCi process and its whole group.
--
-- Stronger than 'interrupt': intended for one-shot processes (such as the
-- per-suite @cabal repl test:…@ used by the test runner) where SIGINT is
-- insufficient — test frameworks like @hspec@ and @tasty@ install SIGINT
-- handlers that finalise the current run rather than aborting it. Safe to call
-- from another thread while the session is running.
terminate :: (Process :> es) => Repl -> Eff es ()
terminate repl =
    Process.terminateProcessGroup repl.handle


-- | Ask GHCi to @:quit@ and wait briefly for it to exit cleanly, letting it
-- shut down gracefully before the enclosing 'withRepl' tears down the
-- group. Never throws.
quitRepl :: (File :> es, Process :> es, Timeout :> es) => Config -> Repl -> Eff es ()
quitRepl config repl = do
    void $ trySync $ do
        File.hPutTextLn repl.stdin ":quit"
        File.hFlush repl.stdin
    void $ timeout config.shutdownTimeout (Process.waitExitCode repl.handle)


-- ---------------------------------------------------------------------------
-- Internal helpers

-- | Build the finish marker for counter value @n@.
markerFor :: Int -> Text
markerFor n = markerPrefix <> show n <> "~#"


-- | The prefix shared by all finish markers.
markerPrefix :: Text
markerPrefix = "#~TRI-FINISH-"


-- | Write the synchronisation Haskell statements to GHCi stdin.
--
-- After each user command, these cause GHCi to emit the finish marker on both
-- stdout and stderr, so 'drainUntil' knows when to stop.
--
-- The marker is emitted as two standalone, fully-qualified statements — one per
-- stream — using only 'System.IO.hPutStrLn'. This is deliberate: a
-- SIGINT-interrupted ':reload' empties GHCi's interactive scope, dropping the
-- implicit @import Prelude@, so bare names like @putStrLn@ (and even the @>>@
-- operator) fall out of scope. A marker built from those would /error/ instead
-- of printing — its marker would never appear and 'drainUntil' would block
-- forever waiting for it (the "stuck Building…" stall). Fully-qualified
-- 'System.IO.hPutStrLn' resolves via GHCi's implicit qualified imports even
-- with an emptied scope, so the marker survives an interrupt.
sendSyncCommand :: (File :> es) => Handle -> Text -> Eff es ()
sendSyncCommand h marker = do
    -- Use show to produce a valid Haskell string literal for the marker text.
    let markerLit = toText (show @String (toString marker)) -- e.g. "\"#~TRI-FINISH-3~#\""
    File.hPutTextLn h ("System.IO.hPutStrLn System.IO.stdout " <> markerLit)
    File.hPutTextLn h ("System.IO.hPutStrLn System.IO.stderr " <> markerLit)
    File.hFlush h


-- | Read lines from a handle until /this command's/ finish marker is seen (or
-- EOF).
--
-- Stops only on a line containing the exact @marker@ it was given. A line
-- carrying a /different/ finish marker — a stale leftover from a prior command
-- that was interrupted mid-flight — is skipped rather than matched, so it can
-- never make a later drain return prematurely (the "0 modules"/hang desync).
-- Each ordinary line is passed to @onLine@ as it arrives, so callers can stream
-- progress without waiting for the full drain to complete. Returns accumulated
-- non-marker lines in order. Throws 'UnexpectedExit' on EOF before the marker.
drainUntil :: (File :> es) => Handle -> Text -> (Text -> Eff es ()) -> Eff es [Text]
drainUntil h marker onLine = go []
  where
    go acc = do
        result <- trySync $ File.hGetLine h
        case result of
            Left _ ->
                throwIO $ UnexpectedExit marker (listToMaybe (reverse acc))
            Right line
                | marker `T.isInfixOf` line -> pure (reverse acc)
                -- A stale marker from an interrupted command: drop it, keep going.
                | markerPrefix `T.isInfixOf` line -> go acc
                | otherwise -> do
                    onLine line
                    go (line : acc)


-- | Convert a 'GhciLoading' progress callback into a per-line hook suitable
-- for 'drainUntil'. Non-progress lines are ignored.
progressLineHook :: (GhciLoading -> Eff es ()) -> Text -> Eff es ()
progressLineHook onProgress line = traverse_ onProgress (parseProgressLine line)


-- | Wait up to the given number of seconds for a GHCi version banner on
-- stdout, capturing stderr (and any non-banner stdout lines) in case the
-- build command fails before printing a banner.
--
-- Throws 'StartupFailed' with the captured output if stdout EOFs (the build
-- command exited) or 'StartupTimeout' if the banner never arrives.
waitForBannerOrFail
    :: ( Conc :> es
       , Concurrent :> es
       , File :> es
       , Timeout :> es
       )
    => Second -> Handle -> Handle -> Eff es ()
waitForBannerOrFail delay out err = do
    capturedVar <- newTVarIO ([] :: [Text])
    let captureLine line = atomically $ modifyTVar' capturedVar (line :)
        drainStderr = drainUntilEof err captureLine
        watchStdout = waitForBannerStdout out captureLine

    Conc.scoped do
        stderrThread <- Conc.fork drainStderr
        result <- timeout delay $ trySync watchStdout
        case result of
            Just (Right ()) -> pure ()
            Just (Left ex) -> do
                -- stdout EOF before the banner: the build command exited. Wait
                -- for the stderr drain to reach EOF too (bounded, in case the
                -- pipe lingers) so we surface its *complete* output — e.g.
                -- cabal's dependency-resolution error — rather than whatever
                -- the drain happened to have read so far.
                _ <- timeout (1 :: Second) (Conc.await stderrThread)
                captured <- atomically $ readTVar capturedVar
                throwIO $ StartupFailed $ fromMaybe (startupExitedMessage ex) (renderCapturedLines captured)
            Nothing -> do
                captured <- atomically $ readTVar capturedVar
                throwIO $ maybe StartupTimeout StartupFailed (renderCapturedLines captured)


waitForBannerStdout :: (File :> es) => Handle -> (Text -> Eff es ()) -> Eff es ()
waitForBannerStdout h captureLine = go
  where
    isVersionLine :: Text -> Bool
    isVersionLine line =
        let stripped = stripAnsi line
        in  "GHCi, version " `T.isInfixOf` stripped
                || "GHCJSi, version " `T.isInfixOf` stripped
                || "Clashi, version " `T.isInfixOf` stripped

    go = do
        result <- trySync $ File.hGetLine h
        case result of
            Left ex -> throwIO ex
            Right line ->
                if isVersionLine line then
                    pure ()
                else do
                    captureLine line
                    go


drainUntilEof :: (File :> es) => Handle -> (Text -> Eff es ()) -> Eff es ()
drainUntilEof h onLine = go
  where
    go = do
        result <- trySync $ File.hGetLine h
        case result of
            Left _ -> pure ()
            Right line -> onLine line >> go


-- | Render the captured (reverse-order) output lines into an error message,
-- stripping ANSI escapes and dropping blank lines. Returns 'Nothing' when
-- nothing useful remains, so callers can fall back to a generic message.
renderCapturedLines :: [Text] -> Maybe Text
renderCapturedLines capturedRev =
    let cleaned = filter (not . T.null . T.strip) (map stripAnsi (reverse capturedRev))
    in  if null cleaned then Nothing else Just (T.intercalate "\n" cleaned)


-- | Fallback message when the build command exited before the banner without
-- printing anything we could capture.
startupExitedMessage :: SomeException -> Text
startupExitedMessage ex =
    "Build command exited before GHCi started: " <> toText (displayException ex)
