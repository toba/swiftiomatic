import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct DiscouragedObjectLiteralRuleTests {
  @Test func withImageLiteral() async {
    let baseDescription = DiscouragedObjectLiteralRule.description
    let nonTriggeringExamples =
      baseDescription.nonTriggeringExamples + [
        Example(
          "let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
        )
      ]
    let triggeringExamples = [
      Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")")
    ]

    let description = baseDescription.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["image_literal": true, "color_literal": false])
  }

  @Test func withColorLiteral() async {
    let baseDescription = DiscouragedObjectLiteralRule.description
    let nonTriggeringExamples =
      baseDescription.nonTriggeringExamples + [
        Example("let image = #imageLiteral(resourceName: \"image.jpg\")")
      ]
    let triggeringExamples = [
      Example(
        "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
      )
    ]

    let description = baseDescription.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: triggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["image_literal": false, "color_literal": true])
  }
}
