import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct IdentifierNameRuleTests {
  // MARK: - Excluded names

  @Test func excludedNameDoesNotViolate() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let Apple = 0",
      configuration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  @Test func excludedPatternWithPrefixDoesNotViolate() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let some_apple = 0",
      configuration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  @Test func excludedPatternWithDigitsDoesNotViolate() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let Test123 = 0",
      configuration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  @Test func nonMatchingExcludedPatternStillViolates() async {
    await assertViolates(
      IdentifierNameRule.self,
      "let ap_ple = 0",
      configuration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  @Test func camelCaseVariantOfExcludedNameStillViolates() async {
    await assertViolates(
      IdentifierNameRule.self,
      "let AppleJuice = 0",
      configuration: ["excluded": ["Apple", "some.*", ".*\\d+.*"]])
  }

  // MARK: - Allowed symbols

  @Test func dollarSignAllowedSymbol() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let myLet$ = 0",
      configuration: ["allowed_symbols": ["$", "%", "_"]])
  }

  @Test func percentAllowedSymbol() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let myLet% = 0",
      configuration: ["allowed_symbols": ["$", "%", "_"]])
  }

  @Test func combinedAllowedSymbols() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let myLet$% = 0",
      configuration: ["allowed_symbols": ["$", "%", "_"]])
  }

  @Test func underscoreAsAllowedSymbol() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let _myLet = 0",
      configuration: ["allowed_symbols": ["$", "%", "_"]])
  }

  @Test func underscoreWithAllowedSymbolsStillViolates() async {
    await assertLint(
      IdentifierNameRule.self,
      "let 1️⃣my_Let$ = 0",
      findings: [FindingSpec("1️⃣", message: "Variable name 'my_Let$' should only contain alphanumeric and other allowed characters")],
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  // MARK: - Validates start with lowercase

  @Test func uppercaseStartViolatesWithErrorSeverity() async {
    await assertViolates(
      IdentifierNameRule.self,
      "let MyLet = 0",
      configuration: ["validates_start_with_lowercase": "error"])
  }

  @Test func uppercaseEnumCaseViolatesWithErrorSeverity() async {
    await assertViolates(
      IdentifierNameRule.self,
      "enum Foo { case MyCase }",
      configuration: ["validates_start_with_lowercase": "error"])
  }

  @Test func uppercaseFunctionNameViolatesWithErrorSeverity() async {
    await assertViolates(
      IdentifierNameRule.self,
      "func IsOperator(name: String) -> Bool { true }",
      configuration: ["validates_start_with_lowercase": "error"])
  }

  @Test func uppercaseStartDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let MyLet = 0",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func uppercaseEnumCaseDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "enum Foo { case MyEnum }",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func uppercaseFunctionDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "func IsOperator(name: String) -> Bool",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func staticLetDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "class C { class let MyLet = 0 }",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func staticFuncDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "class C { static func MyFunc() {} }",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func classFuncDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "class C { class func MyFunc() {} }",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func operatorFuncDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "func √ (arg: Double) -> Double { arg }",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  // MARK: - Start with lowercase + allowed symbols combined

  @Test func allowedSymbolBypassesLowercaseCheck() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let MyLet = 0",
      configuration: [
        "validates_start_with_lowercase": "error",
        "allowed_symbols": ["M"],
      ] as [String: any Sendable])
  }

  @Test func nonAllowedSymbolStartStillViolates() async {
    await assertViolates(
      IdentifierNameRule.self,
      "let OneLet = 0",
      configuration: [
        "validates_start_with_lowercase": "error",
        "allowed_symbols": ["M"],
      ] as [String: any Sendable])
  }

  // MARK: - Emoji names

  @Test func emojiIdentifierName() async {
    await assertNoViolation(
      IdentifierNameRule.self,
      "let 👦🏼 = \"👦🏼\"",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  // MARK: - Function name in violation message

  @Test func functionNameInViolationMessage() {
    let example = SwiftSource(contents: "func _abc(arg: String) {}")
    let violations = IdentifierNameRule().validate(file: example)
    #expect(
      violations.map(\.reason) == [
        "Function name '_abc(arg:)' should start with a lowercase character"
      ])
  }
}
