module Tricorder.Daemon.Ghci.TextParser
    ( TextParser
    , run
    )
where

import Text.Megaparsec (Parsec, parse)
import Prelude hiding (many)


-- | Parser over a single 'Text' value.
type TextParser = Parsec Void Text


-- | Run a 'TextParser' on a 'Text' value, returning 'Nothing' on failure.
run :: TextParser a -> Text -> Maybe a
run p t = case parse p "" t of
    Right x -> Just x
    Left _ -> Nothing
