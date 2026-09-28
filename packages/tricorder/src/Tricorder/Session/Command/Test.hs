module Tricorder.Session.Command.Test
    ( renderTest
    , resolveTestCommand
    , defaultTestTemplate
    )
where

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.CommandTemplate (CommandTemplate (..), renderText, targetPlaceholder)
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.TestTarget (TestTarget (..))

import Tricorder.Build.ByteSize qualified as ByteSize


renderTest :: CommandTemplate 'Test -> Maybe ByteSize -> TestTarget -> ResolvedCommand 'Test
renderTest commandTemplate mMemoryLimit target =
    ResolvedCommand
        $ renderText
            commandTemplate {arguments = commandTemplate.arguments <> memoryLimitArg}
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
                    case commandTemplate.repl of
                        Stack -> stack
                        StackMulti -> stack
                        Cabal -> cabal
                        Unknown -> cabal
            )
            mMemoryLimit


resolveTestCommand :: Repl -> Config -> CommandTemplate 'Test
resolveTestCommand repl cfg =
    CommandTemplate
        { repl
        , template = fromMaybe (defaultTestTemplate repl) cfg.test.commandTemplate
        , arguments = maybe cfg.test.extraAutoArguments (const []) cfg.test.commandTemplate
        , placeholder = targetPlaceholder
        }


defaultTestTemplate :: Repl -> Text
defaultTestTemplate = \case
    Stack -> "stack ghci {target}"
    StackMulti -> "stack ghci {target}"
    Cabal -> "cabal repl {target}"
    Unknown -> "cabal repl {target}"
