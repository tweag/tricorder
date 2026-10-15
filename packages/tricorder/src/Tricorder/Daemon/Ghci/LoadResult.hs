module Tricorder.Daemon.Ghci.LoadResult
    ( LoadResult (..)
    , resolveKnownTargets
    )
where

import Data.Map.Strict qualified as Map
import Data.Set qualified as Set

import Tricorder.Build (Diagnostic)
import Tricorder.Daemon.Ghci.LoadedModule (LoadedModule (..))


-- | The result of a GHCi load or reload operation.
data LoadResult = LoadResult
    { moduleCount :: Int
    , compiledFiles :: Set FilePath
    -- ^ Files compiled in this cycle (derived from 'GLoading' items).
    -- Used by the session layer to decide which files' previous diagnostics to replace vs. retain.
    , loadedModules :: Map FilePath LoadedModule
    -- ^ Map from canonical absolute path to module metadata, derived from @:show modules@ output.
    -- Lists only modules that compiled successfully this cycle — GHCi drops
    -- failed-compile modules from @:show modules@.
    , targetNames :: [Text]
    -- ^ Raw entries from @:show targets@ — typically dotted module names
    -- in @cabal repl --enable-multi-repl@. Unlike 'loadedModules' this
    -- survives failed compiles, so the Builder feeds it into
    -- @KnownTargetNames@ for the dispatcher's fallback lookup.
    , diagnostics :: [Diagnostic]
    }
    deriving stock (Eq, Show)


-- | Path↔module-name map for the next cycle: this round's @:show modules@
-- plus carryover from @prev@ for targets that failed mid-session and so
-- dropped out. Never-compiled targets are absent here (no path↔name
-- mapping); the dispatcher recognises those via 'KnownTargetNames'.
resolveKnownTargets
    :: Map FilePath LoadedModule
    -- ^ Previous known-targets map (carryover source).
    -> LoadResult
    -> Map FilePath LoadedModule
resolveKnownTargets prev lr =
    let primary = lr.loadedModules
        primaryNames = Set.fromList [lm.moduleName | lm <- Map.elems primary]
        prevByName = Map.fromList [(lm.moduleName, (path, lm)) | (path, lm) <- Map.toList prev]
        carryover =
            Map.fromList
                [ (path, lm)
                | name <- lr.targetNames
                , not (Set.member name primaryNames)
                , Just (path, lm) <- [Map.lookup name prevByName]
                ]
    in  Map.union primary carryover
