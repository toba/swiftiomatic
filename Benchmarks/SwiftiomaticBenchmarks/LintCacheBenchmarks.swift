import Benchmark
import Foundation
import TobaBenchmark
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

    registerStoreBenchmark("CacheStoreCleanRecord", paths: cleanPaths, record: cleanRecord)
    registerStoreBenchmark(
        "CacheStoreRecordWithFindings",
        paths: findingPaths,
        record: recordWithFindings
    )
}

/// Registers one benchmark that stores `record` under each of `paths`
///
/// Both store benchmarks measure the same loop. Building them here keeps the measured region in one
/// place, so an edit to it cannot reach one benchmark and miss the other.
///
/// - Parameters:
///   - name: The benchmark name the threshold files key on
///   - paths: The absolute paths the loop stores under, one per measured store
///   - record: The record every store in the loop writes
private func registerStoreBenchmark(
    _ name: String,
    paths: [String],
    record: LintCache.Record
) {
    Benchmark(
        name,
        configuration: .init(warmupIterations: storeWarmupCount, thresholds: Tolerance.steady),
        closure: { benchmark in
            benchmark.startMeasurement()
            for index in 0..<storesPerBatch {
                sharedCache.store(
                    absolutePath: paths[index],
                    contentHash: contentHashes[index],
                    fingerprint: fingerprint,
                    record: record
                )
            }
        },
        setup: { prepareFixtures() },
        teardown: { removeCacheDirectory() }
    )
}

/// Stores per measured iteration. One store is too short to time against the clock's resolution, so
/// divide the figure by this count when quoting a per-store cost.
private let storesPerBatch = 100

/// Warmup iterations both store benchmarks run before the first sample
///
/// The cost per iteration climbs over the first ten to fifteen iterations, then holds. The first
/// pass over the path list creates each file. Every later pass renames a temporary file over an
/// existing one, which unlinks the replaced inode, and that costs more than a create.
///
/// The run length the suite inherits gives one warmup on a short pass, which leaves all ten samples
/// on the climb. `CacheStoreCleanRecord` then read a p90 of 715653119 against 778043391 from a
/// 500-sample pass, a gap of 8.7% against a 3% band. The deep pass held p25 through p90 inside 2%,
/// which is the plateau. Twenty warmups put every sample there at either pass length.
private let storeWarmupCount = max(BenchmarkRun.warmupCount, 20)

/// Fixed stand-in for the configuration fingerprint. `store` only uses it to pick a subdirectory,
/// so the real hash adds nothing to what is measured here.
private let fingerprint = String(repeating: "a", count: 64)

/// Paths the clean-record benchmark stores under
///
/// Building a name from the loop index inside the measured region makes the cost of an iteration
/// depend on how many digits the index carries, so the figure describes the pass length rather than
/// the write. These lists hold every name the loop needs, and `prepareFixtures` builds them before
/// the first measured iteration.
private let cleanPaths = (0..<storesPerBatch).map { "/tmp/benchmark/file\($0).swift" }

/// Paths the findings-record benchmark stores under
private let findingPaths = (0..<storesPerBatch).map { "/tmp/benchmark/found\($0).swift" }

/// Content hashes both benchmarks pair with their paths
private let contentHashes = (0..<storesPerBatch).map { "hash\($0)" }

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

/// Builds the name lists and writes one record, so the measured iterations read the steady state
///
/// Every file after the first finds the fingerprint subdirectory already present. Touching each
/// name list here runs its one-time initialization outside the measured region.
private func prepareFixtures() {
    blackHole(cleanPaths)
    blackHole(findingPaths)
    blackHole(contentHashes)
    sharedCache.store(
        absolutePath: "/tmp/benchmark/warm.swift",
        contentHash: "warm",
        fingerprint: fingerprint,
        record: cleanRecord
    )
}

private func removeCacheDirectory() { try? FileManager.default.removeItem(at: cacheRoot) }
