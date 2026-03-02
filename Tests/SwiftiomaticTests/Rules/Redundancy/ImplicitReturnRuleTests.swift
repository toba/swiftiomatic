import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ImplicitReturnRuleTests {
  @Test func onlyClosureKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRule.nonTriggeringExamples
      + ImplicitReturnRule.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRule.ClosureExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRule.ClosureExamples.triggeringExamples,
      corrections: ImplicitReturnRule.ClosureExamples.corrections,
      kind: .closure,
    )
  }

  @Test func onlyFunctionKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRule.nonTriggeringExamples
      + ImplicitReturnRule.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRule.FunctionExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRule.FunctionExamples.triggeringExamples,
      corrections: ImplicitReturnRule.FunctionExamples.corrections,
      kind: .function,
    )
  }

  @Test func onlyGetterKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRule.nonTriggeringExamples
      + ImplicitReturnRule.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRule.GetterExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRule.GetterExamples.triggeringExamples,
      corrections: ImplicitReturnRule.GetterExamples.corrections,
      kind: .getter,
    )
  }

  @Test func onlyInitializerKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRule.nonTriggeringExamples
      + ImplicitReturnRule.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRule.InitializerExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRule.InitializerExamples.triggeringExamples,
      corrections: ImplicitReturnRule.InitializerExamples.corrections,
      kind: .initializer,
    )
  }

  @Test func onlySubscriptKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRule.nonTriggeringExamples
      + ImplicitReturnRule.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRule.SubscriptExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRule.SubscriptExamples.triggeringExamples,
      corrections: ImplicitReturnRule.SubscriptExamples.corrections,
      kind: .subscript,
    )
  }

  private func verifySubset(
    nonTriggeringExamples: [Example],
    triggeringExamples: [Example],
    corrections: [Example: Example],
    kind: ImplicitReturnOptions.ReturnKind,
  ) async {
    let description = TestExamples(from: ImplicitReturnRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples.removingViolationMarker(),
      triggeringExamples: triggeringExamples,
      corrections: corrections,
    )

    await verifyRule(description, ruleConfiguration: ["included": [kind.rawValue]])
  }
}
