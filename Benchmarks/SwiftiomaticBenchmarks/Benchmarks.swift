import Benchmark

/// Registration point the `BenchmarkPlugin` generated runner calls
///
/// Each area registers its own benchmarks. Read the figures from a release run, because this target
/// measures optimized code and a debug build inflates dictionary and existential costs enough to
/// misreport where the time goes.
///
/// The target uses `@testable`, so a run needs the testing flag:
///
/// ```sh
/// swift package -Xswiftc -enable-testing benchmark
/// ```
let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .mallocCountTotal],
        warmupIterations: 3,
        maxDuration: .seconds(5)
    )

    registerLintBenchmarks()
    registerFormatBenchmarks()
    registerLintCacheBenchmarks()
    registerWhitespaceBenchmarks()
}

/// Tolerances a comparison allows before it reports a regression
///
/// These bound the deviation between two runs. They are not ceilings on the figures themselves.
/// `swift package benchmark thresholds update` records the ceilings separately.
///
/// Each is computed rather than stored, because `BenchmarkThresholds` is not `Sendable` and a
/// stored static property of a non-`Sendable` type is global mutable state.
///
/// Every band names `mallocCountTotal` as well as `wallClock`. A metric left out of the dictionary
/// falls back to a zero tolerance, and an allocation count that moves by one then fails the run.
enum Tolerance {
    /// For the end-to-end paths, which measured under 7% deviation across ten iterations
    static var steady: [BenchmarkMetric: BenchmarkThresholds] {
        [.wallClock: .init(relative: [.p50: 10.0, .p90: 15.0]), .mallocCountTotal: allocations]
    }

    /// For the short walks and the dispatch probes, where per-iteration variance is larger
    static var noisy: [BenchmarkMetric: BenchmarkThresholds] {
        [.wallClock: .init(relative: [.p50: 25.0, .p90: 35.0]), .mallocCountTotal: allocations]
    }

    /// Allocation counts hold steady across a run, so this is tight on purpose.
    ///
    /// The absolute band covers the counts that shift with the iteration number, such as the file
    /// names the cache benchmarks build. The relative band still catches a real jump in a benchmark
    /// that allocates little.
    private static var allocations: BenchmarkThresholds {
        .init(relative: [.p50: 5.0, .p90: 5.0], absolute: [.p50: 1_000, .p90: 1_000])
    }
}
