import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct EmptyCountRuleTests {
  // MARK: - Non-triggering (default: only_after_dot = false)

  @Test func variableNamedCountDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "var count = 0")
  }

  @Test func isEmptyDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().isEmpty")
  }

  @Test func countGreaterThanOneDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().count > 1")
  }

  @Test func countEqualsOneDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().count == 1")
  }

  @Test func countEqualsHexDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().count == 0xff")
  }

  @Test func countEqualsBinaryDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().count == 0b01")
  }

  @Test func countEqualsOctalDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "[Int]().count == 0o07")
  }

  @Test func localCountDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "func isEmpty(count: Int) -> Bool { count == 0 }")
  }

  @Test func localLetCountDoesNotTrigger() async {
    await assertNoViolation(
      EmptyCountRule.self,
      """
      var isEmpty: Bool {
          let count = 0
          return count == 0
      }
      """
    )
  }

  @Test func closureParameterCountDoesNotTrigger() async {
    await assertNoViolation(EmptyCountRule.self, "{ count in count == 0 }()")
  }

  // MARK: - Triggering (default: only_after_dot = false)

  @Test func countEqualsZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func zeroEqualsCountTriggers() async {
    await assertLint(
      EmptyCountRule.self, "0 == [Int]().1️⃣count",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countEqualsZeroNoSpacesTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count==0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countGreaterThanZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count > 0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countNotEqualsZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count != 0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countEqualsHexZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0x0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countEqualsHexZeroPaddedTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0x00_00",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countEqualsBinaryZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0b00",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countEqualsOctalZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0o00",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func bareCountEqualsZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "1️⃣count == 0",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countInMacroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "#ExampleMacro { $0.list.1️⃣count == 0 }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func countInExtensionIsEmptyTriggers() async {
    await assertLint(
      EmptyCountRule.self,
      """
      extension E {
          var isEmpty: Bool { 1️⃣count == 0 }
      }
      """,
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func multipleViolationsTrigger() async {
    await assertLint(
      EmptyCountRule.self,
      "1️⃣count == 0 && [Int]().2️⃣count == 0o00",
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")]
    )
  }

  // MARK: - Corrections (default: only_after_dot = false)

  @Test func correctsCountEqualsZeroToIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "[].1️⃣count == 0",
      expected: "[].isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsZeroEqualsCountToIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "0 == [].1️⃣count",
      expected: "[].isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsCountNoSpacesToIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "[Int]().1️⃣count==0",
      expected: "[Int]().isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsCountGreaterThanZeroToNotIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "[Int]().1️⃣count > 0",
      expected: "![Int]().isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsCountNotEqualsZeroToNotIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "[Int]().1️⃣count != 0",
      expected: "![Int]().isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsBareCountToIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "1️⃣count == 0",
      expected: "isEmpty",
      findings: [FindingSpec("1️⃣")]
    )
  }

  @Test func correctsMultipleViolations() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "1️⃣count == 0 && [Int]().2️⃣count == 0o00",
      expected: "isEmpty && [Int]().isEmpty",
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")]
    )
  }

  @Test func correctsComplexExpressionWithMixedViolations() async {
    await assertFormatting(
      EmptyCountRule.self,
      input:
        "[Int]().count != 3 && [Int]().1️⃣count != 0 || 2️⃣count == 0 && [Int]().count > 2",
      expected: "[Int]().count != 3 && ![Int]().isEmpty || isEmpty && [Int]().count > 2",
      findings: [FindingSpec("1️⃣"), FindingSpec("2️⃣")]
    )
  }

  @Test func correctsMacroCountToIsEmpty() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "#ExampleMacro { $0.list.1️⃣count == 0 }",
      expected: "#ExampleMacro { $0.list.isEmpty }",
      findings: [FindingSpec("1️⃣")]
    )
  }

  // MARK: - only_after_dot = true

  @Test func onlyAfterDotBareCountDoesNotTrigger() async {
    await assertNoViolation(
      EmptyCountRule.self, "count == 0",
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotDiscountDoesNotTrigger() async {
    await assertNoViolation(
      EmptyCountRule.self, "discount == 0",
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotOrderDiscountDoesNotTrigger() async {
    await assertNoViolation(
      EmptyCountRule.self, "order.discount == 0",
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotTipsRuleDoesNotTrigger() async {
    await assertNoViolation(
      EmptyCountRule.self,
      "let rule = #Rule(Tips.Event(id: \"someTips\")) { $0.donations.isEmpty }",
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotCountEqualsZeroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "[Int]().1️⃣count == 0",
      findings: [FindingSpec("1️⃣")],
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotCountInMacroTriggers() async {
    await assertLint(
      EmptyCountRule.self, "#ExampleMacro { $0.list.1️⃣count == 0 }",
      findings: [FindingSpec("1️⃣")],
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotCorrectsMixedExpression() async {
    await assertFormatting(
      EmptyCountRule.self,
      input: "count == 0 && [Int]().1️⃣count == 0o00",
      expected: "count == 0 && [Int]().isEmpty",
      findings: [FindingSpec("1️⃣")],
      configuration: ["only_after_dot": true]
    )
  }

  @Test func onlyAfterDotCorrectsComplexExpression() async {
    await assertFormatting(
      EmptyCountRule.self,
      input:
        "[Int]().count != 3 && [Int]().1️⃣count != 0 || count == 0 && [Int]().count > 2",
      expected:
        "[Int]().count != 3 && ![Int]().isEmpty || count == 0 && [Int]().count > 2",
      findings: [FindingSpec("1️⃣")],
      configuration: ["only_after_dot": true]
    )
  }
}
