import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct GenericTypeNameRuleTests {
  @Test func genericTypeNameWithExcluded() async {
    let baseExamples = TestExamples(from: GenericTypeNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("func foo<apple> {}"),
        Example("func foo<some_apple> {}"),
        Example("func foo<test123> {}"),
      ]
    let triggeringExamples =
      baseExamples.triggeringExamples + [
        Example("func foo<ap_ple> {}"),
        Example("func foo<appleJuice> {}"),
      ]
    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )
    await verifyRule(
      description, ruleConfiguration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func genericTypeNameWithAllowedSymbols() async {
    let baseExamples = TestExamples(from: GenericTypeNameRule.self)
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + [
        Example("func foo<T$>() {}"),
        Example("func foo<T$, U%>(param: U%) -> T$ {}"),
        Example("typealias StringDictionary<T$> = Dictionary<String, T$>"),
        Example("class Foo<T$%> {}"),
        Example("struct Foo<T$%> {}"),
        Example("enum Foo<T$%> {}"),
      ]

    let description = baseExamples.with(nonTriggeringExamples: nonTriggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func genericTypeNameWithAllowedSymbolsAndViolation() async {
    let triggeringExamples = [
      Example("func foo<↓T_$>() {}")
    ]

    let description = TestExamples(from: GenericTypeNameRule.self)
      .with(triggeringExamples: triggeringExamples)
    await verifyRule(description, ruleConfiguration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func genericTypeNameWithIgnoreStartWithLowercase() async {
    let baseExamples = TestExamples(from: GenericTypeNameRule.self)
    let triggeringExamplesToRemove = [
      Example("func foo<↓type>() {}"),
      Example("class Foo<↓type> {}"),
      Example("struct Foo<↓type> {}"),
      Example("enum Foo<↓type> {}"),
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
