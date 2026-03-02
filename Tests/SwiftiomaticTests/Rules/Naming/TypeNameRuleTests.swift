import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TypeNameRuleTests {
  @Test func typeNameWithExcluded() async {
    let baseExamples = TestExamples(from: TypeNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("class apple {}"),
        Example("struct some_apple {}"),
        Example("protocol test123 {}"),
      ]
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("enum ap_ple {}"),
        Example("typealias appleJuice = Void"),
      ]
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )
    await verifyRule(
      description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func typeNameWithAllowedSymbols() async {
    let baseExamples = TestExamples(from: TypeNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("class MyType$ {}"),
        Example("struct MyType$ {}"),
        Example("enum MyType$ {}"),
        Example("typealias Foo$ = Void"),
        Example("protocol Foo {\n associatedtype Bar$\n }"),
      ]

    let description = baseExamples.with(nonTriggeringExamples: nonTriggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$"]])
  }

  @Test func typeNameWithAllowedSymbolsAndViolation() async {
    let triggeringExamples = [
      Example("class ↓My_Type$ {}")
    ]

    let description = TestExamples(from: TypeNameRule.self)
      .with(triggeringExamples: triggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func typeNameWithIgnoreStartWithLowercase() async {
    let baseExamples = TestExamples(from: TypeNameRule.self)
    let triggeringExamplesToRemove = [
      Example("private typealias ↓foo = Void"),
      Example("class ↓myType {}"),
      Example("struct ↓myType {}"),
      Example("enum ↓myType {}"),
    ]
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples
      + triggeringExamplesToRemove
      .removingViolationMarkers()
    let triggeringExamples = baseExamples.triggeringExamples
      .filter { !triggeringExamplesToRemove.contains($0) }

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["validates_start_with_lowercase": "off"])
  }
}
