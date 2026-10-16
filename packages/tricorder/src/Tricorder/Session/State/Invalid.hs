module Tricorder.Session.State.Invalid (Invalid (..)) where

import Tricorder.Session (Session)


data Invalid = Invalid
    { reason :: Text
    , fallback :: Session
    }
    deriving stock (Eq)
