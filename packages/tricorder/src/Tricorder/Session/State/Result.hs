module Tricorder.Session.State.Result
    ( Result (..)
    , fromEither
    , toEither
    , toMaybe
    )
where

import Data.Default (def)

import Tricorder.Session (Session)
import Tricorder.Session.State.Invalid (Invalid)

import Tricorder.Session.State.Invalid qualified as Invalid


data Result
    = Ok Session
    | Invalid Invalid
    deriving stock (Eq)


fromEither :: Either Text Session -> Result
fromEither = \case
    Left reason ->
        Invalid
            Invalid.Invalid
                { reason
                , fallback = def
                }
    Right session -> Ok session


toEither :: Result -> Either Invalid Session
toEither = \case
    Ok a -> Right a
    Invalid b -> Left b


toMaybe :: Result -> Maybe Session
toMaybe = \case
    Ok x -> Just x
    Invalid _ -> Nothing
