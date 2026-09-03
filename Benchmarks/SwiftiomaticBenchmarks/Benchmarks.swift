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
    Benchmark.defaultConfiguration = BenchmarkRun.defaultConfiguration(metrics: [
        .wallClock, .instructions, .syscalls, .mallocCountTotal,
    ])

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
            .instructions: instructions,
            .syscalls: TobaBenchmark.Tolerance.fixed(count: 200),
            .mallocCountTotal: allocations,
        ]
    }

    /// For the short walks and the dispatch probes, where per-iteration variance is larger
    static var noisy: [BenchmarkMetric: BenchmarkThresholds] {
        [
            .wallClock: TobaBenchmark.Tolerance.wallClock(p50: 25.0, p90: 35.0),
            .instructions: instructions,
            .syscalls: TobaBenchmark.Tolerance.fixed(count: 200),
            .mallocCountTotal: allocations,
        ]
    }

    /// The second gate. It holds far tighter than the clock across a run, and it catches a change
    /// that moves work without moving an allocation.
    private static var instructions: BenchmarkThresholds {
        TobaBenchmark.Tolerance.relative(p50: 3.0, p90: 3.0)
    }

    /// Allocation counts hold steady across a run, so this is tight on purpose.
    ///
    /// The band covers the counts that shift with the iteration number, such as the file names the
    /// cache benchmarks build. A percentage beside it would catch nothing extra and would fail a
    /// benchmark that allocates little, where a move of one is a large fraction of the recording.
    private static var allocations: BenchmarkThresholds {
        TobaBenchmark.Tolerance.fixed(count: 1_000)
    }
}
