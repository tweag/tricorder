module Tricorder.Daemon.Ghci.Severity
    ( Severity (..)
    , parse
    )
where

import Data.Text qualified as T


-- | Severity of a GHCi diagnostic message.
data Severity = Warning | Error
    deriving stock (Eq, Ord, Show)


-- | Determine severity from the text after the position (lowercased, stripped).
parse :: Text -> Maybe Severity
parse lower
    | "warning:" `T.isPrefixOf` lower = Just Warning
    | "error:" `T.isPrefixOf` lower = Just Error
    | otherwise = Nothing
