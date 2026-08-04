module Unit.Tricorder.SocketSpec (spec_Socket) where

import Atelier.Effects.File (File, runFile)
import Effectful (IOE, runEff)
import System.IO (hClose, hGetLine, openFile, writeFile)
import Test.Hspec (Spec, describe, it, shouldBe)

import Tricorder.Socket.Client (isDaemonReady)
import Tricorder.Socket.UnixSocket
    ( SocketScript (..)
    , UnixSocket
    , acceptHandle
    , bindSocket
    , removeSocketFile
    , runUnixSocketIO
    , runUnixSocketScripted
    , socketFileExists
    )


spec_Socket :: Spec
spec_Socket = do
    describe "runUnixSocketScripted" testScripted
    describe "isDaemonReady" testReady


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: Spec
testScripted = do
    describe "socketFileExists" do
        it "returns True when scripted" do
            result <- runScripted [NextFileCheck True] $ socketFileExists "/"
            result `shouldBe` True

        it "returns False when scripted" do
            result <- runScripted [NextFileCheck False] $ socketFileExists "/"
            result `shouldBe` False

    describe "removeSocketFile" do
        it "is always a no-op" do
            -- No NextFileCheck/NextAccept needed; just returns ()
            runScripted [] $ removeSocketFile "/nonexistent/path"

    describe "acceptHandle" do
        it "returns the scripted handle, readable from a file" do
            let tmpPath = "/tmp/tricorder-socket-accept-test.txt"
            writeFile tmpPath "hello from test\n"
            h <- liftIO $ openFile tmpPath ReadMode
            line <- runScripted [NextAccept h] $ do
                sock <- bindSocket "/"
                h' <- acceptHandle sock
                liftIO $ hGetLine h'
            liftIO $ hClose h
            line `shouldBe` "hello from test"


--------------------------------------------------------------------------------
-- isDaemonReady (real IO interpreter)
--------------------------------------------------------------------------------

testReady :: Spec
testReady = do
    it "returns False when nothing is listening on the path" do
        -- A connect to a non-existent socket must be caught, not thrown: this is
        -- the race the start/status path hit before the socket was bound.
        result <- runIO' $ isDaemonReady "/tmp/tricorder-isdaemonready-absent.sock"
        result `shouldBe` False

    it "returns True once a socket is bound and listening" do
        let path = "/tmp/tricorder-isdaemonready-bound.sock"
        result <- runIO' do
            removeSocketFile path
            _ <- bindSocket path
            isDaemonReady path
        runIO' $ removeSocketFile path
        result `shouldBe` True


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run scripted socket operations (no Delay needed).
runScripted :: [SocketScript] -> Eff '[UnixSocket, File, IOE] a -> IO a
runScripted script = runEff . runFile . runUnixSocketScripted script


-- | Run socket operations against the real IO interpreter.
runIO' :: Eff '[UnixSocket, File, IOE] a -> IO a
runIO' = runEff . runFile . runUnixSocketIO
