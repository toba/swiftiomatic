import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct AssertionFailuresRuleTests {
  // MARK: - Non-triggering

  @Test func assertTrueDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "assert(true)")
  }

  @Test func assertTrueWithMessageDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, #"assert(true, "message")"#)
  }

  @Test func assertWithExpressionDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "assert(false || true)")
  }

  @Test func assertionFailureDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "assertionFailure()")
  }

  @Test func preconditionFailureDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "preconditionFailure()")
  }

  @Test func xcTestAssertFalseDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "XCTAssert(false)")
  }

  @Test func preconditionWithVariableDoesNotTrigger() async {
    await assertNoViolation(AssertionFailuresRule.self, "precondition(condition)")
  }

  // MARK: - Triggering

  @Test func assertFalseTriggersViolation() async {
    await assertLint(
      AssertionFailuresRule.self, "1️⃣assert(false)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func assertFalseWithMessageTriggersViolation() async {
    await assertLint(
      AssertionFailuresRule.self, #"1️⃣assert(false, "message")"#,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func assertFalseWithExtraArgsTriggersViolation() async {
    await assertLint(
      AssertionFailuresRule.self, #"1️⃣assert(false, "message", 2, 1)"#,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func preconditionFalseTriggersViolation() async {
    await assertLint(
      AssertionFailuresRule.self, "1️⃣precondition(false)",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func preconditionFalseWithMessageTriggersViolation() async {
    await assertLint(
      AssertionFailuresRule.self, #"1️⃣precondition(false, "message")"#,
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - Corrections

  @Test func correctsAssertFalse() async {
    await assertFormatting(
      AssertionFailuresRule.self,
      input: "1️⃣assert(false)",
      expected: "assertionFailure()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsAssertFalseWithMessage() async {
    await assertFormatting(
      AssertionFailuresRule.self,
      input: #"1️⃣assert(false, "message")"#,
      expected: #"assertionFailure("message")"#,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsAssertFalseWithExtraArgs() async {
    await assertFormatting(
      AssertionFailuresRule.self,
      input: #"1️⃣assert(false, "msg", 2, 1)"#,
      expected: #"assertionFailure("msg", 2, 1)"#,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsPreconditionFalse() async {
    await assertFormatting(
      AssertionFailuresRule.self,
      input: "1️⃣precondition(false)",
      expected: "preconditionFailure()",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsPreconditionFalseWithMessage() async {
    await assertFormatting(
      AssertionFailuresRule.self,
      input: #"1️⃣precondition(false, "msg")"#,
      expected: #"preconditionFailure("msg")"#,
      findings: [FindingSpec("1️⃣")]
    )
  }
}
