-- | The core observe 'Plan' ("Atelier.Observe.Core"). 'concForkLinks' is exercised end-to-end with
-- /real/ 'Conc' forks under the concurrent discharge 'observeConc': a parent region forks a child,
-- and the child's region must (a) be collected at all — forked moments survive the discharge — and
-- (b) be rerooted to a fresh trace linked back to the exact fork-site region.
module Unit.Atelier.Observe.CoreSpec (spec_ObserveCore) where

import Atelier.Observe
    ( Consumer
    , Link (..)
    , Moment (..)
    , MomentCtx (MomentCtx)
    , Tap
    , eachMoment
    , observeConc
    , tap
    , watch
    )
import Data.IORef (modifyIORef', newIORef, readIORef)
import Effectful (Dispatch (Dynamic), DispatchOf, Effect, IOE, runEff)
import Effectful.Concurrent (runConcurrent)
import Effectful.Dispatch.Dynamic (interpret, send)
import Test.Hspec (Spec, describe, it, shouldContain)

import Atelier.Effects.Conc (Conc, await, fork, runConc)
import Atelier.Observe.Core (concForkLinks)


-- A parent operation whose interpreter forks a child doing 'Work', then awaits it.
data Parent :: Effect where
    Parent :: Parent m ()


type instance DispatchOf Parent = Dynamic


-- The forked child's leaf operation.
data Work :: Effect where
    Work :: Work m ()


type instance DispatchOf Work = Dynamic


runWork :: Eff (Work : es) a -> Eff es a
runWork = interpret \_ -> \case
    Work -> pure ()


runParent :: (Conc :> es, Work :> es) => Eff (Parent : es) a -> Eff es a
runParent = interpret \_ -> \case
    Parent -> do
        t <- fork (send Work)
        void (await t)


parentTap :: Tap Parent () Text ()
parentTap = watch (const "parent")


workTap :: Tap Work () Text ()
workTap = watch (const "work")


spec_ObserveCore :: Spec
spec_ObserveCore = describe "Atelier.Observe.Core.concForkLinks" do
    it "collects a forked child's region and reroots it, linked to the fork-site region" do
        seen <- newIORef []
        let plan = tap parentTap <> concForkLinks <> tap workTap
            sink :: (IOE :> es) => Consumer es () Text () () ()
            sink = eachMoment \case
                Entered (MomentCtx _ p _ _ _ _) links _ -> liftIO (modifyIORef' seen ((p, links) :))
                _ -> pure ()
        (_, ()) <-
            runEff . runConcurrent . runConc . runWork . runParent
                $ observeConc sink plan (send Parent)
        recorded <- readIORef seen
        -- the parent region opened as an ordinary (linkless) region…
        recorded `shouldContain` [(["parent"], [] :: [Link () Text])]
        -- …and the forked child's region was collected at all (observe would have lost it), rerooted
        -- to a fresh top-level path, carrying a region-granular link back to the parent's region
        recorded `shouldContain` [(["work"], [LinkRegion Nothing ["parent"]])]
