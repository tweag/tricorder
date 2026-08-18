module Tricorder.Socket.Protocol
    ( Force (..)
    , Query (..)
    , StatusQuery (..)
    , DiagnosticQuery (..)
    , ErrorResponse (..)
    , ClientMessage (..)
    , Waiters (..)
    )
where

import Data.Aeson (FromJSON, ToJSON)

import Tricorder.SourceLookup (SourceQuery)


data Force = Force | NoForce


data StatusQuery = StatusQuery {awaitDone :: Bool}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype DiagnosticQuery = DiagnosticQuery {index :: Int}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Query
    = Status StatusQuery
    | Watch
    | Source [SourceQuery]
    | DiagnosticAt DiagnosticQuery
    | Quit Waiters
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


data Waiters = WaitForWaiters | IgnoreWaiters
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)


newtype ErrorResponse = ErrorResponse {message :: Text}
    deriving stock (Eq, Generic, Show)
    deriving anyclass (ToJSON)


data ClientMessage = ClientMessage
    { clientVersion :: Text
    , payload :: Query
    }
    deriving stock (Eq, Generic, Show)
    deriving anyclass (FromJSON, ToJSON)
