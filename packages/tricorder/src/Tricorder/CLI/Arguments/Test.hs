module Tricorder.CLI.Arguments.Test (parser) where

import Options.Applicative
    ( Parser
    , ParserInfo
    , command
    , footer
    , help
    , helpDoc
    , hsubparser
    , info
    , metavar
    , progDesc
    , strArgument
    )
import Tricorder.CLI.Command.Test (Command, SuitesOptions (..))

import Data.Text qualified as T
import Options.Applicative.Help.Pretty qualified as Doc
import Tricorder.CLI.Command.FieldMask qualified as FieldMask
import Tricorder.CLI.Command.Test qualified as Test

import Tricorder.CLI.FieldMask (Schema (..))

import Tricorder.CLI.App.Test.SuiteView qualified as SuiteView
import Tricorder.CLI.Arguments.FieldMask qualified as FieldMask
import Tricorder.CLI.Arguments.IfDaemonIsStopped qualified as IfDaemonIsStopped
import Tricorder.CLI.Arguments.OutputFormat qualified as OutputFormat
import Tricorder.CLI.Arguments.TestFilter qualified as TestFilter
import Tricorder.CLI.Arguments.WaitMode qualified as WaitMode


parser :: ParserInfo Command
parser =
    info commandParser (progDesc "See statuses and information on configured test suites.")


commandParser :: Parser Command
commandParser =
    hsubparser
        $ command
            "suites"
            ( info
                suitesParser
                ( progDesc "Show test suites, their test cases and output."
                    <> footer suitesFooter
                )
            )


suitesParser :: Parser Command
suitesParser =
    fmap Test.Suites
        $ SuitesOptions
            <$> many (strArgument (metavar "TEST-TARGET..." <> help "Test suites to show (default: all)"))
            <*> TestFilter.parser (help "Show only failed test suites, and only their failed test cases")
            <*> FieldMask.parser
                ( helpDoc
                    $ Just
                    $ (<> Doc.line)
                    $ mconcat
                    $ Doc.punctuate
                        (Doc.line <> Doc.line)
                        [ "Fields to return for each test suite."
                        , "Available fields:"
                            <> Doc.line
                            <> Doc.indent 4 (Doc.vsep $ renderSchema SuiteView.schema)
                        , "Select nested fields with parentheses,"
                            <> Doc.line
                            <> "e.g. --fields 'name,cases(description,failure)'."
                            <> Doc.line
                            <> "A field without parentheses shows all of its nested fields."
                        , "Default fields:"
                            <> Doc.line
                            <> Doc.pretty (FieldMask.render SuiteView.defaultFields)
                        ]
                )
            <*> OutputFormat.parser
            <*> WaitMode.parser
            <*> IfDaemonIsStopped.parser
  where
    renderSchema (Schema fields) = renderField <$> fields
    renderField (name, sub) =
        Doc.pretty name
            <> maybe
                Doc.emptyDoc
                ( \nestedSchema ->
                    Doc.enclose
                        "("
                        ")"
                        $ Doc.sep
                        $ Doc.punctuate ","
                        $ renderSchema nestedSchema
                )
                sub


suitesFooter :: String
suitesFooter =
    toString
        $ "Available fields:\n"
            <> renderSchema SuiteView.schema
            <> "\nSelect nested fields with parentheses, e.g. --fields 'name,cases(description,failure)'."
            <> " A field without parentheses shows all of its nested fields."
  where
    renderSchema (Schema fields) = T.intercalate ", " $ renderField <$> fields
    renderField (name, sub) = name <> maybe "" (\nestedSchema -> "(" <> renderSchema nestedSchema <> ")") sub
