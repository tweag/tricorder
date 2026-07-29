module Unit.Tricorder.Effects.SessionStoreSpec (spec_SessionStore) where

import Atelier.Effects.Chan (Chan, runChan)
import Atelier.Effects.Clock (Clock, runClockConst)
import Atelier.Effects.Conc (Conc, runConc)
import Atelier.Effects.Monitoring.Tracing (Tracing, runTracingNoOp)
import Atelier.Effects.Publishing (runPubSub)
import Atelier.Effects.Publishing.Pub (Pub)
import Atelier.Effects.Publishing.Sub (Sub)
import Control.Concurrent (threadDelay)
import Data.Default (def)
import Data.IORef (IORef)
import Data.Time (UTCTime (..), fromGregorian)
import Effectful (IOE, runEff)
import Effectful.Concurrent (Concurrent, runConcurrent)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Error.Static (Error, runErrorNoCallStack, throwError)
import Test.Hspec (Spec, describe, it, shouldBe)

import Atelier.Effects.Publishing.Pub qualified as Pub
import Data.IORef qualified as IORef

import Tricorder.Effects.SessionStore
    ( ActiveSession (..)
    , SessionStore (..)
    , SessionStoreReloaded (..)
    , runSessionStoreConst
    , withSession
    )
import Tricorder.Session (Command (..), Session (..))

import Tricorder.Effects.SessionStore qualified as SessionStore


spec_SessionStore :: Spec
spec_SessionStore = do
    describe "withSession" testWithSession


testWithSession :: Spec
testWithSession = do
    it "calls the action with the current session" do
        cmdRef <- IORef.newIORef Nothing
        _ <- runFixed session1 do
            withSession \active -> do
                liftIO $ IORef.writeIORef cmdRef (Just active.session.command)
                throwError StopSignal
        result <- IORef.readIORef cmdRef
        result `shouldBe` Just session1.command

    it "provides a reloader that calls rawReload" do
        reloadedRef <- IORef.newIORef False
        _ <- runFlagged reloadedRef do
            withSession \active -> do
                active.reloader.reload
                throwError StopSignal
        reloaded <- IORef.readIORef reloadedRef
        reloaded `shouldBe` True

    it "restarts with the new session when reloaded" do
        sessionsRef <- IORef.newIORef []
        sessionRef <- IORef.newIORef session1
        callCount <- IORef.newIORef (0 :: Int)
        _ <- runMutable sessionRef do
            withSession \active -> do
                liftIO $ IORef.modifyIORef' sessionsRef (active.session.command :)
                n <- liftIO $ IORef.atomicModifyIORef' callCount (\x -> (x + 1, x + 1))
                if n == 1 then do
                    -- Give withSession time to call listenOnce_ before we publish.
                    liftIO $ threadDelay 1_000
                    liftIO $ IORef.writeIORef sessionRef session2
                    Pub.publish (SessionStoreReloaded session2)
                else
                    throwError StopSignal
        sessions <- reverse <$> IORef.readIORef sessionsRef
        sessions `shouldBe` [session1.command, session2.command]


--------------------------------------------------------------------------------
-- Effect stack
--------------------------------------------------------------------------------

data StopSignal = StopSignal
    deriving stock (Show)


type TestEs =
    '[ Conc
     , Error StopSignal
     , Pub SessionStoreReloaded
     , Sub SessionStoreReloaded
     , SessionStore
     , Chan
     , Clock
     , Tracing
     , Concurrent
     , IOE
     ]


runFixed :: Session -> Eff TestEs a -> IO (Either StopSignal a)
runFixed session =
    runEff
        . runConcurrent
        . runTracingNoOp
        . runClockConst epoch
        . runChan
        . runSessionStoreConst session
        . runPubSub @SessionStoreReloaded
        . runErrorNoCallStack @StopSignal
        . runConc


runFlagged :: IORef Bool -> Eff TestEs a -> IO (Either StopSignal a)
runFlagged flag =
    runEff
        . runConcurrent
        . runTracingNoOp
        . runClockConst epoch
        . runChan
        . runSessionStoreFlagged flag
        . runPubSub @SessionStoreReloaded
        . runErrorNoCallStack @StopSignal
        . runConc


runMutable :: IORef Session -> Eff TestEs a -> IO (Either StopSignal a)
runMutable ref =
    runEff
        . runConcurrent
        . runTracingNoOp
        . runClockConst epoch
        . runChan
        . runSessionStoreMutable ref
        . runPubSub @SessionStoreReloaded
        . runErrorNoCallStack @StopSignal
        . runConc


runSessionStoreFlagged :: (IOE :> es) => IORef Bool -> Eff (SessionStore : es) a -> Eff es a
runSessionStoreFlagged flag = interpret_ \case
    Get -> pure session1
    RawReload -> liftIO $ IORef.writeIORef flag True


runSessionStoreMutable :: (IOE :> es) => IORef Session -> Eff (SessionStore : es) a -> Eff es a
runSessionStoreMutable ref = interpret_ \case
    Get -> liftIO $ IORef.readIORef ref
    RawReload -> pure ()


--------------------------------------------------------------------------------
-- Fixtures
--------------------------------------------------------------------------------

session1 :: Session
session1 = def {command = Command "session-1"}


session2 :: Session
session2 = def {command = Command "session-2"}


epoch :: UTCTime
epoch = UTCTime (fromGregorian 1970 1 1) 0
