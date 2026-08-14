-- | Tracing integration for the 'Conc' effect.
--
-- Provides interpreters and interposers that automatically propagate
-- OpenTelemetry trace context across thread boundaries using span links.
module Atelier.Effects.Conc.Traced
    ( module ExConc
    , ExConc.await

      -- * Interpreters
    , runConc
    , runConcByConfig
    , runConcTraced

      -- * Interposers
    , withConcTracingLinks
    )
where

import Atelier.Effects.Conc (Conc (..), Scope (..), concStrat, fork, forkTry, fork_, runConcBase)
import Effectful (IOE, raise, withEffToIO)
import Effectful.Concurrent (Concurrent)
import Effectful.Dispatch.Dynamic (interpose, localLend, localUnlift, passthrough)
import Effectful.Reader.Static (Reader, asks)

import Atelier.Effects.Conc qualified as Conc
import Atelier.Effects.Conc qualified as ExConc hiding (runConc)
import Ki qualified

import Atelier.Effects.Monitoring.Tracing (Tracing, TracingConfig (..))

import Atelier.Effects.Monitoring.Tracing qualified as Tracing


-- | Run 'Conc' effect with automatic trace context propagation in a new scope.
runConc :: (Concurrent :> es, IOE :> es, Tracing :> es) => Eff (Conc : es) a -> Eff es a
runConc eff = withEffToIO concStrat $ \unlift ->
    Ki.scoped $ \scope ->
        unlift $ runConcTraced (Scope scope) eff


-- | Run 'Conc' effect, selecting the interpreter based on tracing config.
--
-- If tracing is enabled, uses 'runConc' for automatic span link propagation.
-- If tracing is disabled, falls back to 'Conc.runConc' to skip the overhead.
runConcByConfig
    :: ( Concurrent :> es
       , IOE :> es
       , Reader TracingConfig :> es
       , Tracing :> es
       )
    => Eff (Conc : es) a -> Eff es a
runConcByConfig eff = do
    tracingEnabled <- asks @TracingConfig (.enabled)
    if tracingEnabled then runConc eff else Conc.runConc eff


-- | Run 'Conc' effect with automatic trace context propagation.
--
-- All fork variants ('fork', 'fork_', 'forkTry') use span links, i.e. forked
-- threads start a fresh trace whose root spans carry a link back to the
-- originating span.
runConcTraced
    :: ( Concurrent :> es
       , IOE :> es
       , Tracing :> es
       )
    => Scope -> Eff (Conc : es) a -> Eff es a
runConcTraced scope = runConcBase scope . withConcTracingLinks


-- | Intercept fork operations and wrap the forked action with span link propagation.
--
-- Re-dispatches to the underlying 'Conc' handler via 'fork', 'fork_', 'forkTry'.
withConcTracingLinks :: (Conc :> es, Tracing :> es) => Eff es a -> Eff es a
withConcTracingLinks = interpose \env -> \case
    Fork action -> tracedFork env action fork
    Fork_ action -> tracedFork env action fork_
    ForkTry action -> tracedFork env action forkTry
    other -> passthrough env other
  where
    tracedFork env action kiOp = do
        parentCtx <- Tracing.getSpanContext
        localUnlift env concStrat \unliftEff ->
            localLend @'[Tracing] env concStrat \lend ->
                kiOp
                    $ unliftEff
                        . lend
                        . Tracing.withLinkPropagation parentCtx
                        . raise @Tracing
                    $ action
