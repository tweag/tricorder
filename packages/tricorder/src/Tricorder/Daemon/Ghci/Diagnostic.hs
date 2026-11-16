module Tricorder.Daemon.Ghci.Diagnostic
    ( unattributedFailure
    , headerParser
    )
where

import Data.Char (isAlpha)
import Text.Megaparsec (getInput, takeWhile1P)
import Text.Megaparsec.Char (char)
import Prelude hiding (many)

import Atelier.FileSystem.Path qualified as Path
import Data.Text qualified as T

import Tricorder.Build (Diagnostic (..))
import Tricorder.Build.DiagnosticLocation (DiagnosticLocation (..))
import Tricorder.Daemon.Ghci.Position (Position)
import Tricorder.Daemon.Ghci.TextParser (TextParser)

import Tricorder.Build.Severity qualified as Severity
import Tricorder.Daemon.Ghci.Position qualified as Position


-- | Synthetic diagnostic for a failed load with no located error. Without a
-- source span it cannot point anywhere, but it stops the build reading as
-- clean and tells the user where to look.
unattributedFailure :: Diagnostic
unattributedFailure =
    Diagnostic
        { severity = Severity.Error
        , file = Locationless
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
headerParser :: TextParser (Path.Any, Position, Position, Text)
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
    case Path.fromFilePath @Path.Any $ toString filePart of
        Left _ -> fail $ "not a valid file path: " <> toString filePart
        Right path -> do
            (sp, ep) <- Position.parser
            afterPos <- getInput
            pure (path, sp, ep, afterPos)
