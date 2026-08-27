import XCTest
import SwiftParser
import SwiftSyntax
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

/// Baseline timing for the lint path, and the work-unit counts that size a change to it.
///
/// `LintCoordinator.lint` runs two walks over the file. `RewritePipeline` runs first so the static
/// `willEnter` / `transform` hooks fire and emit their findings, and its mutated tree is discarded.
/// `LintPipeline` walks second for the lint-only rules and the structural-pass rules that keep an
/// instance `visit` override. The tests below time each walk on its own so a change to one is not
/// read off the total.
///
/// Read these in release. A debug build inflates dictionary and existential costs enough to make
/// the dispatch look like a larger share of the walk than it is.
final class LintPipelinePerformanceTests: PerformanceTestCase {
    /// Rule-cache lookups one `LintPipeline` walk performs over the perf-gate file, and the number
    /// of distinct rules it instantiates. Measured 2026-08-27 with a temporary counter in
    /// `LintPipeline.rule(_:)` , which was removed once the numbers were recorded.
    ///
    /// `lookupsPerWalk` is the operation count a typed dispatch table would convert from a
    /// dictionary lookup plus a conditional cast into an array subscript. The two cost tests below
    /// repeat exactly this many operations, so their difference is the whole saving such a table
    /// can produce for this file.
    private static let lookupsPerWalk = 30_062

    /// Distinct rules the walk instantiates, as a band rather than a single number. The observed
    /// count moves between 99 and 100 depending on which tests run before this one, so process
    /// state outside the pipeline reaches rule selection. The band catches real drift in the size
    /// the cost tests are built on without failing on that ordering.
    private static let distinctRulesPerWalk = 95...105

    /// The largest source file in the repository, used as the perf gate by the rewrite tests too.
    private static func layoutCoordinatorSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SwiftiomaticPerformanceTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // repo root
            .appendingPathComponent("Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    private static func perfGateTree() throws -> SourceFileSyntax {
        try Parser.parse(source: layoutCoordinatorSource())
    }

    /// The whole lint path as `sm lint` invokes it: parse, discarded rewrite walk, lint walk.
    func testFullLintOnLayoutCoordinator() throws {
        let source = try Self.layoutCoordinatorSource()
        measureIfNotInCI {
            let coordinator = LintCoordinator(
                configuration: Configuration(), findingConsumer: { _ in })
            try? coordinator.lint(
                source: source, assumingFileURL: URL(fileURLWithPath: "/tmp/perf.swift"))
        }
    }

    /// The `LintPipeline` walk alone, which is where every `rule(_:)` cache lookup happens. Compare
    /// against `testFullLintOnLayoutCoordinator` to see what share of lint time a change to the
    /// lint dispatch can reach at all.
    func testLintPipelineWalkOnLayoutCoordinator() throws {
        let sourceFile = try Self.perfGateTree()
        measureIfNotInCI {
            let context = makeTestContext(
                sourceFileSyntax: sourceFile, selection: .infinite, findingConsumer: { _ in })
            LintPipeline(context: context).walk(Syntax(sourceFile))
        }
    }

    /// Confirms the walk still instantiates the rule count the cost tests are sized against. A
    /// large drift here means `lookupsPerWalk` needs re-measuring before either cost figure is
    /// quoted.
    func testWalkInstantiatesExpectedRuleCount() throws {
        let sourceFile = try Self.perfGateTree()
        let context = makeTestContext(
            sourceFileSyntax: sourceFile, selection: .infinite, findingConsumer: { _ in })
        let pipeline = LintPipeline(context: context)
        pipeline.walk(Syntax(sourceFile))
        XCTAssertTrue(Self.distinctRulesPerWalk.contains(pipeline.ruleCache.count))
    }

    // MARK: - What a typed dispatch table would replace

    @inline(never)
    private func viaDictionary<R: InstanceSyntaxRule>(
        _ type: R.Type,
        _ cache: [ObjectIdentifier: any SyntaxRule]
    ) -> R? { cache[ObjectIdentifier(type)] as? R }

    @inline(never)
    private func viaIndex<R: InstanceSyntaxRule>(_ index: Int, _ table: [R]) -> R { table[index] }

    /// Builds a cache holding the rules a real walk instantiates, so the lookup runs against a
    /// dictionary of the true size and key distribution.
    private func populatedRuleCache() throws -> (
        cache: [ObjectIdentifier: any SyntaxRule], probe: NestingDepth
    ) {
        let sourceFile = try Self.perfGateTree()
        let context = makeTestContext(
            sourceFileSyntax: sourceFile, selection: .infinite, findingConsumer: { _ in })
        let pipeline = LintPipeline(context: context)
        pipeline.walk(Syntax(sourceFile))
        return (pipeline.ruleCache, NestingDepth(context: context))
    }

    /// Current shape: `ObjectIdentifier` construction, dictionary lookup, conditional cast off an
    /// existential, repeated once per rule per node.
    func testRuleLookupViaDictionary() throws {
        let (cache, _) = try populatedRuleCache()
        measureIfNotInCI {
            for _ in 0..<Self.lookupsPerWalk { _ = viaDictionary(NestingDepth.self, cache) }
        }
    }

    /// Proposed shape: an array subscript into a typed table of rule instances.
    func testRuleLookupViaArrayIndex() throws {
        let (_, probe) = try populatedRuleCache()
        let table = [probe]
        measureIfNotInCI { for _ in 0..<Self.lookupsPerWalk { _ = viaIndex(0, table) } }
    }
}
