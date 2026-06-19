-- | The observation 'Plan' for @atelier-core@'s own effects, built on "Atelier.Observe". It keeps
-- the base library's effects oblivious — the instrumentation lives here, opt-in, and merges into an
-- application's 'Plan' with @'<>'@.
--
-- For now it ships the 'Conc' fork-linking tap ('concForkLinks'): the structured-concurrency analog
-- of the retired @Atelier.Effects.Conc.Traced@, routed through "Atelier.Observe" instead of the
-- OpenTelemetry effect. It is an ordinary higher-order 'Atelier.Observe.rerooting' tap — no bespoke
-- interpose — whose 'OverActions' mapping wraps the fork operations. Taps for the publish/subscribe
-- and component effects, whose region labels and trace identities are an application's vocabulary,
-- are best assembled where that vocabulary lives (e.g. tricorder's plan) with the
-- 'Atelier.Observe.tap' combinators.
module Atelier.Observe.Core
    ( concForkLinks
    ) where

import Atelier.Observe (OverActions, Plan, rerooting, tap)

import Atelier.Effects.Conc (Conc (..), concStrat)


-- | A 'Plan' that links forked threads back to the region that spawned them. It is a higher-order
-- 'rerooting' tap over 'Conc': each forked action ('fork', 'fork_', 'forkTry') runs in its /own/
-- trace (no nesting under, nor unbounded growth of, the parent's) yet links back to the exact fork
-- site. Parent→child transport is free: the scope cursor rides the shared effect environment into
-- the child. The non-forking 'Conc' operations pass through untouched. Merge it into an
-- application's observe 'Plan' with @'<>'@.
concForkLinks :: (Conc :> es) => Plan es i r e s
concForkLinks = tap (rerooting concStrat overForks)


-- Where 'Conc''s fork operations carry their actions: wrap each so it reroots and links back to the
-- fork site (the framework supplies @wrap@). Everything else — 'Await', 'AwaitAll', 'Race',
-- 'Scoped' — passes through unwrapped, matching the retired @runConcTraced@, which linked only the
-- explicit forks.
overForks :: OverActions Conc
overForks wrap = \case
    Fork action -> Fork (wrap action)
    Fork_ action -> Fork_ (wrap action)
    ForkTry action -> ForkTry (wrap action)
    other -> other
