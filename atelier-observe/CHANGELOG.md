# Changelog

All notable changes to `atelier-observe` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- Initial release, extracted from the atelier toolkit: side-channel
  observation of oblivious Effectful programs.
- `Atelier.Observe` — the core. A `Tap` interposes on an oblivious effect to
  emit signals on each region boundary; a `Plan` assembles taps and samplers;
  discharging a plan (`observe` / `observeInto` / `silent`) turns a run into a
  `Moment` stream; a `Consumer` (a `Control.Foldl.FoldM`) folds that stream
  into a harvest.
- `Atelier.Observe.Aggregate` — one summary policy: a `Region` trie of
  two-laned `Report`s keyed into `Traces`, with the `collecting` consumer that
  builds it. A pure function of the public `Moment` stream, so the core never
  depends on it.
- `tapping` — the preferred inverted surface for building a first-order `Tap`:
  match an operation once and declare all its facets (`atRegion`, `underTrace`,
  `linkTo`, `enterWith`, `exitWith`, `failWith`, `tagWith`) together in a `do`
  block. It compiles to the same record the `watch` / `entering` setter chain
  does.
- Scope signals — a new `Tap` lane (`tagging` setter, `tagWith` builder command,
  `onScope` field) whose signals are in effect over a region *and every region
  nested inside it*, riding `MomentCtx.tags` on every descendant moment. The seam
  for tagging a whole subtree (a component name, request id, tenant) so a consumer
  can filter or attribute by it; the OpenTelemetry exporter attaches them as
  attributes on every span in the subtree. `MomentCtx` gains a `tags` field.
