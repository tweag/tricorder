module Tricorder.CLI.Docs (renderReference) where

import Options.Applicative
    ( ParserInfo (..)
    , ParserResult (..)
    , columns
    , execParserPure
    , prefs
    , renderFailure
    )
import Options.Applicative.Common (mapParser)
import Options.Applicative.Types (OptReader (..), Option (..))

import Data.Text qualified as Text

import Tricorder.CLI.Arguments (opts)


-- | Markdown reference: one section per command (depth-first), each containing
-- the verbatim @--help@ output.
renderReference :: Text
renderReference =
    Text.intercalate "\n" $ section <$> commandPaths


section :: ([String], String) -> Text
section (path, help) =
    Text.unlines
        [ "### `" <> Text.unwords (map toText ("tricorder" : path)) <> " --help`"
        , ""
        , "```"
        , Text.stripEnd (toText help)
        , "```"
        ]


-- | A parser info with its result type hidden; subcommands have their own.
data SomeInfo = forall x. SomeInfo (ParserInfo x)


-- | All command paths (the root is @[]@), paired with their rendered help.
commandPaths :: [([String], String)]
commandPaths = go [] (SomeInfo opts)
  where
    go path (SomeInfo info) =
        (path, helpFor path)
            : concatMap
                (\(name, child) -> go (path <> [name]) child)
                (subcommands info)


subcommands :: ParserInfo a -> [(String, SomeInfo)]
subcommands info = concat $ mapParser (const cmds) info.infoParser
  where
    cmds :: Option x -> [(String, SomeInfo)]
    cmds opt = case opt.optMain of
        CmdReader _ cs -> [(name, SomeInfo child) | (name, child) <- reverse cs]
        _ -> []


helpFor :: [String] -> String
helpFor path =
    case execParserPure (prefs (columns 80)) opts (path <> ["--help"]) of
        Failure failure -> fst $ renderFailure failure "tricorder"
        _ -> ""
