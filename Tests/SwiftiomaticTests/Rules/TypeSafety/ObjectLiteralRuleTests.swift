import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ObjectLiteralRuleTests {
  // MARK: - Instance Properties

  private let imageLiteralTriggeringExamples = ["", ".init"].flatMap {
    (method: String) -> [Example] in
    ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
      [
        Example("let image = ↓\(prefix)Image\(method)(named: \"foo\")")
      ]
    }
  }

  private let colorLiteralTriggeringExamples = ["", ".init"].flatMap {
    (method: String) -> [Example] in
    ["UI", "NS"].flatMap { (prefix: String) -> [Example] in
      [
        Example(
          "let color = ↓\(prefix)Color\(method)(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
        ),
        Example(
          "let color = ↓\(prefix)Color\(method)(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)",
        ),
        Example("let color = ↓\(prefix)Color\(method)(white: 0.5, alpha: 1)"),
      ]
    }
  }

  private var allTriggeringExamples: [Example] {
    imageLiteralTriggeringExamples + colorLiteralTriggeringExamples
  }

  // MARK: - Test Methods

  @Test func objectLiteralWithImageLiteral() async {
    // Verify ObjectLiteral rule for when image_literal is true.
    let baseExamples = TestExamples(from: ObjectLiteralRule.self)
    let nonTriggeringColorLiteralExamples =
      colorLiteralTriggeringExamples.removingViolationMarkers()
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + nonTriggeringColorLiteralExamples

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: imageLiteralTriggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["image_literal": true, "color_literal": false])
  }

  @Test func objectLiteralWithColorLiteral() async {
    // Verify ObjectLiteral rule for when color_literal is true.
    let baseExamples = TestExamples(from: ObjectLiteralRule.self)
    let nonTriggeringImageLiteralExamples =
      imageLiteralTriggeringExamples.removingViolationMarkers()
    let nonTriggeringExamples =
      baseExamples.nonTriggeringExamples + nonTriggeringImageLiteralExamples

    let description = baseExamples.with(
      nonTriggeringExamples: nonTriggeringExamples,
      triggeringExamples: colorLiteralTriggeringExamples,
    )

    await verifyRule(
      description, ruleConfiguration: ["image_literal": false, "color_literal": true])
  }

  @Test func objectLiteralWithImageAndColorLiteral() async {
    // Verify ObjectLiteral rule for when image_literal & color_literal are true.
    let description = TestExamples(from: ObjectLiteralRule.self)
      .with(triggeringExamples: allTriggeringExamples)
    await verifyRule(
      description, ruleConfiguration: ["image_literal": true, "color_literal": true])
  }
}
