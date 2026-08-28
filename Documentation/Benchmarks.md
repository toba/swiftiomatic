# Benchmarks

## Introduction

The `SwiftiomaticBenchmarks` target measures the paths `sm` runs on every file. It is built on
[package-benchmark](https://github.com/ordo-one/package-benchmark), which records baselines as JSON
and fails a run when a figure crosses a threshold.

The target is an executable, not a test target, because the benchmark plugin discovers and runs it.
No `sm` target depends on it. `scripts/install.sh` builds `--product sm`, so the release build never
compiles it and the shipping binary never links it.

This file holds the workflow. It holds no figures. The recorded numbers live in `Thresholds/`, and
the tooling writes them. A number copied into prose drifts from the one the gate checks.

## Running

The target reaches the internal pipeline types with `@testable import SwiftiomaticKit`, so every run
passes the testing flag:

```sh
swift package -Xswiftc -enable-testing benchmark
```

Omit the flag and the target fails to compile with "module was not compiled for testing".

The flag applies to that invocation alone. It does not reach `scripts/install.sh`, which is why the
shipping binary keeps its normal optimization.

Every global option goes before the `benchmark` verb. Put one after it and the plugin rejects it as
an unknown option.

Run one benchmark by name:

```sh
swift package -Xswiftc -enable-testing benchmark --filter LintFullPathGateFile
```

## The three records the tooling keeps

### Thresholds, the gate

`Thresholds/` holds one JSON file per benchmark, each carrying a wall-clock and an allocation
ceiling. These are committed. They are what turns a benchmark run into a check.

```sh
swift package -Xswiftc -enable-testing --allow-writing-to-package-directory \
  benchmark thresholds update
swift package -Xswiftc -enable-testing benchmark thresholds check
```

Run `update` only when a change is meant to move a figure. Run `check` to find out whether one moved
without being meant to.

### Baselines, the local comparison

```sh
swift package -Xswiftc -enable-testing --allow-writing-to-package-directory \
  benchmark baseline update main
swift package -Xswiftc -enable-testing benchmark baseline compare main
```

Compare two records to weigh two approaches to one problem:

```sh
swift package -Xswiftc -enable-testing benchmark baseline compare main experiment
```

Baselines key on a machine identifier and do not transfer between machines, so `.gitignore` excludes
`.benchmarkBaselines/`. Upstream also states that this representation is not stable and may break
between releases, so never treat a baseline as an archive.

### Exports, the history

An export is the supported way to keep figures over time. Upstream names these formats the intended
stable interface for saving benchmark data.

```sh
swift package -Xswiftc -enable-testing --allow-writing-to-package-directory \
  benchmark --format jmh
```

`histogramEncoded` and `histogramSamples` keep the full distribution. `influx` suits a time-series
database. `markdown` produces a table meant for a continuous integration job summary.

## Tolerances

`Tolerance` in `Benchmarks.swift` sets how far a run may deviate before a comparison reports a
regression. Two bands cover the suite. `steady` allows 10% at p50 and 15% at p90, and covers the
end-to-end paths. `noisy` allows 25% and 35%, and covers the short walks and the dispatch probes.

A tolerance is not a ceiling. The ceilings live in `Thresholds/`.

## What each benchmark measures

| Benchmark | Path |
|---|---|
| `LintFullPathGateFile` | `LintCoordinator.lint`, both walks, on the largest file in the repository |
| `LintPipelineWalkGateFile` | `LintPipeline` alone, to show the share a dispatch change can reach |
| `LintMedianSizedFile` | `LintCoordinator.lint` on a file at the repository's median line count |
| `RuleLookupDictionary` | The current dispatch shape, repeated once per lookup a real walk performs |
| `RuleLookupArrayIndex` | The typed-table shape, over the same operation count |
| `FormatFullPipeline` | `RewriteCoordinator.format`, the Xcode active-file path |
| `FormatTwoStageCompactGateFile` | `RewritePipeline` plus the ordered structural passes |
| `CacheStoreCleanRecord` | 100 `LintCache.store` calls for a file that linted clean |
| `CacheStoreRecordWithFindings` | The same, for a record carrying ten findings |
| `WhitespaceLintMisSpacedFile` | `WhitespaceLinter.lint` on the stdin path Xcode uses |

The two cache benchmarks measure 100 stores per iteration. One store is too short to time against
the clock's resolution. Divide by 100 to quote a per-store cost.

## The XCTest target

`Tests/SwiftiomaticPerformanceTests` still holds the same measurements as XCTest `measure` blocks.
It stays until these baselines are proven. Run it with `RUN_BENCHMARKS` set, in release.

XCTest writes a baseline only as an `.xcbaseline` bundle, and only Xcode reads one. A `swift test`
run ignores it, which is why that target reports figures and gates nothing.

Three benchmarks moved setup out of the timed region during the port, so their figures do not line
up with the XCTest ones.

- Whitespace lint now times `WhitespaceLinter.lint` alone. The XCTest block also timed the parse and
  the context construction.
- The lint pipeline walk and the two-stage compact pipeline now build the `Context` before
  measurement starts. The XCTest blocks built it inside.

The remaining seven measure the same region as before.
