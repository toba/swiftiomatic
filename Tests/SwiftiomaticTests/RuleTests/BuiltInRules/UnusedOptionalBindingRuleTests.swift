import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct UnusedOptionalBindingRuleTests {
    @Test func defaultConfiguration() async {
        let baseDescription = UnusedOptionalBindingRule.description
        let triggeringExamples =
            baseDescription.triggeringExamples + [
                Example("guard let _ = try? alwaysThrows() else { return }"),
            ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        await verifyRule(description)
    }

    @Test func ignoreOptionalTryEnabled() async {
        // Perform additional tests with the ignore_optional_try settings enabled.
        let baseDescription = UnusedOptionalBindingRule.description
        let nonTriggeringExamples =
            baseDescription.nonTriggeringExamples + [
                Example("guard let _ = try? alwaysThrows() else { return }"),
            ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        await verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
    }
}
