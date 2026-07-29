module Atelier.Effects.Publishing.Pub
    ( Pub (..)
    , publish
    , toWriter
    ) where

import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret_)
import Effectful.TH (makeEffect)
import Effectful.Writer.Static.Shared (Writer, tell)
import Prelude hiding (map)


-- | Effect for publishing events of type @event@.
data Pub (event :: Type) :: Effect where
    -- | Publish an event to all current subscribers.
    Publish :: event -> Pub event m ()


makeEffect ''Pub


-- | Handler that uses a provided Writer effect instead of actually publishing.
-- Useful for testing and inspecting what events were published.
toWriter :: forall event es a. (Writer [event] :> es) => Eff (Pub event : es) a -> Eff es a
toWriter =
    interpret_ \case
        Publish event -> tell [event]
