module Tricorder.Session.Command.Test
    ( renderTest
    , resolveTestCommand
    , defaultTestTemplate
    )
where

import Tricorder.Build.ByteSize (ByteSize)
import Tricorder.Session.Command (CommandTemplate (..), renderText, targetPlaceholder)
import Tricorder.Session.Command.ResolvedCommand (ResolvedCommand (..))
import Tricorder.Session.Config (CommandConfig (..), Config (..))
import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.TestTarget (TestTarget (..))

import Tricorder.Build.ByteSize qualified as ByteSize


-- | Render the @test@ command for a single test target's short-lived
-- process, with any memory-limit RTS flag filled in for this specific run.
-- The memory-limit flag is Tricorder-managed (derived from
-- @test_memory_limit@, not from @test.extra_auto_arguments@) and is appended
-- after the user's configured arguments.
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


-- | Resolve the effective test 'CommandTemplate': REPL kind, template
-- (user's @test.command_template@, else an automatically resolved default),
-- and extra arguments. Carries no target — 'renderTest' is called once per
-- test target, supplying that target (and any memory-limit flag) explicitly.
--
-- @test.extra_auto_arguments@ only applies when @test.command_template@ is unset
-- — see 'Tricorder.Session.Config.CommandConfig'.
--
-- Unlike 'resolveBuildCommand', there is no deprecated top-level fallback:
-- the legacy @command@ key never affected test runs (it only ever configured
-- the build/load invocation), so it isn't consulted here either.
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
