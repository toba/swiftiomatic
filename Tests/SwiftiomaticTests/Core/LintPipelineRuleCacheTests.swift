import Testing
import SwiftParser
import SwiftSyntax
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

    @Test func storesEachInstanceAtItsRuleIndex() throws {
        let pipeline = makePipeline()
        let underscores = pipeline.rule(NoLeadingUnderscores.self)
        let redundantOverride = pipeline.rule(DropRedundantOverride.self)
        let underscoresIndex = try #require(
            ConfigurationRegistry.ruleIndex(of: NoLeadingUnderscores.self))
        let overrideIndex = try #require(
            ConfigurationRegistry.ruleIndex(of: DropRedundantOverride.self))

        #expect(pipeline.ruleCache.count == 2)
        #expect(pipeline.rules[underscoresIndex] === underscores)
        #expect(pipeline.rules[overrideIndex] === redundantOverride)
    }

    /// Every rule sits at its own index in the registry, so the literal indices in the generated
    /// pipelines name the rule the call site names.
    @Test func ruleIndicesMatchRegistryPositions() {
        for (index, rule) in ConfigurationRegistry.allRuleTypes.enumerated() {
            #expect(ConfigurationRegistry.ruleIndex(of: rule) == index)
            #expect(ConfigurationRegistry.ruleKeys[index] == rule.key)
        }
        #expect(ConfigurationRegistry.allRuleTypes.count == ConfigurationRegistry.ruleCount)
    }

    /// A rule that answers `.skipChildren` skips the node's descendants and resumes after the
    /// walk leaves the node.
    @Test func skipChildrenEndsWhenTheWalkLeavesTheNode() throws {
        let tree = Parser.parse(source: "struct A { struct B {} }\nstruct C {}\n")
        let pipeline = LintPipeline(
            context: makeTestContext(
                sourceFileSyntax: tree, selection: .infinite, findingConsumer: { _ in }))
        let outer = try #require(tree.statements.first?.item.as(StructDeclSyntax.self))
        let index = try #require(ConfigurationRegistry.ruleIndex(of: NoLeadingUnderscores.self))

        pipeline.didVisit(index, outer, .skipChildren)
        #expect(pipeline.skipCount == 1)
        pipeline.endSkip(index, tree)
        #expect(pipeline.skipCount == 1)
        pipeline.endSkip(index, outer)
        #expect(pipeline.skipCount == 0)
        #expect(pipeline.skipUntil[index] == nil)
    }
}
