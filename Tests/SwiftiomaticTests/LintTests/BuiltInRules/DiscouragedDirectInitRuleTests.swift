import Testing

@testable import Swiftiomatic

@Suite struct DiscouragedDirectInitRuleTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  private let baseDescription = DiscouragedDirectInitRule.description

  @Test func discouragedDirectInitWithConfiguredSeverity() {
    verifyRule(baseDescription, ruleConfiguration: ["severity": "error"])
  }

  @Test func discouragedDirectInitWithNewIncludedTypes() {
    let triggeringExamples = [
      Example("let foo = ↓Foo()"),
      Example("let bar = ↓Bar()"),
    ]

    let nonTriggeringExamples = [
      Example("let foo = Foo(arg: toto)"),
      Example("let bar = Bar(arg: \"toto\")"),
    ]

    let description =
      baseDescription
      .with(triggeringExamples: triggeringExamples)
      .with(nonTriggeringExamples: nonTriggeringExamples)

    verifyRule(description, ruleConfiguration: ["types": ["Foo", "Bar"]])
  }

  @Test func discouragedDirectInitWithReplacedTypes() {
    let triggeringExamples = [
      Example("let bundle = ↓Bundle()")
    ]

    let nonTriggeringExamples = [
      Example("let device = UIDevice()")
    ]

    let description =
      baseDescription
      .with(triggeringExamples: triggeringExamples)
      .with(nonTriggeringExamples: nonTriggeringExamples)

    verifyRule(description, ruleConfiguration: ["types": ["Bundle"]])
  }
}
