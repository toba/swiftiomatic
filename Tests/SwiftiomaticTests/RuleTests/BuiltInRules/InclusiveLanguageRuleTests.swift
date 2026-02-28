import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct InclusiveLanguageRuleTests {
    @Test func nonTriggeringExamplesWithNonDefaultConfig() async {
        for example in InclusiveLanguageRuleExamples.nonTriggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [example])
                .with(triggeringExamples: [])
            await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }

    @Test func triggeringExamplesWithNonDefaultConfig() async {
        for example in InclusiveLanguageRuleExamples.triggeringExamplesWithConfig {
            let description = InclusiveLanguageRule.description
                .with(nonTriggeringExamples: [])
                .with(triggeringExamples: [example])
            await verifyRule(description, ruleConfiguration: example.configuration)
        }
    }
}
