module Tricorder.Session.Stage.Test.Command
    ( RenderedTestCommand (..)
    , render
    )
where

import Tricorder.Session.Command.RenderedCommand (RenderedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Stage.Test.Session (ResolvedTestOptions (..), Session (..))
import Tricorder.Session.TestTarget (TestTarget (..))

import Tricorder.Build.ByteSize qualified as ByteSize
import Tricorder.Session.CommandTemplate qualified as CommandTemplate


data RenderedTestCommand = RenderedTestCommand
    { command :: RenderedCommand 'Test
    , options :: ResolvedTestOptions
    }


render :: Session -> TestTarget -> RenderedTestCommand
render testSession target =
    RenderedTestCommand
        { command =
            RenderedCommand
                $ CommandTemplate.renderText
                    testSession.commandTemplate {arguments = testSession.commandTemplate.arguments <> memoryLimitArg}
                    [getTestTarget target]
        , options = testSession.options
        }
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
            testSession.options.memoryLimit
