module Tricorder.API.Test.SuitesResponse
    ( SuitesResponse (..)
    , codec
    )
where

import Autodocodec (ValueCodec, listCodec, object, requiredFieldWith, (.=))


-- | Test suites, each cut down to the requested fields.
newtype SuitesResponse suite = SuitesResponse
    { suites :: [suite]
    }
    deriving stock (Eq, Show)


codec :: ValueCodec input output -> ValueCodec (SuitesResponse input) (SuitesResponse output)
codec suite =
    object "SuitesResponse"
        $ SuitesResponse
            <$> requiredFieldWith "suites" (listCodec suite) "The requested test suites." .= (.suites)
