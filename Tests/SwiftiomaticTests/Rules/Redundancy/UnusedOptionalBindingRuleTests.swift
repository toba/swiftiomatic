import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct UnusedOptionalBindingRuleTests {
  @Test func defaultConfiguration() async {
    let baseExamples = TestExamples(from: UnusedOptionalBindingRule.self)
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("guard let _ = try? alwaysThrows() else { return }")
      ]

    let description = baseExamples.with(triggeringExamples: triggeringExamples)
    await verifyRule(description)
  }

  @Test func ignoreOptionalTryEnabled() async {
    // Perform additional tests with the ignore_optional_try settings enabled.
    let baseExamples = TestExamples(from: UnusedOptionalBindingRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("guard let _ = try? alwaysThrows() else { return }")
      ]

    let description = baseExamples.with(nonTriggeringExamples: nonTriggeringExamples)
    await verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
  }
}
