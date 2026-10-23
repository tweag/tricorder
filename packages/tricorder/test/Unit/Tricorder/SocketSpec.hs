module Unit.Tricorder.SocketSpec (test_Socket) where

import Atelier.Effects.File (File)
import Atelier.Effects.FileSystem (FileSystem)
import Effectful (IOE, runEff)
import Effectful.Exception (trySync)
import System.IO (hClose, hGetLine, openFile, writeFile)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

import Atelier.Effects.File qualified as File
import Atelier.Effects.FileSystem qualified as FileSystem

import Tricorder.Socket.Client (isDaemonReady)
import Tricorder.Socket.UnixSocket (SocketScript (..), UnixSocket)

import Tricorder.Socket.UnixSocket qualified as UnixSocket


test_Socket :: TestTree
test_Socket =
    testGroup
        "Socket"
        [ testGroup "runUnixSocketScripted" testScripted
        , testGroup "isDaemonReady" testReady
        ]


--------------------------------------------------------------------------------
-- Scripted interpreter tests
--------------------------------------------------------------------------------

testScripted :: [TestTree]
testScripted =
    [ testGroup
        "accept"
        [ testCase "returns the scripted handle, readable from a file" do
            let tmpPath = "/tmp/tricorder-socket-accept-test.txt"
            writeFile tmpPath "hello from test\n"
            h <- liftIO $ openFile tmpPath ReadMode
            line <- runScripted [NextAccept h] $ do
                sock <- UnixSocket.bind "/"
                h' <- UnixSocket.accept sock
                liftIO $ hGetLine h'
            liftIO $ hClose h
            line @?= "hello from test"
        ]
    ]


--------------------------------------------------------------------------------
-- isDaemonReady (real IO interpreter)
--------------------------------------------------------------------------------

testReady :: [TestTree]
testReady =
    [ testCase "returns False when nothing is listening on the path" do
        -- A connect to a non-existent socket must be caught, not thrown: this is
        -- the race the start/status path hit before the socket was bound.
        result <- runIO' $ isDaemonReady "/tmp/tricorder-isdaemonready-absent.sock"
        result @?= False
    , testCase "returns True once a socket is bound and listening" do
        let path = "/tmp/tricorder-isdaemonready-bound.sock"
        result <- runIO' do
            void $ trySync $ FileSystem.removeFile path
            _ <- UnixSocket.bind path
            isDaemonReady path
        runIO' $ void $ trySync $ FileSystem.removeFile path
        result @?= True
    ]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run scripted socket operations (no Delay needed).
runScripted :: [SocketScript] -> Eff '[UnixSocket, File, IOE] a -> IO a
runScripted script = runEff . File.run . UnixSocket.runScripted script


-- | Run socket operations against the real IO interpreter.
runIO' :: Eff '[UnixSocket, File, FileSystem, IOE] a -> IO a
runIO' = runEff . FileSystem.runIO . File.run . UnixSocket.runIO
