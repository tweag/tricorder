-- | A narrow effect for the non-interactive @cabal@ subcommands tricorder
-- needs. The interpreter is the /sole/ spawner of the @cabal@ executable, and
-- it only ever runs the specific, pre-validated commands modelled here —
-- callers can neither pass arbitrary arguments nor choose the working
-- directory (fetches are pinned to the project root). Interactive
-- @cabal repl@ sessions are a separate concern, handled by
-- "Tricorder.Effects.GhciSession.GhciProcess".
module Tricorder.Effects.Cabal
    ( -- * Effect
      Cabal
    , FetchResult (..)
    , fetchSource
    , cabalVersion

      -- * Interpreters
    , runCabalIO
    , runCabalFetchWith
    , runCabalScripted
    , CabalScript (..)
    ) where

import Atelier.Effects.Log (Log)
import Atelier.Effects.Process (Process, proc, readProcess, readProcessSafe, setWorkingDir)
import Effectful (Effect)
import Effectful.Dispatch.Dynamic (interpret, reinterpret)
import Effectful.Exception (trySync)
import Effectful.Reader.Static (Reader, ask)
import Effectful.State.Static.Shared (evalState, get, put)
import Effectful.TH (makeEffect)
import System.Exit (ExitCode (..))

import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T

import Tricorder.GhcPkg.Types (PackageId (..))
import Tricorder.Runtime (ProjectRoot (..))


-- | Whether an on-demand fetch exited cleanly. A clean exit that still leaves
-- no tarball is a /deterministic/ absence (safe to cache); a failed fetch is
-- /transient/ (must not be cached).
data FetchResult = Fetched | FetchFailed
    deriving stock (Eq, Show)


-- | The non-interactive @cabal@ subcommands tricorder drives. Each runs the
-- user's /own/ @cabal@ executable inside their project — tricorder deliberately
-- does not bring the @Cabal@ library along as a Haskell dependency, so
-- behaviour always matches the user's toolchain and project configuration.
data Cabal :: Effect where
    -- | @cabal fetch --no-dependencies \<pkgId\>@, run in the project root so it
    -- honours the project's configured repositories (CHaP, constraints).
    -- Reports only whether the fetch exited cleanly, so a transient failure
    -- (offline, stale index, yanked) stays distinguishable from a genuine
    -- absence and is not cached.
    FetchSource :: PackageId -> Cabal m FetchResult
    -- | @cabal --version@, trimmed to its first line. 'Nothing' if @cabal@ is
    -- absent or errors — a capability probe callers can branch on.
    CabalVersion :: Cabal m (Maybe Text)


makeEffect ''Cabal


-- | Production interpreter. The only code path that spawns @cabal@.
runCabalIO
    :: (Log :> es, Process :> es, Reader ProjectRoot :> es)
    => Eff (Cabal : es) a
    -> Eff es a
runCabalIO = interpret \_ -> \case
    FetchSource pkgId -> do
        ProjectRoot projectRoot <- ask
        Log.info $ "Source: cabal fetch " <> unPackageId pkgId
        let cfg =
                setWorkingDir projectRoot
                    $ proc "cabal" ["fetch", "--no-dependencies", toString (unPackageId pkgId)]
        result <- trySync (readProcess cfg)
        case result of
            Right (ExitSuccess, _, _) -> pure Fetched
            Right (ExitFailure _, out, err) -> do
                let details = T.strip (decodeUtf8 (err <> out))
                    suffix = if T.null details then "" else ": " <> details
                Log.warn $ "Source: cabal fetch failed for " <> unPackageId pkgId <> suffix
                pure FetchFailed
            Left e -> do
                Log.warn $ "Source: cabal fetch failed for " <> unPackageId pkgId <> ": " <> show e
                pure FetchFailed
    CabalVersion -> do
        out <- readProcessSafe "cabal" ["--version"]
        pure $ T.strip . fst . T.breakOn "\n" <$> out


-- | Test interpreter: every 'fetchSource' yields the result of @onFetch@, which
-- runs in the remaining effects so it can model the fetch's observable side
-- effect — e.g. populating a fake filesystem to mimic a warmed cache.
-- 'cabalVersion' is unsupported. Use this when the unit under test drives
-- @cabal@ solely through 'fetchSource'.
runCabalFetchWith :: Eff es FetchResult -> Eff (Cabal : es) a -> Eff es a
runCabalFetchWith onFetch = interpret \_ -> \case
    FetchSource _ -> onFetch
    CabalVersion -> error "runCabalFetchWith: cabalVersion is not supported"


-- | Script element for the pure test interpreter.
data CabalScript
    = -- | Return this value for the next 'fetchSource' call.
      NextFetch FetchResult
    | -- | Return this value for the next 'cabalVersion' call.
      NextVersion (Maybe Text)


-- | Scripted interpreter for testing. Does not require 'IOE'.
runCabalScripted :: [CabalScript] -> Eff (Cabal : es) a -> Eff es a
runCabalScripted script = reinterpret (evalState script) \_ -> \case
    FetchSource _ ->
        get >>= \case
            NextFetch r : rest -> put rest >> pure r
            _ -> error "CabalScripted: expected NextFetch but queue was empty or mismatched"
    CabalVersion ->
        get >>= \case
            NextVersion r : rest -> put rest >> pure r
            _ -> error "CabalScripted: expected NextVersion but queue was empty or mismatched"
