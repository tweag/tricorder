-- | The builder's interpretation layer over a raw 'Repl' session: issue the
-- GHCi load commands (@:reload@, @:add@, @:unadd@) and assemble the captured
-- output into a 'LoadResult' via the pure parsers in
-- 'Tricorder.Effects.GhciSession.GhciParser'.
module Tricorder.Effects.GhciSession.Load
    ( collectLoadResult
    , reload
    , add
    , unadd
    ) where

import Atelier.Effects.Conc (Conc)
import Atelier.Effects.File (File)
import Atelier.Effects.Log (Log)
import Effectful.Concurrent (Concurrent)

import Atelier.Effects.Log qualified as Log
import Data.Text qualified as T

import Tricorder.Effects.GhciSession.GhciParser
    ( GhciLoading (..)
    , LoadResult (..)
    , collectResult
    , parseShowModules
    , parseShowTargets
    , unattributedFailure
    )
import Tricorder.Effects.Repl (Repl)

import Tricorder.Effects.Repl qualified as Repl


-- | Parse already-drained GHCi output lines into a 'LoadResult', fetching the
-- current module list via @:show modules@.
--
-- Progress is emitted live by 'Repl.exec' as lines arrive, so no replay
-- callback is needed here — this function only assembles the final result.
collectLoadResult
    :: (Conc :> es, Concurrent :> es, File :> es, Log :> es)
    => Repl
    -> [Text]
    -> FilePath
    -> Eff es LoadResult
collectLoadResult repl lines' projectRoot = do
    let noProgress = \_ -> pure ()
    moduleLines <- Repl.exec repl ":show modules" noProgress
    targetLines <- Repl.exec repl ":show targets" noProgress
    let result =
            collectResult
                projectRoot
                lines'
                (parseShowModules moduleLines)
                (parseShowTargets targetLines)
    -- A failed load with no located error produces only the synthetic
    -- 'unattributedFailure'. The parsed diagnostics tell the user nothing in
    -- that case, so log the raw GHCi output — it's the only way to see what
    -- actually went wrong, and the synthetic diagnostic points here.
    when (any (== unattributedFailure) result.diagnostics)
        $ Log.info
        $ "GHCi reported a failed load with no located error. Full GHCi output:\n"
            <> T.unlines lines'
    pure result


-- | Execute @:reload@ and return the assembled 'LoadResult'. Progress events
-- fire live via @onProgress@ as each @[N of M] Compiling …@ line is read.
reload
    :: (Conc :> es, Concurrent :> es, File :> es, Log :> es)
    => Repl
    -> FilePath
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
reload repl projectRoot onProgress = do
    reloadLines <- Repl.exec repl ":reload" onProgress
    collectLoadResult repl reloadLines projectRoot


-- | Execute @:add@ for the given file and return the assembled 'LoadResult'.
-- Progress events fire live via @onProgress@ as compilation proceeds.
add
    :: (Conc :> es, Concurrent :> es, File :> es, Log :> es)
    => Repl
    -> FilePath -- the file to :add
    -> FilePath -- projectRoot
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
add repl filePath projectRoot onProgress = do
    addLines <- Repl.exec repl (":add " <> T.pack filePath) onProgress
    collectLoadResult repl addLines projectRoot


-- | Execute @:unadd@ for the given module and return the assembled
-- 'LoadResult'. Progress events fire live via @onProgress@ as compilation
-- proceeds.
unadd
    :: (Conc :> es, Concurrent :> es, File :> es, Log :> es)
    => Repl
    -> Text -- the module name to :unadd
    -> FilePath -- projectRoot
    -> (GhciLoading -> Eff es ())
    -> Eff es LoadResult
unadd repl moduleName projectRoot onProgress = do
    unaddLines <- Repl.exec repl (":unadd " <> moduleName) onProgress
    collectLoadResult repl unaddLines projectRoot
