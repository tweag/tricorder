-- | The concurrent streaming discharge 'observeConc'. Its headline over 'observe' is that moments
-- fired in /forked/ threads are collected: 'observe' folds through a 'State' that is cloned per
-- fork, so a child thread's moments update a throwaway copy and vanish, whereas 'observeConc' routes
-- every moment to one drain thread over a 'Chan'. The second property pins exception-safety: a
-- throwing run still drains everything fired before the throw and runs the consumer's @stop@.
module Unit.ObserveConcSpec (spec_ObserveConc) where

import Data.IORef (modifyIORef', newIORef, readIORef)
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, IOE, runEff)
import Effectful.Concurrent (Concurrent, forkIO, runConcurrent)
import Effectful.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Effectful.Dispatch.Dynamic (interpret, send)
import Test.Hspec (Spec, describe, it, shouldBe)

import Control.Exception qualified as E

import Atelier.Observe
    ( Consumer
    , Moment (..)
    , Tap
    , eachMoment
    , foldMoments
    , observeConc
    , tap
    , watch
    )


-- A trivial leaf effect to observe, with a pure interpreter and one that throws on "boom".
data Note :: Effect where
    Note :: Text -> Note m ()


type instance DispatchOf Note = Dynamic


note :: (Note :> es) => Text -> Eff es ()
note t = send (Note t)


runNote :: Eff (Note : es) a -> Eff es a
runNote = interpret \_ -> \case
    Note _ -> pure ()


runNoteThrowing :: (IOE :> es) => Eff (Note : es) a -> Eff es a
runNoteThrowing = interpret \_ -> \case
    Note t -> when (t == "boom") (liftIO (E.throwIO (E.ErrorCall "boom")))


noteTap :: Tap Note i Text e
noteTap = watch (const "note")


momentTag :: Moment i r e s -> String
momentTag = \case
    Entered {} -> "enter"
    Exited {} -> "exit"
    Failed {} -> "fail"
    Measured {} -> "measure"


spec_ObserveConc :: Spec
spec_ObserveConc = describe "Atelier.Observe.observeConc" do
    it "collects moments fired in forked threads (which observe would lose)" do
        -- three children each fire one observed op, synchronised so the program does not return
        -- until all have finished; the parent then fires one more. All four regions must land.
        let countEnters :: Consumer es i r e s (Sum Int)
            countEnters = foldMoments \case
                Entered {} -> Sum 1
                _ -> mempty
            prog :: (Concurrent :> es, Note :> es) => Eff es ()
            prog = do
                dones <- replicateM 3 newEmptyMVar
                for_ dones \d -> void (forkIO (note "child" >> putMVar d ()))
                for_ dones takeMVar
                note "parent"
        (_, total) <-
            runEff . runConcurrent . runNote
                $ observeConc countEnters (tap noteTap) prog
        total `shouldBe` Sum 4

    it "flushes through stop on a throw, draining every moment fired before it" do
        seen <- newIORef []
        let recordTags :: (IOE :> es) => Consumer es i r e s ()
            recordTags = eachMoment \m -> liftIO (modifyIORef' seen (momentTag m :))
            prog = note "ok" >> note "boom"
        _ <-
            E.try (runEff . runConcurrent . runNoteThrowing $ observeConc recordTags (tap noteTap) prog)
                :: IO (Either E.SomeException ((), ()))
        tags <- reverse <$> readIORef seen
        -- the clean "ok" region opened and closed; the throwing "boom" region opened then Failed —
        -- all reached the drain before the re-raise, because observeConc joins it on the way out
        tags `shouldBe` ["enter", "exit", "enter", "fail"]
