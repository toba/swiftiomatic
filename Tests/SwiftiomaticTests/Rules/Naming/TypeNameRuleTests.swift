import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct TypeNameRuleTests {
  // MARK: - Excluded names

  @Test func excludedNameDoesNotViolate() async {
    await assertNoViolation(
      TypeNameRule.self,
      "class apple {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func excludedPatternWithPrefixDoesNotViolate() async {
    await assertNoViolation(
      TypeNameRule.self,
      "struct some_apple {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func excludedPatternWithDigitsDoesNotViolate() async {
    await assertNoViolation(
      TypeNameRule.self,
      "protocol test123 {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func nonMatchingExcludedPatternStillViolates() async {
    await assertViolates(
      TypeNameRule.self,
      "enum ap_ple {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func camelCaseVariantOfExcludedNameStillViolates() async {
    await assertViolates(
      TypeNameRule.self,
      "typealias appleJuice = Void",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  // MARK: - Allowed symbols

  @Test func dollarSignAllowedInClassName() async {
    await assertNoViolation(
      TypeNameRule.self,
      "class MyType$ {}",
      configuration: ["allowed_symbols": ["$"]])
  }

  @Test func dollarSignAllowedInStructName() async {
    await assertNoViolation(
      TypeNameRule.self,
      "struct MyType$ {}",
      configuration: ["allowed_symbols": ["$"]])
  }

  @Test func dollarSignAllowedInEnumName() async {
    await assertNoViolation(
      TypeNameRule.self,
      "enum MyType$ {}",
      configuration: ["allowed_symbols": ["$"]])
  }

  @Test func dollarSignAllowedInTypealias() async {
    await assertNoViolation(
      TypeNameRule.self,
      "typealias Foo$ = Void",
      configuration: ["allowed_symbols": ["$"]])
  }

  @Test func dollarSignAllowedInAssociatedType() async {
    await assertNoViolation(
      TypeNameRule.self,
      """
      protocol Foo {
       associatedtype Bar$
       }
      """,
      configuration: ["allowed_symbols": ["$"]])
  }

  @Test func underscoreWithAllowedSymbolsStillViolates() async {
    await assertLint(
      TypeNameRule.self,
      "class 1️⃣My_Type$ {}",
      findings: [FindingSpec("1️⃣", message: "Type name 'My_Type$' should only contain alphanumeric and other allowed characters")],
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  // MARK: - Validates start with lowercase

  @Test func lowercaseTypealiasDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      TypeNameRule.self,
      "private typealias foo = Void",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseClassDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      TypeNameRule.self,
      "class myType {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseStructDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      TypeNameRule.self,
      "struct myType {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseEnumDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      TypeNameRule.self,
      "enum myType {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func underscoreInTypeNameStillViolatesWhenLowercaseCheckDisabled() async {
    await assertViolates(
      TypeNameRule.self,
      "private typealias Foo_Bar = Void",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func tooShortTypeNameStillViolatesWhenLowercaseCheckDisabled() async {
    await assertViolates(
      TypeNameRule.self,
      "struct My {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }
}
