import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ObjectLiteralRuleTests {
  // MARK: - Non-triggering

  @Test func allowsImageLiteral() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      #"let image = #imageLiteral(resourceName: "image.jpg")"#)
  }

  @Test func allowsColorLiteral() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      "let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)"
    )
  }

  @Test func allowsVariableImageName() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      "let image = UIImage(named: aVariable)")
  }

  @Test func allowsInterpolatedImageName() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      #"let image = UIImage(named: "interpolated \(variable)")"#)
  }

  @Test func allowsColorWithNonLiteralValues() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      "let color = UIColor(red: value, green: value, blue: value, alpha: 1)")
  }

  // MARK: - Image literal only

  @Test func detectsUIImageNamedInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      #"let image = 1️⃣UIImage(named: "foo")"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": true, "color_literal": false])
  }

  @Test func detectsNSImageNamedInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      #"let image = 1️⃣NSImage(named: "foo")"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": true, "color_literal": false])
  }

  @Test func detectsUIImageDotInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      #"let image = 1️⃣UIImage.init(named: "foo")"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": true, "color_literal": false])
  }

  @Test func detectsNSImageDotInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      #"let image = 1️⃣NSImage.init(named: "foo")"#,
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": true, "color_literal": false])
  }

  @Test func allowsColorInitWhenImageOnly() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      "let color = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
      configuration: ["image_literal": true, "color_literal": false])
  }

  // MARK: - Color literal only

  @Test func detectsUIColorRGBAInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      "let color = 1️⃣UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func detectsNSColorRGBAInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      "let color = 1️⃣NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func detectsUIColorWhiteAlphaInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      "let color = 1️⃣UIColor(white: 0.5, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func detectsUIColorDotInit() async {
    await assertLint(
      ObjectLiteralRule.self,
      "let color = 1️⃣UIColor.init(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func detectsColorWithArithmeticValues() async {
    await assertLint(
      ObjectLiteralRule.self,
      "let color = 1️⃣UIColor(red: 100 / 255.0, green: 50 / 255.0, blue: 0, alpha: 1)",
      findings: [FindingSpec("1️⃣")],
      configuration: ["image_literal": false, "color_literal": true])
  }

  @Test func allowsImageInitWhenColorOnly() async {
    await assertNoViolation(
      ObjectLiteralRule.self,
      #"let image = UIImage(named: "foo")"#,
      configuration: ["image_literal": false, "color_literal": true])
  }

  // MARK: - Both enabled

  @Test func detectsBothImageAndColorInits() async {
    await assertLint(
      ObjectLiteralRule.self,
      """
      let image = 1️⃣UIImage(named: "foo")
      let color = 2️⃣UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
      """,
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")],
      configuration: ["image_literal": true, "color_literal": true])
  }
}
