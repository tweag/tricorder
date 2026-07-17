# Changelog

All notable changes to `atelier-observe-otel` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to the [PVP](https://pvp.haskell.org/).

## [Unreleased]

### Added

- Initial release: an OpenTelemetry exporter for `atelier-observe`.
- The `exporting` consumer attaches `atelier-observe` scope signals
  (`MomentCtx.tags`) as span attributes on every span in the tagged subtree, so a
  whole subtree can be filtered or attributed by them in the backend.
- `Atelier.Observe.OpenTelemetry.Provider` — a thin wrapper around the
  hs-opentelemetry SDK that initialises a `TracerProvider` (OTLP, configured by
  the standard `OTEL_*` environment variables) and derives a `Tracer`, with a
  bracketed flush on shutdown.
