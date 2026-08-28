import Benchmark
import SwiftParser
import SwiftSyntax
@testable import SwiftiomaticKit

/// Timing for the lint path, and the dispatch probes that size a change to it
///
/// `LintCoordinator.lint` runs two walks over the file. `RewritePipeline` runs first so the static
/// `willEnter` and `transform` hooks fire and emit their findings, and its mutated tree is
/// discarded. `LintPipeline` walks second for the lint-only rules and the structural-pass rules
/// that keep an instance `visit` override. Each walk is timed on its own so a change to one is not
/// read off the total.
func registerLintBenchmarks() {
    Benchmark(
        "LintFullPathGateFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = Fixture.perfGateSource()
        benchmark.startMeasurement()
        let coordinator = LintCoordinator(configuration: Configuration(), findingConsumer: { _ in })
        try? coordinator.lint(source: source, assumingFileURL: Fixture.scratchFileURL)
    }

    // Compare against the full path to see what share of lint time a dispatch change can reach.
    Benchmark(
        "LintPipelineWalkGateFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let sourceFile = Parser.parse(source: Fixture.perfGateSource())
        let context = Fixture.context(for: sourceFile)
        benchmark.startMeasurement()
        LintPipeline(context: context).walk(Syntax(sourceFile))
    }

    registerDispatchProbes()
}

/// Lint of a file at the repository's median size, which is the work `LintCache.store` follows on a
/// cache miss.
func registerMedianLintBenchmark() {
    Benchmark(
        "LintMedianSizedFile",
        configuration: .init(thresholds: Tolerance.steady)
    ) { benchmark in
        let source = Fixture.medianSizedSource()
        benchmark.startMeasurement()
        let coordinator = LintCoordinator(configuration: Configuration(), findingConsumer: { _ in })
        try? coordinator.lint(source: source, assumingFileURL: Fixture.scratchFileURL)
    }
}

// MARK: - What a typed dispatch table would replace

/// Rule-cache lookups one `LintPipeline` walk performs over the gate file. Measured 2026-08-27 with
/// a temporary counter in `LintPipeline.rule(_:)`, which was removed once the number was recorded.
///
/// The two probes below repeat exactly this many operations, so their difference is the whole
/// saving a typed dispatch table can produce for this file.
private let lookupsPerWalk = 30_062

@inline(never)
private func viaDictionary<R: InstanceSyntaxRule>(
    _ type: R.Type,
    _ cache: [ObjectIdentifier: any SyntaxRule]
) -> R? { cache[ObjectIdentifier(type)] as? R }

@inline(never)
private func viaIndex<R: InstanceSyntaxRule>(_ index: Int, _ table: [R]) -> R { table[index] }

/// Builds a cache holding the rules a real walk instantiates, so a lookup runs against a dictionary
/// of the true size and key distribution.
private func populatedRuleCache() -> (
    cache: [ObjectIdentifier: any SyntaxRule], probe: NestingDepth
) {
    let sourceFile = Parser.parse(source: Fixture.perfGateSource())
    let context = Fixture.context(for: sourceFile)
    let pipeline = LintPipeline(context: context)
    pipeline.walk(Syntax(sourceFile))
    return (pipeline.ruleCache, NestingDepth(context: context))
}

private func registerDispatchProbes() {
    // Current shape: ObjectIdentifier construction, dictionary lookup, then a conditional cast off
    // an existential, repeated once per rule per node.
    Benchmark(
        "RuleLookupDictionary",
        configuration: .init(thresholds: Tolerance.noisy)
    ) { benchmark in
        let (cache, _) = populatedRuleCache()
        benchmark.startMeasurement()
        for _ in 0..<lookupsPerWalk { blackHole(viaDictionary(NestingDepth.self, cache)) }
    }

    // Proposed shape: an array subscript into a typed table of rule instances.
    Benchmark(
        "RuleLookupArrayIndex",
        configuration: .init(thresholds: Tolerance.noisy)
    ) { benchmark in
        let (_, probe) = populatedRuleCache()
        let table = [probe]
        benchmark.startMeasurement()
        for _ in 0..<lookupsPerWalk { blackHole(viaIndex(0, table)) }
    }
}
