module Tricorder.API.Test.Args (parser) where

import Autodocodec (HasCodec (..))
import Options.Applicative
    ( Parser
    , ParserInfo
    , command
    , footer
    , help
    , helpDoc
    , hsubparser
    , info
    , infoOption
    , long
    , metavar
    , progDesc
    , strArgument
    )

import Data.Text qualified as T
import Options.Applicative.Help.Pretty qualified as Doc

import Tricorder.API.Test (Command)
import Tricorder.API.Test.SuiteView (SuiteView)

import Tricorder.API.FieldMask qualified as FieldMask
import Tricorder.API.FieldMask.Args qualified as FieldMask.Args
import Tricorder.API.FieldMask.Projection qualified as FieldMask.Projection
import Tricorder.API.FieldMask.Schema qualified as FieldMask (Schema (..))
import Tricorder.API.FieldMask.Schema qualified as FieldMask.Schema
import Tricorder.API.IfBuildIsPending.Args qualified as IfBuildIsPending.Args
import Tricorder.API.IfDaemonIsStopped.Args qualified as IfDaemonIsStopped.Args
import Tricorder.API.JsonSchema qualified as JsonSchema
import Tricorder.API.OutputFormat.Args qualified as OutputFormat.Args
import Tricorder.API.Response qualified as Response
import Tricorder.API.Test qualified as Test
import Tricorder.API.Test.SuiteView.Schema qualified as SuiteView.Schema
import Tricorder.API.Test.SuitesResponse qualified as SuitesResponse
import Tricorder.API.TestFilter.Args qualified as TestFilter.Args


parser :: ParserInfo Command
parser =
    info commandParser (progDesc "See statuses and information on configured test suites.")


commandParser :: Parser Command
commandParser =
    hsubparser
        $ command
            "suites"
            ( info
                (suitesParser <**> helpJson)
                ( progDesc "Show test suites, their test cases and output."
                    <> footer suitesFooter
                )
            )


suitesParser :: Parser Command
suitesParser =
    fmap Test.Suites
        $ Test.SuitesOptions
            <$> many (strArgument (metavar "TEST-TARGET..." <> help "Test suites to show (default: all)"))
            <*> TestFilter.Args.parser (help "Show only failed test suites, and only their failed test cases.")
            <*> FieldMask.Args.parser
                ( helpDoc
                    $ Just
                    $ (<> Doc.line)
                    $ mconcat
                    $ Doc.punctuate
                        (Doc.line <> Doc.line)
                        [ "Comma-separated list of fields to return for each test suite."
                        , "Available fields:"
                            <> Doc.line
                            <> Doc.indent 4 (Doc.vsep $ FieldMask.Schema.render SuiteView.Schema.schema)
                        , "Select nested fields with parentheses,"
                            <> Doc.line
                            <> "e.g. --fields 'name,cases(description,failure)'."
                            <> Doc.line
                            <> "A field without parentheses shows all of its nested fields."
                        , "Default fields:"
                            <> Doc.line
                            <> Doc.pretty (FieldMask.render SuiteView.Schema.defaultFields)
                        ]
                )
            <*> OutputFormat.Args.parser
            <*> IfBuildIsPending.Args.parser
            <*> IfDaemonIsStopped.Args.parser


helpJson :: Parser (a -> a)
helpJson =
    infoOption
        ( toString
            $ JsonSchema.document "tricorder test suites --json"
            $ Response.codec
            $ SuitesResponse.codec
            $ FieldMask.Projection.optionalKeys
            $ codec @SuiteView
        )
        (long "help-json" <> help "Show the JSON Schema of the output of --json and exit.")


suitesFooter :: String
suitesFooter =
    toString
        $ "Available fields:\n"
            <> renderSchema SuiteView.Schema.schema
            <> "\nSelect nested fields with parentheses, e.g. --fields 'name,cases(description,failure)'."
            <> " A field without parentheses shows all of its nested fields."
  where
    renderSchema (FieldMask.Schema fields) = T.intercalate ", " $ renderField <$> fields
    renderField (name, sub) = name <> maybe "" (\nestedSchema -> "(" <> renderSchema nestedSchema <> ")") sub
