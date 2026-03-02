import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct DiscouragedDirectInitRuleTests {
  private let baseExamples = TestExamples(from: DiscouragedDirectInitRule.configuration)

  @Test func discouragedDirectInitWithConfiguredSeverity() async {
    await verifyRule(baseExamples, ruleConfiguration: ["severity": "error"])
  }

  @Test func discouragedDirectInitWithNewIncludedTypes() async {
    let triggeringExamples = [
      Example("let foo = ↓Foo()"),
      Example("let bar = ↓Bar()"),
    ]

    let nonTriggeringExamples = [
      Example("let foo = Foo(arg: toto)"),
      Example("let bar = Bar(arg: \"toto\")"),
    ]

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
  }

  @Test func discouragedDirectInitWithReplacedTypes() async {
    let triggeringExamples = [
      Example("let bundle = ↓Bundle()")
    ]

    let nonTriggeringExamples = [
      Example("let device = UIDevice()")
    ]

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
  }
}
