import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct DiscouragedObjectLiteralRuleTests {
  // MARK: - Non-triggering

  @Test func allowsUIImageInit() async {
    await assertNoViolation(
      DiscouragedObjectLiteralRule.self,
      "let image = UIImage(named: aVariable)")
  }

  @Test func allowsInterpolatedImageName() async {
    await assertNoViolation(
      DiscouragedObjectLiteralRule.self,
      #"let image = UIImage(named: "interpolated \(variable)")"#)
  }

  @Test func allowsUIColorInit() async {
    await assertNoViolation(
      DiscouragedObjectLiteralRule.self,
      "let color = UIColor(red: value, green: value, blue: value, alpha: 1)")
  }

  // MARK: - Triggering (both enabled by default)

  @Test func detectsImageLiteral() async {
    await assertLint(
      DiscouragedObjectLiteralRule.self,
      #"let image = 1️⃣#imageLiteral(resourceName: "image.jpg")"#,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsColorLiteral() async {
    await assertLint(
      DiscouragedObjectLiteralRule.self,
      "let color = 1️⃣#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Image literal only

  @Test func detectsImageLiteralWhenOnlyImageEnabled() async {
    await assertLint(
      DiscouragedObjectLiteralRule.self,
      #"let image = 1️⃣#imageLiteral(resourceName: "image.jpg")"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": true, "color_literal": false])
  }

  @Test func allowsColorLiteralWhenOnlyImageEnabled() async {
    await assertNoViolation(
      DiscouragedObjectLiteralRule.self,
      "let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
      configuration: ["image_literal": true, "color_literal": false])
  }

  // MARK: - Color literal only

  @Test func detectsColorLiteralWhenOnlyColorEnabled() async {
    await assertLint(
      DiscouragedObjectLiteralRule.self,
      "let color = 1️⃣#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func allowsImageLiteralWhenOnlyColorEnabled() async {
    await assertNoViolation(
      DiscouragedObjectLiteralRule.self,
      #"let image = #imageLiteral(resourceName: "image.jpg")"#,
      configuration: ["image_literal": false, "color_literal": true])
  }
}
