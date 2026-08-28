# SwiftiomaticBenchmarks

Benchmarks for the lint, format and cache paths, built on [package-benchmark](https://github.com/ordo-one/package-benchmark).

## What It Does

Measures wall-clock time and allocation counts for the paths `sm` runs on every file: the full lint, the full format, each pipeline walk on its own, and the lint cache write. Records baselines as JSON and fails a run when a figure crosses its threshold.

## Where It Fits

An executable target rather than a test target, because the benchmark plugin discovers and runs it. It uses `@testable import SwiftiomaticKit` to reach the internal pipeline types, so a run passes `-Xswiftc -enable-testing`:

```sh
swift package -Xswiftc -enable-testing benchmark
```

No `sm` target depends on this one, so the shipping binary carries none of it. `scripts/install.sh` builds `--product sm`, which leaves this target out of the release build entirely.

See [Documentation/Benchmarks.md](../../Documentation/Benchmarks.md) for the workflow and the recorded figures.
