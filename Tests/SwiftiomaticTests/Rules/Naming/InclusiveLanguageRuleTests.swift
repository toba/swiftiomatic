import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct InclusiveLanguageRuleTests {
  // MARK: - Non-triggering with override_terms config

  @Test func overrideTermsIgnoresDefaultTerms() async {
    await assertNoViolation(
      InclusiveLanguageRule.self,
      """
      let blackList = [
          "foo", "bar"
      ]
      """,
      configuration: ["override_terms": ["abc123"]])
  }

  @Test func overrideAndAdditionalTermsDoNotMatchAbsentTerm() async {
    await assertNoViolation(
      InclusiveLanguageRule.self,
      "private func doThisThing() {}",
      configuration: [
        "override_terms": ["abc123"],
        "additional_terms": ["xyz789"],
      ] as [String: any Sendable])
  }

  // MARK: - Triggering with additional_terms config

  @Test func additionalTermFizzBuzzViolates() async {
    await assertLint(
      InclusiveLanguageRule.self,
      """
      enum Things {
          case foo, 1️⃣fizzBuzz
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "Declaration fizzBuzz contains the term \"fizzbuzz\" which is not considered inclusive")
      ],
      configuration: ["additional_terms": ["fizzbuzz"]])
  }

  @Test func additionalTermSwiftViolatesInFunctionName() async {
    await assertLint(
      InclusiveLanguageRule.self,
      "private func 1️⃣thisIsASwiftyFunction() {}",
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "Declaration thisIsASwiftyFunction contains the term \"swift\" which is not considered inclusive"
        )
      ],
      configuration: ["additional_terms": ["swift"]])
  }

  @Test func additionalTermCaseInsensitiveViolates() async {
    await assertLint(
      InclusiveLanguageRule.self,
      #"private var 1️⃣fooBar = "abc""#,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "Declaration fooBar contains the term \"foobar\" which is not considered inclusive")
      ],
      configuration: ["additional_terms": ["FoObAr"]])
  }
}
