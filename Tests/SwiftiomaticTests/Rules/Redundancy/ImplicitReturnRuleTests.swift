import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ImplicitReturnRuleTests {
  @Test func onlyClosureKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRuleExamples.nonTriggeringExamples
      + ImplicitReturnRuleExamples.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRuleExamples.ClosureExamples.triggeringExamples,
      corrections: ImplicitReturnRuleExamples.ClosureExamples.corrections,
      kind: .closure,
    )
  }

  @Test func onlyFunctionKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRuleExamples.nonTriggeringExamples
      + ImplicitReturnRuleExamples.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRuleExamples.FunctionExamples.triggeringExamples,
      corrections: ImplicitReturnRuleExamples.FunctionExamples.corrections,
      kind: .function,
    )
  }

  @Test func onlyGetterKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRuleExamples.nonTriggeringExamples
      + ImplicitReturnRuleExamples.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRuleExamples.GetterExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRuleExamples.GetterExamples.triggeringExamples,
      corrections: ImplicitReturnRuleExamples.GetterExamples.corrections,
      kind: .getter,
    )
  }

  @Test func onlyInitializerKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRuleExamples.nonTriggeringExamples
      + ImplicitReturnRuleExamples.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRuleExamples.InitializerExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRuleExamples.InitializerExamples.triggeringExamples,
      corrections: ImplicitReturnRuleExamples.InitializerExamples.corrections,
      kind: .initializer,
    )
  }

  @Test func onlySubscriptKindIncluded() async {
    var nonTriggeringExamples =
      ImplicitReturnRuleExamples.nonTriggeringExamples
      + ImplicitReturnRuleExamples.triggeringExamples
    nonTriggeringExamples.removeAll(
      where: ImplicitReturnRuleExamples.SubscriptExamples.triggeringExamples.contains,
    )

    await verifySubset(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: ImplicitReturnRuleExamples.SubscriptExamples.triggeringExamples,
      corrections: ImplicitReturnRuleExamples.SubscriptExamples.corrections,
      kind: .subscript,
    )
  }

  private func verifySubset(
    nonTriggeringExamples: [Example],
    triggeringExamples: [Example],
    corrections: [Example: Example],
    kind: ImplicitReturnOptions.ReturnKind,
  ) async {
    let description = ImplicitReturnRule.description
      .with(nonTriggeringExamples: nonTriggeringExamples.removingViolationMarker())
      .with(triggeringExamples: triggeringExamples)
      .with(corrections: corrections)

    await verifyRule(description, ruleConfiguration: ["included": [kind.rawValue]])
  }
}
