import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct PrivateOverFilePrivateRuleTests {
  @Test func privateOverFilePrivateValidatingExtensions() async {
    let baseExamples = TestExamples(from: PrivateOverFilePrivateRule.configuration)
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("↓fileprivate extension String {}"),
        Example("↓fileprivate \n extension String {}"),
        Example("↓fileprivate extension \n String {}"),
      ]
    let corrections = [
      Example("↓fileprivate extension String {}"): Example("private extension String {}"),
      Example("↓fileprivate \n extension String {}"): Example(
        "private \n extension String {}",
      ),
      Example("↓fileprivate extension \n String {}"): Example(
        "private extension \n String {}",
      ),
    ]

    let description = baseExamples.with(
      nonTriggeringExamples: [],
      triggeringExamples: triggeringExamples,
      corrections: corrections,
    )
    await verifyRule(description, ruleConfiguration: ["validate_extensions": true])
  }

  @Test func privateOverFilePrivateNotValidatingExtensions() async {
    let baseExamples = TestExamples(from: PrivateOverFilePrivateRule.configuration)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("fileprivate extension String {}")
      ]

    let description = baseExamples.with(nonTriggeringExamples: nonTriggeringExamples)
    await verifyRule(description, ruleConfiguration: ["validate_extensions": false])
  }
}
