import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ImplicitlyUnwrappedOptionalRuleTests {
  @Test func implicitlyUnwrappedOptionalRuleDefaultConfiguration() {
    let rule = ImplicitlyUnwrappedOptionalRule()
    #expect(rule.options.mode == .allExceptIBOutlets)
    #expect(rule.options.severity == .warning)
  }

  @Test func implicitlyUnwrappedOptionalRuleWarnsOnOutletsInAllMode() async {
    let triggeringExamples = [
      Example("@IBOutlet private var label: UILabel!"),
      Example("@IBOutlet var label: UILabel!"),
      Example("let int: Int!"),
    ]

    let nonTriggeringExamples = [Example("if !boolean {}")]
    let description = TestExamples(from: ImplicitlyUnwrappedOptionalRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["mode": "all"],
      commentDoesNotViolate: true, stringDoesNotViolate: true,
    )
  }

  @Test func implicitlyUnwrappedOptionalRuleWarnsOnOutletsInWeakMode() async {
    let triggeringExamples = [
      Example("private weak var label: ↓UILabel!"),
      Example("weak var label: ↓UILabel!"),
      Example("@objc weak var label: ↓UILabel!"),
    ]

    let nonTriggeringExamples = [
      Example("@IBOutlet private var label: UILabel!"),
      Example("@IBOutlet var label: UILabel!"),
      Example("@IBOutlet weak var label: UILabel!"),
      Example("var label: UILabel!"),
      Example("let int: Int!"),
    ]

    let description = TestExamples(from: ImplicitlyUnwrappedOptionalRule.self).with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(description, ruleConfiguration: ["mode": "weak_except_iboutlets"])
  }
}
