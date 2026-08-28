import Benchmark
import Foundation
@testable import SwiftiomaticKit

/// Sizes `LintCache.store` against the lint it follows
///
/// `LintFrontend` calls `store` on the worker thread once a file finishes linting, so a parallel
/// run has every worker doing a `createDirectory`, a JSON encode and an atomic write before it
/// picks up the next file. Whether moving that off the critical path is worth a write queue depends
/// on the ratio between the write and the lint that precedes it.
///
/// The ratio is not a single number. Write cost is close to fixed while lint cost scales with the
/// file, so read these against the median-file lint benchmark rather than the gate file.
func registerLintCacheBenchmarks() {
    registerMedianLintBenchmark()

    Benchmark(
        "CacheStoreCleanRecord",
        configuration: .init(thresholds: Tolerance.steady),
        closure: { benchmark in
            var iteration = 0
            benchmark.startMeasurement()
            for _ in 0..<storesPerBatch {
                iteration += 1
                sharedCache.store(
                    absolutePath: "/tmp/benchmark/file\(iteration).swift",
                    contentHash: "hash\(iteration)",
                    fingerprint: fingerprint,
                    record: cleanRecord
                )
            }
        },
        setup: { warmCacheDirectory() },
        teardown: { removeCacheDirectory() }
    )

    Benchmark(
        "CacheStoreRecordWithFindings",
        configuration: .init(thresholds: Tolerance.steady),
        closure: { benchmark in
            var iteration = 0
            benchmark.startMeasurement()
            for _ in 0..<storesPerBatch {
                iteration += 1
                sharedCache.store(
                    absolutePath: "/tmp/benchmark/found\(iteration).swift",
                    contentHash: "hash\(iteration)",
                    fingerprint: fingerprint,
                    record: recordWithFindings
                )
            }
        },
        setup: { warmCacheDirectory() },
        teardown: { removeCacheDirectory() }
    )
}

/// Stores per measured iteration. One store is too short to time against the clock's resolution, so
/// divide the figure by this count when quoting a per-store cost.
private let storesPerBatch = 100

/// Fixed stand-in for the configuration fingerprint. `store` only uses it to pick a subdirectory,
/// so the real hash adds nothing to what is measured here.
private let fingerprint = String(repeating: "a", count: 64)

private let cacheRoot = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("SwiftiomaticBenchmarkCache")

private let sharedCache = LintCache(root: cacheRoot)

/// A record for a file that linted clean, which is what most files produce
private let cleanRecord = LintCache.Record(entries: [])

/// A record carrying findings, to show how much of the write cost is the payload
private let recordWithFindings = LintCache.Record(
    entries: (0..<10).map { index in
        LintCache.Entry(
            category: "SomeRuleName",
            severity: .warn,
            message: "a finding message of a length typical for this project, index \(index)",
            location: LintCache.Location(file: "/tmp/benchmark/Some.swift", line: index, column: 4),
            notes: []
        )
    }
)

/// Writes one record so the measured iterations read the steady state, where every file after the
/// first finds the fingerprint subdirectory already present.
private func warmCacheDirectory() {
    sharedCache.store(
        absolutePath: "/tmp/benchmark/warm.swift",
        contentHash: "warm",
        fingerprint: fingerprint,
        record: cleanRecord
    )
}

private func removeCacheDirectory() { try? FileManager.default.removeItem(at: cacheRoot) }
