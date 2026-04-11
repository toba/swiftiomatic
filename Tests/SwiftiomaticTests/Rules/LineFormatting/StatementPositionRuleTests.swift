import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct StatementPositionRuleTests {
  // MARK: - Non-triggering (default / cuddled)

  @Test func elseIfCuddledDoesNotTrigger() async {
    await assertNoViolation(StatementPositionRule.self, "} else if {")
  }

  @Test func elseCuddledDoesNotTrigger() async {
    await assertNoViolation(StatementPositionRule.self, "} else {")
  }

  @Test func catchCuddledDoesNotTrigger() async {
    await assertNoViolation(StatementPositionRule.self, "} catch {")
  }

  @Test func stringLiteralDoesNotTrigger() async {
    await assertNoViolation(StatementPositionRule.self, #""}else{""#)
  }

  @Test func catchphraseStructDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)")
  }

  @Test func backtickCatchStructDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)")
  }

  // MARK: - Triggering (default / cuddled)

  @Test func noSpaceElseIfTriggers() async {
    await assertViolates(StatementPositionRule.self, "}else if {")
  }

  @Test func extraSpaceElseTriggers() async {
    await assertViolates(StatementPositionRule.self, "}  else {")
  }

  @Test func newlineCatchTriggers() async {
    await assertViolates(StatementPositionRule.self, "}\ncatch {")
  }

  @Test func newlineTabCatchTriggers() async {
    await assertViolates(StatementPositionRule.self, "}\n\t  catch {")
  }

  // MARK: - Corrections (default / cuddled)

  @Test func correctsNewlineElse() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "}\n else {",
      expected: "} else {")
  }

  @Test func correctsNewlineElseIf() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "}\n   else if {",
      expected: "} else if {")
  }

  @Test func correctsNewlineCatch() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "}\n catch {",
      expected: "} catch {")
  }

  // MARK: - Uncuddled else

  @Test(.disabled("requires sourcekitd")) func uncuddledElseIfDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "  }\n  else if {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledElseDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "    }\n    else {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledCatchDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "  }\n  catch {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledCatchWithBlankLineDoesNotTrigger() async {
    await assertNoViolation(
      StatementPositionRule.self,
      "  }\n\n  catch {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledElseIfMisalignedTriggers() async {
    await assertViolates(
      StatementPositionRule.self,
      "  }else if {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledElseWrongIndentTriggers() async {
    await assertViolates(
      StatementPositionRule.self,
      "}\n  else {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func uncuddledCatchMisalignedTriggers() async {
    await assertViolates(
      StatementPositionRule.self,
      "  }\ncatch {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func correctsUncuddledElseIfInline() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "  }else if {",
      expected: "  }\n  else if {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func correctsUncuddledElseIndentation() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "}\n  else {",
      expected: "}\nelse {",
      configuration: ["statement_mode": "uncuddled_else"])
  }

  @Test(.disabled("requires sourcekitd")) func correctsUncuddledCatchIndentation() async {
    await assertFormatting(
      StatementPositionRule.self,
      input: "  }\ncatch {",
      expected: "  }\n  catch {",
      configuration: ["statement_mode": "uncuddled_else"])
  }
}
