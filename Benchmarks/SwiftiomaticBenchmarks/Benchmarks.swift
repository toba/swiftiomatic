import Benchmark
import TobaBenchmark

/// Registration point the `BenchmarkPlugin` generated runner calls
///
/// Each area registers its own benchmarks.
///
/// The target uses `@testable`, so a run needs the testing flag:
///
/// ```sh
/// swift package -Xswiftc -enable-testing benchmark
/// ```
let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = BenchmarkRun.defaultConfiguration()

    registerLintBenchmarks()
    registerFormatBenchmarks()
    registerLintCacheBenchmarks()
    registerWhitespaceBenchmarks()
}

/// Tolerances a comparison allows before it reports a regression
///
/// The name shadows `TobaBenchmark.Tolerance` inside this file, so each builder call below names
/// the module.
enum Tolerance {
    /// For the end-to-end paths, which measured under 7% deviation across ten iterations
    static var steady: [BenchmarkMetric: BenchmarkThresholds] {
        [
            .wallClock: TobaBenchmark.Tolerance.wallClock(p50: 10.0, p90: 15.0),
            .mallocCountTotal: allocations,
        ]
    }

    /// For the short walks and the dispatch probes, where per-iteration variance is larger
    static var noisy: [BenchmarkMetric: BenchmarkThresholds] {
        [
            .wallClock: TobaBenchmark.Tolerance.wallClock(p50: 25.0, p90: 35.0),
            .mallocCountTotal: allocations,
        ]
    }

    /// Allocation counts hold steady across a run, so this is tight on purpose.
    ///
    /// The absolute band covers the counts that shift with the iteration number, such as the file
    /// names the cache benchmarks build. The relative band still catches a real jump in a benchmark
    /// that allocates little.
    private static var allocations: BenchmarkThresholds {
        TobaBenchmark.Tolerance.drift(count: 1_000)
    }
}
