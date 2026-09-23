module Tricorder.Session.CommandTemplate
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
    -- ^ The bare placeholder name (without braces) 'template' may contain —
    -- see 'targetsPlaceholder' and 'targetPlaceholder'.
    }
    deriving stock (Eq, Generic, Show)


-- | The @{targets}@ placeholder, used by @build@: one invocation covers
-- every target.
targetsPlaceholder :: Text
targetsPlaceholder = "targets"


-- | The @{target}@ placeholder, used by @test@ and @eval@: one invocation
-- per target.
targetPlaceholder :: Text
targetPlaceholder = "target"


instance Default (CommandTemplate 'Build) where
    def = CommandTemplate Unknown ("cabal repl {" <> targetsPlaceholder <> "}") [] targetsPlaceholder


instance Default (CommandTemplate 'Test) where
    def = CommandTemplate Unknown ("cabal repl {" <> targetPlaceholder <> "}") [] targetPlaceholder


instance Default (CommandTemplate 'Eval) where
    def = CommandTemplate Unknown ("cabal repl {" <> targetPlaceholder <> "}") [] targetPlaceholder


-- | Substitute 'placeholder' in 'template' with the REPL-rendered target(s),
-- then append 'arguments'. Not exported — each phase renders differently (a
-- memory-limit flag for test), so use 'renderBuild'\/'renderTest'\/'renderEval'
-- instead, which return the phase-tagged
-- 'Tricorder.Session.Command.ResolvedCommand.ResolvedCommand'.
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


-- | Render targets the way each REPL kind expects on the command line.
-- Plain (single-package) @stack ghci@ only understands bare component
-- names, and needs deduplication since multiple targets can share one;
-- every other kind takes the fully qualified @[package:]kind:name@ form.
renderTargetsFor :: Repl -> [Target] -> [Text]
renderTargetsFor = \case
    Stack -> List.nub . fmap Target.componentName
    StackMulti -> List.nub . fmap Target.renderTarget
    Cabal -> fmap Target.renderTarget
    Unknown -> fmap Target.renderTarget


-- | Substitute every unescaped @{<placeholderName>}@ in a template with the
-- (already REPL-rendered) target list, space-joined. @\\{<placeholderName>}@
-- escapes to a literal @{<placeholderName>}@, with no substitution.
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


-- | Whether a template contains @{<placeholderName>}@, escaped or not. Used
-- to warn when a @test@\/@eval@ @command_template@ omits it (see
-- 'Tricorder.Session.loadSession').
hasPlaceholder :: Text -> Text -> Bool
hasPlaceholder placeholderName template = ("{" <> placeholderName <> "}") `T.isInfixOf` template
