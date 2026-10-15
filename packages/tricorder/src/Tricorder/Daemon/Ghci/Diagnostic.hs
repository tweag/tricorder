module Tricorder.Daemon.Ghci.Diagnostic
    ( unattributedFailure
    , headerParser
    )
where

import Data.Char (isAlpha)
import Text.Megaparsec (getInput, takeWhile1P)
import Text.Megaparsec.Char (char)
import Prelude hiding (many)

import Data.Text qualified as T

import Tricorder.Build (Diagnostic (..), Severity (..))
import Tricorder.Daemon.Ghci.Position (Position)
import Tricorder.Daemon.Ghci.TextParser (TextParser)

import Tricorder.Daemon.Ghci.Position qualified as Position


-- | Synthetic diagnostic for a failed load with no located error. Without a
-- source span it cannot point anywhere, but it stops the build reading as
-- clean and tells the user where to look.
unattributedFailure :: Diagnostic
unattributedFailure =
    Diagnostic
        { severity = SError
        , file = "<no location info>"
        , line = 0
        , col = 0
        , endLine = 0
        , endCol = 0
        , title = "GHCi reported a failed load with no located error"
        , text =
            "GHCi reported a failed load with no located error.\nRun `tricorder log` to see the full GHCi output.\n"
        }


-- | Parse the full diagnostic header:
--   @file:pos:@ or @drive:path:pos:@ for Windows.
-- Returns @(file, startPos, endPos, textAfterColon)@.
headerParser :: TextParser (Text, Position, Position, Text)
headerParser = do
    a <- takeWhile1P Nothing (/= ':')
    _ <- char ':'
    filePart <-
        if T.length a == 1 && isAlpha (T.head a)
            then do
                pathRest <- takeWhile1P Nothing (/= ':')
                _ <- char ':'
                pure (a <> ":" <> pathRest)
            else
                pure a
    (sp, ep) <- Position.parser
    afterPos <- getInput
    pure (filePart, sp, ep, afterPos)
