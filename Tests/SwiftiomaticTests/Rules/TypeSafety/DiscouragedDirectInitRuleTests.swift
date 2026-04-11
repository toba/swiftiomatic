import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct DiscouragedDirectInitRuleTests {
  // MARK: - Non-triggering

  @Test func allowsInitWithArguments() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let foo = Bundle(path: \"bar\")")
  }

  @Test func allowsInitIdentifierWithArguments() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let foo = Bundle.init(path: \"bar\")")
  }

  @Test func allowsPropertyAccess() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let foo = UIDevice.current")
  }

  @Test func allowsBundleMain() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let foo = Bundle.main")
  }

  @Test func allowsFunctionNameMatchingType() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "func testNSError()")
  }

  // MARK: - Triggering (default types)

  @Test func detectsUIDeviceInit() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = 1️⃣UIDevice()",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsBundleInit() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = 1️⃣Bundle()",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsNSErrorInit() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = 1️⃣NSError()",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsDotInitVariant() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = 1️⃣Bundle.init()",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func detectsMultipleInitsInOneExpression() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = bar(bundle: 1️⃣Bundle(), device: 2️⃣UIDevice(), error: 3️⃣NSError())",
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
        FindingSpec("3️⃣"),
      ])
  }

  @Test func detectsStandaloneInit() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "1️⃣UIDevice()",
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - Custom severity

  @Test func respectsCustomSeverity() async {
    await assertViolates(
      DiscouragedDirectInitRule.self,
      "let foo = Bundle()",
      configuration: ["severity": "error"])
  }

  // MARK: - Custom types

  @Test func detectsCustomTypes() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let foo = 1️⃣Foo()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["types": ["Foo", "Bar"]])
  }

  @Test func detectsCustomTypeDotInit() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let bar = 1️⃣Bar()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["types": ["Foo", "Bar"]])
  }

  @Test func allowsCustomTypeWithArguments() async {
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let foo = Foo(arg: toto)",
      configuration: ["types": ["Foo", "Bar"]])
  }

  @Test func customTypesReplaceDefaults() async {
    // When custom types are set, the default types are replaced
    await assertNoViolation(
      DiscouragedDirectInitRule.self,
      "let device = UIDevice()",
      configuration: ["types": ["Bundle"]])
  }

  @Test func detectsBundleWithCustomTypesIncludingBundle() async {
    await assertLint(
      DiscouragedDirectInitRule.self,
      "let bundle = 1️⃣Bundle()",
      findings: [FindingSpec("1️⃣")],
      configuration: ["types": ["Bundle"]])
  }
}
