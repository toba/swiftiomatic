import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct PrefixedTopLevelConstantRuleTests {
  @Test func privateOnly() async {
    let triggeringExamples = [
      Example("private let ↓Foo = 20.0"),
      Example("fileprivate let ↓foo = 20.0"),
    ]
    let nonTriggeringExamples = [
      Example("let Foo = 20.0"),
      Example("internal let Foo = \"Foo\""),
      Example("public let Foo = 20.0"),
    ]

    let description = TestExamples(from: PrefixedTopLevelConstantRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["only_private": true])
  }
}
