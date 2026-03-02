import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct InclusiveLanguageRuleTests {
  @Test func nonTriggeringExamplesWithNonDefaultConfig() async {
    for example in InclusiveLanguageRule.nonTriggeringExamplesWithConfig {
      let description = TestExamples(from: InclusiveLanguageRule.self).with(
        nonTriggeringExamples: [example],
        triggeringExamples: [],
      )
      await verifyRule(description, ruleConfiguration: example.configuration)
    }
  }

  @Test func triggeringExamplesWithNonDefaultConfig() async {
    for example in InclusiveLanguageRule.triggeringExamplesWithConfig {
      let description = TestExamples(from: InclusiveLanguageRule.self).with(
        nonTriggeringExamples: [],
        triggeringExamples: [example],
      )
      await verifyRule(description, ruleConfiguration: example.configuration)
    }
  }
}
