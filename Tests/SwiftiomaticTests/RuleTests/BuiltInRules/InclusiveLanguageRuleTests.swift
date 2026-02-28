import Testing
@testable import Swiftiomatic

@Suite struct InclusiveLanguageRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test func nonTriggeringExamplesWithNonDefaultConfig() {
        for example in InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    @Test func triggeringExamplesWithNonDefaultConfig() {
        for example in InclusiveLanguageRuleExamples.triggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
