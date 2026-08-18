-- | An effect for requesting a value from the environment on each call.
--
-- Unlike 'Effectful.Reader.Static.Reader', 'Input' makes no assumption that the
-- value is stable across the computation — each 'input' may observe a different
-- value. See the 'Input' type below for the full comparison.
module Atelier.Effects.Input
    ( Input
    , input
    , runInputEff
    , runInputConst
    , toReader
    , fromState
    )
where

import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.Reader.Static (Reader, runReader)
import Effectful.State.Static.Shared (State)
import Effectful.TH (makeEffect)

import Effectful.State.Static.Shared qualified as State


-- | Request a value from the effect system.
--
-- This effect does not carry any
-- semantics as to how the value is created, whether it is cached, or whether
-- you get a different value for each call. It is similar to
-- 'Effectful.Reader.Static.Reader' in that it is about requesting a value, but
-- 'Reader' carries the implicit assumption that its value remains static for
-- the duration of the encapsulated computation, while 'Input' carries no such
-- assumption.
--
-- If the value you wish to request from the effect system will remain
-- unchanged for the duration of the computation, use 'Effectful.Reader.Static'
-- or 'Effectful.Reader.Local' instead.
data Input i :: Effect where
    Input :: Input i m i


makeEffect ''Input


-- | Runs the passed effectful action every time 'input' is invoked.
runInputEff :: Eff es i -> Eff (Input i : es) a -> Eff es a
runInputEff mk = interpret_ \Input -> mk


-- | Provides the same value for every invocation of the 'input' operation.
-- This is equivalent to using 'Effectful.Reader.Static' or
-- 'Effectful.Reader.Local', but is available here for testing.
runInputConst :: i -> Eff (Input i : es) a -> Eff es a
runInputConst = runInputEff . pure


-- | Retrieves the value once, and exposes it as a 'Reader' effect.
toReader :: (Input i :> es) => Eff (Reader i : es) a -> Eff es a
toReader act = do
    x <- input
    runReader x act


fromState :: (State i :> es) => Eff (Input i : es) a -> Eff es a
fromState = interpret_ \Input -> State.get
