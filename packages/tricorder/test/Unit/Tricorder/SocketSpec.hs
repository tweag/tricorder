module Unit.Tricorder.SocketSpec (test_Socket) where

import Atelier.Effects.File (File, runFile)
import Effectful (IOE, runEff)
import System.IO (hClose, hGetLine, openFile, writeFile)
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit (testCase, (@?=))

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
        "socketFileExists"
        [ testCase "returns True when scripted" do
            result <- runScripted [NextFileCheck True] $ socketFileExists "/"
            result @?= True
        , testCase "returns False when scripted" do
            result <- runScripted [NextFileCheck False] $ socketFileExists "/"
            result @?= False
        ]
    , testGroup
        "removeSocketFile"
        [ testCase "is always a no-op" do
            -- No NextFileCheck/NextAccept needed; just returns ()
            runScripted [] $ removeSocketFile "/nonexistent/path"
        ]
    , testGroup
        "acceptHandle"
        [ testCase "returns the scripted handle, readable from a file" do
            let tmpPath = "/tmp/tricorder-socket-accept-test.txt"
            writeFile tmpPath "hello from test\n"
            h <- liftIO $ openFile tmpPath ReadMode
            line <- runScripted [NextAccept h] $ do
                sock <- bindSocket "/"
                h' <- acceptHandle sock
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
            removeSocketFile path
            _ <- bindSocket path
            isDaemonReady path
        runIO' $ removeSocketFile path
        result @?= True
    ]


--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- | Run scripted socket operations (no Delay needed).
runScripted :: [SocketScript] -> Eff '[UnixSocket, File, IOE] a -> IO a
runScripted script = runEff . runFile . runUnixSocketScripted script


-- | Run socket operations against the real IO interpreter.
runIO' :: Eff '[UnixSocket, File, IOE] a -> IO a
runIO' = runEff . runFile . runUnixSocketIO
