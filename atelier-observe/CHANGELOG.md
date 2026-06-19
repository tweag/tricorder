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
