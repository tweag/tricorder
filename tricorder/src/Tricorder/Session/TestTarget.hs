module Tricorder.Session.TestTarget
    ( TestTarget (..)
    , renderTestTarget
    , parseTestTargets
    , resolveTestTargets
    , projectTestTargets
    ) where

import Data.Aeson (FromJSON (..), FromJSONKey, ToJSON (..), ToJSONKey)

import Tricorder.Session.Config (Config (..))
import Tricorder.Session.Target (ComponentKind (..), Target (..), parseTarget, renderTarget)


newtype TestTarget = TestTarget {getTestTarget :: Target}
    deriving stock (Eq, Generic, Ord, Show)
    deriving (FromJSON, ToJSON) via Target
    deriving (FromJSONKey, ToJSONKey) via Target


renderTestTarget :: TestTarget -> Text
renderTestTarget = renderTarget . getTestTarget


-- | Parse raw target strings (e.g. the @test_targets@ config) and project them
-- onto their test suites — non-test entries are dropped.
parseTestTargets :: [Text] -> [TestTarget]
parseTestTargets = projectTestTargets . map parseTarget


-- | [tag:test_targets_invariant] Project a target list onto its test suites —
-- the only way to build a 'TestTargets', so the @test:@-only invariant holds by
-- construction.
projectTestTargets :: [Target] -> [TestTarget]
projectTestTargets = mapMaybe mkTestTarget
  where
    mkTestTarget tgt@(Qualified Test _) = Just $ TestTarget tgt
    mkTestTarget tgt@(PackageQualified _ Test _) = Just $ TestTarget tgt
    mkTestTarget _ = Nothing


-- | Resolve which test suites to run after a clean build. Either source — the
-- explicit @test_targets@ config or the build 'targets' — is projected onto its
-- @test:@ components (see 'projectTestTargets'), so non-test entries are
-- dropped and the result only ever names test suites [ref:test_targets_invariant].
resolveTestTargets :: Config -> [Target] -> [TestTarget]
resolveTestTargets cfg targets = case cfg.testTargets of
    Just explicit -> parseTestTargets explicit
    Nothing -> projectTestTargets targets
