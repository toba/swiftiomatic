import XCTest
import Foundation
@testable import SwiftiomaticKit

/// Sizes `LintCache.store` against the lint it follows.
///
/// `LintFrontend` calls `store` on the worker thread once a file finishes linting, so a
/// `--parallel` run has every worker doing a `createDirectory` , a JSON encode and an atomic write
/// before it picks up the next file. Whether moving that off the critical path is worth a write
/// queue depends on the ratio between the write and the lint that precedes it.
///
/// The ratio is not a single number, because the write cost is close to fixed while lint cost
/// scales with the file. These tests use a file at the median size of this repository (86 lines
/// across 424 non-generated sources) rather than the perf-gate file, which is 1999 lines and makes
/// any fixed cost look free.
///
/// Read these in release. Set `RUN_BENCHMARKS` to run them.
final class LintCachePerformanceTests: PerformanceTestCase {
    /// A real source file at the repository's median line count.
    private static func medianSizedSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SwiftiomaticPerformanceTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repo root
            .appendingPathComponent("Sources/SwiftiomaticKit/Syntax/Parsing.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// A record for a file that linted clean, which is what most files produce.
    private static let cleanRecord = LintCache.Record(entries: [])

    /// A record carrying findings, to show how much of the write cost is the payload.
    private static let recordWithFindings = LintCache.Record(entries: (0..<10).map { index in
        LintCache.Entry(
            category: "SomeRuleName",
            severity: .warn,
            message: "a finding message of a length typical for this project, index \(index)",
            location: LintCache.Location(file: "/tmp/perf/Some.swift", line: index, column: 4),
            notes: []
        )
    }
    )

    // Optional, not implicitly unwrapped: the skip in super fires before these are assigned, so
    // tearDown runs against nil on a plain test run.
    private var cacheRoot: URL?
    private var cache: LintCache!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LintCachePerf-\(ProcessInfo.processInfo.globallyUniqueString)")
        cacheRoot = root
        cache = LintCache(root: root)
        // Warm the directory so the benchmark reads the steady state, where every file after the
        // first in a run finds the fingerprint subdirectory already present.
        cache.store(
            absolutePath: "/tmp/perf/warm.swift",
            contentHash: "warm",
            fingerprint: Self.fingerprint,
            record: Self.cleanRecord
        )
    }

    override func tearDownWithError() throws {
        if let cacheRoot { try? FileManager.default.removeItem(at: cacheRoot) }
        try super.tearDownWithError()
    }

    /// Fixed stand-in for the configuration fingerprint. `store` only uses it to pick a
    /// subdirectory, so the real hash adds nothing to what is measured here.
    private static let fingerprint = String(repeating: "a", count: 64)

    /// Lint of a median-sized file, the work `store` follows on a cache miss.
    func testLintMedianSizedFile() throws {
        let source = try Self.medianSizedSource()
        measureIfNotInCI {
            let coordinator = LintCoordinator(
                configuration: Configuration(), findingConsumer: { _ in })
            try? coordinator.lint(
                source: source, assumingFileURL: URL(fileURLWithPath: "/tmp/perf/median.swift"))
        }
    }

    /// One `store` per iteration for a clean file, each to a distinct key so no write is elided.
    func testStoreCleanRecord() throws {
        var iteration = 0
        measureIfNotInCI {
            for _ in 0..<Self.storesPerBatch {
                iteration += 1
                cache.store(
                    absolutePath: "/tmp/perf/file\(iteration).swift",
                    contentHash: "hash\(iteration)",
                    fingerprint: Self.fingerprint,
                    record: Self.cleanRecord
                )
            }
        }
    }

    /// The same, for a record carrying ten findings.
    func testStoreRecordWithFindings() throws {
        var iteration = 0
        measureIfNotInCI {
            for _ in 0..<Self.storesPerBatch {
                iteration += 1
                cache.store(
                    absolutePath: "/tmp/perf/file\(iteration).swift",
                    contentHash: "hash\(iteration)",
                    fingerprint: Self.fingerprint,
                    record: Self.recordWithFindings
                )
            }
        }
    }

    /// Stores per measured batch. One store is too short to time against the clock's resolution, so
    /// the batch is divided out when the figure is quoted.
    private static let storesPerBatch = 100
}
