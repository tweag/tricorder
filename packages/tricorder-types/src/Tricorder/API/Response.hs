module Tricorder.API.Response
    ( Response (..)
    , MessageWithLoc (..)
    , codec
    )
where

import Autodocodec
    ( Autodocodec (..)
    , ValueCodec
    , dimapCodec
    , disjointEitherCodec
    , object
    , requiredField
    , requiredFieldWith
    , (.=)
    )
import Data.Aeson (FromJSON, ToJSON)

import Autodocodec qualified


-- | The envelope around the JSON output of commands: the payload on success,
-- or why there is none.
data Response a
    = Error MessageWithLoc
    | Pending MessageWithLoc
    | Success a
    deriving stock (Eq, Functor, Generic, Show)


instance Applicative Response where
    pure = Success
    Error message <*> _ = Error message
    _ <*> Error message = Error message
    Pending message <*> _ = Pending message
    _ <*> Pending message = Pending message
    Success f <*> Success a = Success $ f a


instance Monad Response where
    Error message >>= _ = Error message
    Pending message >>= _ = Pending message
    Success a >>= f = f a


-- | Exactly one of @success@, @pending@ or @error@, given the codec of the
-- payload.
codec :: ValueCodec input output -> ValueCodec (Response input) (Response output)
codec payload =
    dimapCodec fromEither toEither
        $ disjointEitherCodec
            (object "Error" $ requiredField "error" "The build or tests failed, or the request was invalid.")
        $ disjointEitherCodec
            (object "Pending" $ requiredField "pending" "The build or tests are still running.")
            (object "Success" $ requiredFieldWith "success" payload "The result.")
  where
    fromEither = \case
        Left message -> Error message
        Right (Left message) -> Pending message
        Right (Right a) -> Success a
    toEither = \case
        Error message -> Left message
        Pending message -> Right $ Left message
        Success a -> Right $ Right a


data MessageWithLoc = MessageWithLoc
    { location :: Text
    , message :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via Autodocodec MessageWithLoc


instance Autodocodec.HasCodec MessageWithLoc where
    codec =
        object "MessageWithLoc"
            $ MessageWithLoc
                <$> requiredField
                    "location"
                    "Where the message comes from, e.g. `build`, `postBuild`, `finished` or `arguments`."
                    .= (.location)
                <*> requiredField "message" "A human-readable description." .= (.message)
