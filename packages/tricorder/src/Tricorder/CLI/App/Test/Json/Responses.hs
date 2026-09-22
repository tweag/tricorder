module Tricorder.CLI.App.Test.Json.Responses
    ( Response (..)
    , MessageWithLoc (..)
    , SuitesResponse (..)
    )
where

import Atelier.Types.QuietSnake (QuietSnake (..))
import Data.Aeson
    ( FromJSON
    , Options (..)
    , SumEncoding (..)
    , ToJSON (..)
    , defaultOptions
    , genericToEncoding
    , genericToJSON
    , object
    , pairs
    , (.=)
    )
import Text.Casing (quietSnake)

import Tricorder.CLI.FieldMask (Projected)


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


instance (ToJSON a) => ToJSON (Response a) where
    toJSON = genericToJSON responseOptions
    toEncoding = genericToEncoding responseOptions


data MessageWithLoc = MessageWithLoc
    { location :: Text
    , message :: Text
    }
    deriving stock (Eq, Generic, Show)
    deriving (FromJSON, ToJSON) via QuietSnake MessageWithLoc


responseOptions :: Options
responseOptions =
    defaultOptions
        { constructorTagModifier = quietSnake
        , sumEncoding = ObjectWithSingleField
        }


-- | Test suites, cut down to the requested fields.
newtype SuitesResponse = SuitesResponse
    { suites :: [Projected]
    }
    deriving stock (Eq, Show)


-- | Written by hand so 'toEncoding' keeps the field order of the projection.
instance ToJSON SuitesResponse where
    toJSON response = object ["suites" .= response.suites]
    toEncoding response = pairs ("suites" .= response.suites)
