# atelier-observe-otel

An [OpenTelemetry](https://opentelemetry.io/) exporter for [`atelier-observe`](https://github.com/atelier-hub/tricorder/tree/main/atelier-observe). Part of the **atelier** toolkit.

`atelier-observe` turns an instrumented run into a stream of `Moment`s; this package supplies a `Consumer` that folds that stream into OpenTelemetry spans:

- `Entered` → a span opens (child of the enclosing region's span; a fresh trace per outermost region)
- `Exited` → the span ends with `Ok` status
- `Failed` → the span ends with `Error` status and the exception recorded
- `Measured` → a span event carrying the sampler reading
- signals (the `e` lane) → span attributes
- a region's path → span **name** and **kind** (`SpanKind`, for backend topology and span metrics), via the caller's `Render`
- a `Tap`'s `linkedTo` targets → span **links** between traces

It depends on `hs-opentelemetry-api` for the span API and (in `Atelier.Observe.OpenTelemetry.Provider`) the SDK + OTLP exporter for a ready-made `TracerProvider`. The exporter `Consumer` itself takes a `Tracer`, so you can point it at any provider — including an in-memory one for tests.

## Part of atelier

- [`atelier-prelude`](https://github.com/atelier-hub/tricorder/tree/main/atelier-prelude) — relude-based custom prelude adapted for Effectful
- [`atelier-core`](https://github.com/atelier-hub/tricorder/tree/main/atelier-core) — foundational effects and utilities
- [`atelier-observe`](https://github.com/atelier-hub/tricorder/tree/main/atelier-observe) — side-channel observation of oblivious Effectful programs
- [`atelier-observe-otel`](https://github.com/atelier-hub/tricorder/tree/main/atelier-observe-otel) — this package
- [`atelier-db`](https://github.com/atelier-hub/tricorder/tree/main/atelier-db) — relational database effect (Hasql/Rel8)
- [`atelier-testing`](https://github.com/atelier-hub/tricorder/tree/main/atelier-testing) — database-backed test utilities

## License

MIT — see [LICENSE](LICENSE).
