module Tricorder.Session.TestTarget
    ( TestTarget (..)
    , render
    , parse
    , resolve
    , project
    )
where

import Data.Aeson (FromJSON (..), FromJSONKey, ToJSON (..), ToJSONKey)

import Tricorder.Session.CommandConfig (CommandConfig (..))
import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Stage.Test.Config (TestConfig (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..))

import Tricorder.Session.Target qualified as Target


newtype TestTarget = TestTarget {getTestTarget :: Target}
    deriving stock (Eq, Generic, Ord, Show)
    deriving (FromJSON, ToJSON) via Target
    deriving (FromJSONKey, ToJSONKey) via Target


render :: TestTarget -> Text
render = Target.render . getTestTarget


-- | Parse raw target strings (e.g. the @test_targets@ config) and project them
-- onto their test suites — non-test entries are dropped.
parse :: [Text] -> [TestTarget]
parse = project . map Target.parse


-- | [tag:test_targets_invariant] Project a target list onto its test suites —
-- the only way to build a 'TestTargets', so the @test:@-only invariant holds by
-- construction.
project :: [Target] -> [TestTarget]
project = mapMaybe mk
  where
    mk tgt@(Qualified Test _) = Just $ TestTarget tgt
    mk tgt@(PackageQualified _ Test _) = Just $ TestTarget tgt
    mk _ = Nothing


-- | Resolve which test suites to run after a clean build. The explicit
-- source — @test.targets@, falling back to the deprecated top-level
-- @test_targets@ — is projected onto its @test:@ components (see
-- 'projectTestTargets'), so non-test entries are dropped and the result only
-- ever names test suites [ref:test_targets_invariant]. With neither source
-- set, falls back to deriving test targets from the build 'targets'.
resolve :: Config -> [Target] -> [TestTarget]
resolve cfg targets = case cfg.test.commandConfig.targets <|> cfg.testTargets of
    Just explicit -> parse explicit
    Nothing -> project targets
