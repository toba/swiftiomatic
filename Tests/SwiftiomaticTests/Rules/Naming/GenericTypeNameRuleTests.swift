import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct GenericTypeNameRuleTests {
  // MARK: - Excluded names

  @Test func excludedNamesDoNotViolate() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<apple> {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func excludedPatternWithPrefixDoesNotViolate() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<some_apple> {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func excludedPatternWithDigitsDoesNotViolate() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<test123> {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func nonMatchingExcludedPatternStillViolates() async {
    await assertViolates(
      GenericTypeNameRule.self,
      "func foo<ap_ple> {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  @Test func camelCaseVariantOfExcludedNameStillViolates() async {
    await assertViolates(
      GenericTypeNameRule.self,
      "func foo<appleJuice> {}",
      configuration: ["excluded": ["apple", "some.*", ".*st\\d+.*"]])
  }

  // MARK: - Allowed symbols

  @Test func allowedSymbolsInGenericTypeName() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<T$>() {}",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func allowedSymbolsInMultipleGenerics() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<T$, U%>(param: U%) -> T$ {}",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func allowedSymbolsInTypealias() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "typealias StringDictionary<T$> = Dictionary<String, T$>",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func allowedSymbolsCombinedInClass() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "class Foo<T$%> {}",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func allowedSymbolsCombinedInStruct() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "struct Foo<T$%> {}",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func allowedSymbolsCombinedInEnum() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "enum Foo<T$%> {}",
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  @Test func underscoreWithAllowedSymbolsStillViolates() async {
    await assertLint(
      GenericTypeNameRule.self,
      "func foo<1️⃣T_$>() {}",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "Generic type name 'T_$' should only contain alphanumeric and other allowed characters")
      ],
      configuration: ["allowed_symbols": ["$", "%"]])
  }

  // MARK: - Validates start with lowercase

  @Test func lowercaseGenericNameDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "func foo<type>() {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseGenericInClassDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "class Foo<type> {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseGenericInStructDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "struct Foo<type> {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func lowercaseGenericInEnumDoesNotViolateWhenCheckDisabled() async {
    await assertNoViolation(
      GenericTypeNameRule.self,
      "enum Foo<type> {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func underscoreInGenericStillViolatesWhenLowercaseCheckDisabled() async {
    await assertViolates(
      GenericTypeNameRule.self,
      "func foo<T_Foo>() {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }

  @Test func tooLongGenericStillViolatesWhenLowercaseCheckDisabled() async {
    let longName = String(repeating: "T", count: 21)
    await assertViolates(
      GenericTypeNameRule.self,
      "func foo<\(longName)>() {}",
      configuration: ["validates_start_with_lowercase": "off"])
  }
}
