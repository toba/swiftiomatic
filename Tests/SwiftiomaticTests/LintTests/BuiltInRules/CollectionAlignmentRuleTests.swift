import Testing

@testable import Swiftiomatic

@Suite struct CollectionAlignmentRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  @Test func collectionAlignmentWithAlignLeft() {
    let baseDescription = CollectionAlignmentRule.description
    let examples = CollectionAlignmentRule.Examples(alignColons: false)

    let description = baseDescription.with(
      nonTriggeringExamples: examples.nonTriggeringExamples,
      triggeringExamples: examples.triggeringExamples)

    verifyRule(description)
  }

  @Test func collectionAlignmentWithAlignColons() {
    let baseDescription = CollectionAlignmentRule.description
    let examples = CollectionAlignmentRule.Examples(alignColons: true)

    let description = baseDescription.with(
      nonTriggeringExamples: examples.nonTriggeringExamples,
      triggeringExamples: examples.triggeringExamples)

    verifyRule(description, ruleConfiguration: ["align_colons": true])
  }
}
