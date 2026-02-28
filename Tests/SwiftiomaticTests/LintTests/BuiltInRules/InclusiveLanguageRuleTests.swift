import Testing

@testable import Swiftiomatic

@Suite struct InclusiveLanguageRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  @Test func nonTriggeringExamplesWithNonDefaultConfig() {
    InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig.forEach { example in
      let description = InclusiveLanguageRule.description
        .with(nonTriggeringExamples: [example])
        .with(triggeringExamples: [])
      verifyRule(description, ruleConfiguration: example.configuration)
    }
  }

  @Test func triggeringExamplesWithNonDefaultConfig() {
    InclusiveLanguageRuleExamples.triggeringExamplesWithConfig.forEach { example in
      let description = InclusiveLanguageRule.description
        .with(nonTriggeringExamples: [])
        .with(triggeringExamples: [example])
      verifyRule(description, ruleConfiguration: example.configuration)
    }
  }
}
