module Tricorder.Session.Stage.Test.Command
    ( ResolvedTestCommand
    , render
    )
where

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText)
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Stage.Test.Session (TestSession (..))
import Tricorder.Session.TestTarget (TestTarget (..))

import Tricorder.Build.ByteSize qualified as ByteSize


type ResolvedTestCommand = ResolvedCommand 'Test


render :: TestSession -> Maybe ByteSize -> TestTarget -> ResolvedTestCommand
render testSession mMemoryLimit target =
    ResolvedCommand
        $ renderText
            testSession.commandTemplate {arguments = testSession.commandTemplate.arguments <> memoryLimitArg}
            [getTestTarget target]
  where
    memoryLimitArg =
        maybe
            []
            ( \limit ->
                let
                    stack =
                        [ "--ghc-options"
                        , "+RTS -M"
                            <> ByteSize.toRTSSize limit
                            <> " -RTS"
                        ]
                    cabal =
                        [ "--repl-options"
                        , "+RTS -M"
                            <> ByteSize.toRTSSize limit
                            <> " -RTS"
                        ]
                in
                    case testSession.commandTemplate.repl of
                        Stack -> stack
                        StackMulti -> stack
                        Cabal -> cabal
                        Unknown -> cabal
            )
            mMemoryLimit
