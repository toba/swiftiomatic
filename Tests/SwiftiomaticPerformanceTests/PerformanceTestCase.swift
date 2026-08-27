import XCTest
import Foundation

/// The environment variable that lets a benchmark run
let benchmarkEnvironmentKey = "RUN_BENCHMARKS"

/// Base class for every benchmark in this target, which a plain test run skips
///
/// A benchmark answers how fast the shipping build is, and a plain `swift test` cannot answer it.
/// This target compiles at `-Onone`, so a figure taken there describes an unoptimized build. Read a
/// benchmark from a release run.
///
/// The cost is real either way. XCTest runs a `measure` body ten times, and the walks under this
/// target each cross the largest file in the repository, so the benchmarks add tens of seconds to
/// every unrelated test run.
///
/// Set `RUN_BENCHMARKS` in the environment to run them.
///
/// A subclass that overrides `setUpWithError()` calls `super` first. The skip fires there, so the
/// fixture work below it never runs.
//  sm:ignore:next requireFinalOnXCTestCase - every benchmark class inherits from this one
class PerformanceTestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment[benchmarkEnvironmentKey] != nil,
            "set \(benchmarkEnvironmentKey) to run the benchmarks")
    }

    /// Runs `block` once under Swift CI, where performance numbers are not read and nodes have
    /// variable characteristics. Anywhere else, times it with `measure` .
    func measureIfNotInCI(_ block: () -> Void) {
        if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] != nil {
            block()
        } else {
            measure { block() }
        }
    }
}
