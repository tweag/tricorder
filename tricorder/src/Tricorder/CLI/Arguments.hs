module Tricorder.CLI.Arguments
    ( Command (..)
    , FollowMode (..)
    , LogMode (..)
    , OutputFormat (..)
    , StatusOptions (..)
    , TestOptions (..)
    , EvalCommentsOptions (..)
    , Verbosity (..)
    , WaitMode (..)
    , parseArguments
    , runArguments
    )
where

import Atelier.Effects.Arguments (Arguments, execParser)
import Effectful.Reader.Static (Reader, runReader)
import Options.Applicative
    ( Parser
    , ParserInfo
    , ReadM
    , argument
    , auto
    , command
    , eitherReader
    , flag
    , flag'
    , fullDesc
    , header
    , help
    , helper
    , hsubparser
    , info
    , infoOption
    , long
    , metavar
    , option
    , progDesc
    , short
    )

import Data.Text qualified as T

import Tricorder.Module (ModuleName (..))
import Tricorder.Socket.Protocol (Force (..))
import Tricorder.SourceLookup (SourceQuery (..))

import Tricorder.Version qualified as Version


data WaitMode
    = ShowCurrent
    | WaitForBuild
    deriving stock (Eq)


data OutputFormat
    = TextOutput
    | JsonOutput
    deriving stock (Eq)


data Verbosity
    = Concise
    | Verbose
    deriving stock (Eq)


data FollowMode
    = NoFollow
    | Follow
    deriving stock (Eq)


data LogMode
    = ShowLog FollowMode
    | ShowLogPath


data StatusOptions = StatusOptions
    { wait :: WaitMode
    , format :: OutputFormat
    , verbosity :: Verbosity
    , expand :: Maybe Int
    }


data TestOptions = TestOptions
    { failedOnly :: Bool
    , wait :: WaitMode
    }


data EvalCommentsOptions = EvalCommentsOptions
    { wait :: WaitMode
    , format :: OutputFormat
    }


data Command
    = Start
    | Stop Force
    | Status StatusOptions
    | Test TestOptions
    | UI
    | Log LogMode
    | Source [SourceQuery]
    | Restart Force
    | EvalComments EvalCommentsOptions


runArguments :: (Arguments :> es) => Eff (Reader Command : es) a -> Eff es a
runArguments eff = do
    args <- parseArguments
    runReader args eff


parseArguments :: (Arguments :> es) => Eff es Command
parseArguments = execParser opts


opts :: ParserInfo Command
opts =
    info (commandParser <**> versionOption <**> helper)
        $ fullDesc
            <> progDesc "tricorder — daemon-based GHCi build status"
            <> header "tricorder — robust GHCi daemon with structured querying"


versionOption :: Parser (a -> a)
versionOption = infoOption (toString Version.gitHash) (long "version" <> help "Show version and exit")


commandParser :: Parser Command
commandParser =
    hsubparser
        ( command "start" (info (pure Start) (progDesc "Start the daemon (no-op if already running)"))
            <> command "stop" (info stopParser (progDesc "Stop the daemon"))
            <> command "status" (info statusParser (progDesc "Print build diagnostics (--json for machine-readable output)"))
            <> command "test-results" (info testParser (progDesc "Show output from the latest test run"))
            <> command "ui" (info (pure UI) (progDesc "Auto-refreshing terminal display"))
            <> command "log" (info logParser (progDesc "Show daemon log output"))
            <> command "source" (info sourceParser (progDesc "Print the Haskell source of one or more installed modules"))
            <> command "restart" (info restartParser (progDesc "Restart the daemon"))
            <> command "eval-comments" (info evalCommentsParser (progDesc "Show eval comments from the latest build"))
        )


logParser :: Parser Command
logParser =
    Log <$> (pathFlag <|> followFlag)
  where
    pathFlag =
        flag'
            ShowLogPath
            ( long "print-path"
                <> help "Print the path to the log file instead of its contents"
            )
    followFlag =
        ShowLog
            <$> flag
                NoFollow
                Follow
                ( long "follow"
                    <> short 'f'
                    <> help "Keep streaming new log lines as they are written"
                )


statusParser :: Parser Command
statusParser =
    Status
        <$> ( StatusOptions
                <$> waitParser
                <*> jsonFormatToggleParser
                <*> flag
                    Concise
                    Verbose
                    ( long "verbose"
                        <> short 'v'
                        <> help "Print full GHC message body under each diagnostic"
                    )
                <*> optional
                    ( option
                        auto
                        ( long "expand"
                            <> metavar "N"
                            <> help "Print full GHC message body for diagnostic #N"
                        )
                    )
            )


testParser :: Parser Command
testParser =
    Test
        <$> ( TestOptions
                <$> flag
                    False
                    True
                    ( long "failed"
                        <> help "Only show output from failed test suites"
                    )
                <*> waitParser
            )


sourceParser :: Parser Command
sourceParser =
    Source <$> some (argument queryReader (metavar "MODULE[#FUNCTION]" <> help "Module or Module#function"))


stopParser :: Parser Command
stopParser =
    Stop <$> forceParser "Ignore waiting queries when stopping the daemon"


restartParser :: Parser Command
restartParser =
    Restart <$> forceParser "Ignore watiting queries when restarting the daemon"


forceParser :: String -> Parser Force
forceParser helpText = flag NoForce Force $ long "force" <> help helpText


evalCommentsParser :: Parser Command
evalCommentsParser =
    EvalComments
        <$> ( EvalCommentsOptions
                <$> waitParser
                <*> jsonFormatToggleParser
            )


waitParser :: Parser WaitMode
waitParser =
    flag
        ShowCurrent
        WaitForBuild
        ( long "wait"
            <> help "Block until the current build cycle completes"
        )


jsonFormatToggleParser :: Parser OutputFormat
jsonFormatToggleParser =
    flag
        TextOutput
        JsonOutput
        ( long "json"
            <> help "Output full build state as JSON"
        )


queryReader :: ReadM SourceQuery
queryReader = eitherReader $ \s ->
    let t = toText s
        (m, rest) = T.break (== '#') t
    in  Right
            $ SourceQuery
                { moduleName = ModuleName m
                , function = if T.null rest then Nothing else Just (T.tail rest)
                }
