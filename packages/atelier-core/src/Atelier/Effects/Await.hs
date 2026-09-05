-- | The consuming half of a 'Yield'\/'Await' coroutine pair.
--
-- An 'Await' computation requests values one at a time, analogous to the
-- @Reader@\/@Input@ effects. Pair it with a 'Yield' producer — for example via
-- 'awaitYield' — to stream values from one computation into another. The effect
-- and its operations live in "Atelier.Effects.Internal.Coroutine" and are
-- re-exported here.
module Atelier.Effects.Await
    ( -- * Effect
      Await

      -- * Operations
    , await
    , takeAwait

      -- * Interpreters
    , eachAwait
    , awaitYield
    )
where

import Atelier.Effects.Internal.Coroutine
    ( Await
    , await
    , awaitYield
    , eachAwait
    , takeAwait
    )

