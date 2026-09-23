module Tricorder.Session.Command
    ( CommandTemplate (..)
    , renderText
    , renderTargetsFor
    , hasPlaceholder
    , targetsPlaceholder
    , targetPlaceholder
    )
where

import Data.Default (Default (..))

import Data.List qualified as List
import Data.Text qualified as T

import Tricorder.Session.Repl (Repl (..))
import Tricorder.Session.Stage (Stage (..))
import Tricorder.Session.Target (Target (..))

import Tricorder.Session.Target qualified as Target


-- | A command string to be rendered with a provided list of targets.
data CommandTemplate (stage :: Stage) = CommandTemplate
    { repl :: Repl
    , template :: Text
    , arguments :: [Text]
    , placeholder :: Text
    -- ^ The bare placeholder name (without braces) that 'template' may
    -- contain: 'targetsPlaceholder' for build (one invocation covers every
    -- target, hence the plural), 'targetPlaceholder' for test and eval (one
    -- invocation per target).
    }
    deriving stock (Eq, Generic, Show)


-- | The @{targets}@ placeholder name, used by @build@: an invocation covers
-- every configured/auto-detected target at once.
targetsPlaceholder :: Text
targetsPlaceholder = "targets"


-- | The @{target}@ placeholder name, used by @test@ and @eval@: each
-- invocation runs against exactly one target (a test suite, or a module
-- being evaluated).
targetPlaceholder :: Text
targetPlaceholder = "target"


instance Default (CommandTemplate 'Build) where
    def = CommandTemplate Unknown "{targets}" [] targetsPlaceholder


instance Default (CommandTemplate 'Test) where
    def = CommandTemplate Unknown "{target}" [] targetPlaceholder


instance Default (CommandTemplate 'Eval) where
    def = CommandTemplate Unknown "{target}" [] targetPlaceholder


-- | Render a 'CommandTemplate' against a target list, producing the literal
-- shell command Tricorder spawns: substitute 'placeholder' in 'template'
-- with the REPL-kind-rendered target(s), then append 'arguments'. The
-- 'CommandTemplate' carries no target information of its own — every call
-- site supplies the target(s) it wants rendered.
--
-- Shared by 'renderBuild', 'renderTest', and 'renderEval' — not exported,
-- since each phase renders differently (a plain wrap for build/eval, an
-- extra memory-limit flag for test) and the phase-tagged
-- 'Tricorder.Session.Command.ResolvedCommand.ResolvedCommand' result is what
-- the rest of the daemon should be threading around, not bare 'Text'.
renderText :: CommandTemplate stage -> [Target] -> Text
renderText commandTemplate targets =
    T.unwords
        $ T.words
            ( substitutePlaceholder
                commandTemplate.placeholder
                (renderTargetsFor commandTemplate.repl targets)
                commandTemplate.template
            )
            <> commandTemplate.arguments


-- | Render a target list the way each REPL kind expects it on the command
-- line. Plain (single-package) @stack ghci@ only understands bare component
-- names, and de-duplicates because multiple targets can share a component
-- name across differently-qualified forms; every other kind takes the fully
-- qualified @[package:]kind:name@ form cabal understands.
renderTargetsFor :: Repl -> [Target] -> [Text]
renderTargetsFor = \case
    Stack -> List.nub . fmap Target.componentName
    StackMulti -> List.nub . fmap Target.renderTarget
    Cabal -> fmap Target.renderTarget
    Unknown -> fmap Target.renderTarget


-- | Substitute every unescaped @{<placeholderName>}@ occurrence in a
-- template with the (already REPL-rendered) target list, space-joined.
-- @\\{<placeholderName>}@ is a literal escape: it renders as
-- @{<placeholderName>}@ verbatim, with no substitution. Only the leading
-- brace needs escaping.
--
-- Implemented as swap-substitute-swap-back so the escaped form is never
-- itself matched by the unescaped-placeholder substitution.
substitutePlaceholder :: Text -> [Text] -> Text -> Text
substitutePlaceholder placeholderName renderedTargets =
    T.replace escapeSentinel bareholder
        . T.replace bareholder (T.unwords renderedTargets)
        . T.replace ("\\" <> bareholder) escapeSentinel
  where
    bareholder = "{" <> placeholderName <> "}"
    -- Must not itself contain the literal substring "{<placeholderName>}" —
    -- the unescaped-placeholder pass above would otherwise match inside it.
    escapeSentinel = "\NUL__escaped_" <> placeholderName <> "_placeholder__\NUL"


-- | Whether a template contains an unescaped @{<placeholderName>}@ or an
-- escaped @\\{<placeholderName>}@ placeholder at all. Used to warn when
-- @test.command_template@ has neither (see 'Tricorder.Session.loadSession').
hasPlaceholder :: Text -> Text -> Bool
hasPlaceholder placeholderName template = ("{" <> placeholderName <> "}") `T.isInfixOf` template
