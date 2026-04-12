import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ConditionalReturnsOnNewlineRuleTests {
  // MARK: - Non-triggering (default)

  @Test func guardOnNewlineDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "guard true else {\n return true\n}")
  }

  @Test func guardWithMultipleConditionsDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "guard true,\n let x = true else {\n return true\n}")
  }

  @Test func ifOnNewlineDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "if true else {\n return true\n}")
  }

  @Test func ifWithMultipleConditionsDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "if true,\n let x = true else {\n return true\n}")
  }

  @Test func returnKeywordInIdentifierDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "if textField.returnKeyType == .Next {")
  }

  @Test func commentContainingReturnDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "if true { // return }")
  }

  @Test func guardElseOnSeparateLineDoesNotTrigger() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      """
      guard something
      else { return }
      """)
  }

  // MARK: - Triggering (default)

  @Test func guardSameLineReturnTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣guard true else { return }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifSameLineReturnTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣if true { return }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifElseSameLineReturnTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣if true { break } else { return }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifElseWithSpacesSameLineReturnTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣if true { break } else {       return }",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func ifElseReturnStringTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      #"1️⃣if true { return "YES" } else { return "NO" }"#,
      findings: [FindingSpec("1️⃣")])
  }

  @Test func guardXCTFailSameLineReturnTriggers() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣guard condition else { XCTFail(); return }",
      findings: [FindingSpec("1️⃣")])
  }

  // MARK: - if_only configuration

  @Test func guardSameLineDoesNotTriggerWithIfOnly() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "guard true else { return }",
      configuration: ["if_only": true])
  }

  @Test func ifSameLineReturnTriggersWithIfOnly() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣if true { return }",
      findings: [FindingSpec("1️⃣")],
      configuration: ["if_only": true])
  }

  @Test func ifElseReturnTriggersWithIfOnly() async {
    await assertLint(
      ConditionalReturnsOnNewlineRule.self,
      "1️⃣if true { break } else { return }",
      findings: [FindingSpec("1️⃣")],
      configuration: ["if_only": true])
  }

  @Test func commentInIfDoesNotTriggerWithIfOnly() async {
    await assertNoViolation(
      ConditionalReturnsOnNewlineRule.self,
      "/*if true { */ return }",
      configuration: ["if_only": true])
  }
}
