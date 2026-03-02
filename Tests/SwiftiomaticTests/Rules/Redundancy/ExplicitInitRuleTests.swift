import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ExplicitInitRuleTests {
  @Test func includeBareInit() async {
    let baseExamples = TestExamples(from: ExplicitInitRule.configuration)
    let nonTriggeringExamples =
      [
        Example("let foo = Foo()"),
        Example("let foo = init()"),
      ] + baseExamples.nonTriggeringExamples

    let triggeringExamples = [
      Example("let foo: Foo = ↓.init()"),
      Example("let foo: [Foo] = [↓.init(), ↓.init()]"),
      Example("foo(↓.init())"),
    ]

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["include_bare_init": true])
  }
}
