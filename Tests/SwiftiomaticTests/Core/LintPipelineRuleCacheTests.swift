import Testing
import SwiftParser
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct LintPipelineRuleCacheTests {
    private func makePipeline() -> LintPipeline {
        let syntax = Parser.parse(source: "let a = 1\n")
        let context = makeTestContext(
            sourceFileSyntax: syntax, selection: .infinite, findingConsumer: { _ in })
        return .init(context: context)
    }

    @Test func reusesOneInstancePerRuleType() {
        let pipeline = makePipeline()
        let first = pipeline.rule(NoLeadingUnderscores.self)
        let second = pipeline.rule(NoLeadingUnderscores.self)

        #expect(first === second)
        #expect(pipeline.ruleCache.count == 1)
    }

    @Test func keepsOneEntryPerRuleType() {
        let pipeline = makePipeline()
        let underscores = pipeline.rule(NoLeadingUnderscores.self)
        let redundantOverride = pipeline.rule(DropRedundantOverride.self)

        #expect(pipeline.ruleCache.count == 2)
        #expect(
            pipeline.ruleCache[ObjectIdentifier(NoLeadingUnderscores.self)]
                as? NoLeadingUnderscores === underscores
        )
        #expect(
            pipeline.ruleCache[ObjectIdentifier(DropRedundantOverride.self)]
                as? DropRedundantOverride === redundantOverride
        )
    }

    /// A mismatched cache entry gets replaced instead of trapping.
    ///
    /// The key is `ObjectIdentifier(R.self)` , so a mismatch cannot happen through `rule(_:)` .
    /// This test pins the recovery path that lets the lookup drop its force cast.
    @Test func replacesAnEntryOfTheWrongType() {
        let pipeline = makePipeline()
        let wrongType = DropRedundantOverride(context: pipeline.context)
        pipeline.ruleCache[ObjectIdentifier(NoLeadingUnderscores.self)] = wrongType

        let recovered = pipeline.rule(NoLeadingUnderscores.self)

        #expect(type(of: recovered) == NoLeadingUnderscores.self)
        #expect(
            pipeline.ruleCache[ObjectIdentifier(NoLeadingUnderscores.self)]
                as? NoLeadingUnderscores === recovered
        )
    }
}
