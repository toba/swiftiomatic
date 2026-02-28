import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct CollectionAlignmentRuleTests {
    @Test func collectionAlignmentWithAlignLeft() async {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: false)

        let description = baseDescription.with(
            nonTriggeringExamples: examples.nonTriggeringExamples,
            triggeringExamples: examples.triggeringExamples,
        )

        await verifyRule(description)
    }

    @Test func collectionAlignmentWithAlignColons() async {
        let baseDescription = CollectionAlignmentRule.description
        let examples = CollectionAlignmentRule.Examples(alignColons: true)

        let description = baseDescription.with(
            nonTriggeringExamples: examples.nonTriggeringExamples,
            triggeringExamples: examples.triggeringExamples,
        )

        await verifyRule(description, ruleConfiguration: ["align_colons": true])
    }
}
