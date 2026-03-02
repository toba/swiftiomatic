import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct CollectionAlignmentRuleTests {
  @Test func collectionAlignmentWithAlignLeft() async {
    let examples = CollectionAlignmentRule.Examples(alignColons: false)

    let testExamples = TestExamples(from: CollectionAlignmentRule.self)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples)
  }

  @Test func collectionAlignmentWithAlignColons() async {
    let examples = CollectionAlignmentRule.Examples(alignColons: true)

    let testExamples = TestExamples(from: CollectionAlignmentRule.self)
      .with(
        nonTriggeringExamples: examples.nonTriggeringExamples,
        triggeringExamples: examples.triggeringExamples,
      )

    await verifyRule(testExamples, ruleConfiguration: ["align_colons": true])
  }
}
