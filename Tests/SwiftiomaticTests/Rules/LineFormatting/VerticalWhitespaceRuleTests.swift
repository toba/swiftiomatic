import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct VerticalWhitespaceRuleTests {
  // MARK: - Non-triggering (default: max_empty_lines = 1)

  @Test func singleNewlineDoesNotTrigger() async {
    await assertNoViolation(VerticalWhitespaceRule.self, "let abc = 0\n")
  }

  @Test func doubleNewlineDoesNotTrigger() async {
    await assertNoViolation(VerticalWhitespaceRule.self, "let abc = 0\n\n")
  }

  @Test func blockCommentWithNewlinesDoesNotTrigger() async {
    await assertNoViolation(VerticalWhitespaceRule.self, "/* bcs \n\n\n\n*/")
  }

  @Test func commentFollowedByEmptyLineDoesNotTrigger() async {
    await assertNoViolation(VerticalWhitespaceRule.self, "// bca \n\n")
  }

  @Test func classWithSingleEmptyLineDoesNotTrigger() async {
    await assertNoViolation(VerticalWhitespaceRule.self, "class CCCC {\n  \n}")
  }

  @Test func commentBeforeImportDoesNotTrigger() async {
    await assertNoViolation(
      VerticalWhitespaceRule.self,
      """
      // comment

      import Foundation
      """)
  }

  // MARK: - Triggering (default: max_empty_lines = 1)

  @Test func threeNewlinesTriggers() async {
    await assertViolates(VerticalWhitespaceRule.self, "let aaaa = 0\n\n\n")
  }

  @Test func fourNewlinesTriggers() async {
    await assertViolates(VerticalWhitespaceRule.self, "struct AAAA {}\n\n\n\n")
  }

  @Test func classWithTwoEmptyLinesTriggers() async {
    await assertViolates(VerticalWhitespaceRule.self, "class CCCC {\n  \n  \n}")
  }

  @Test func doubleBlankLineBeforeImportTriggers() async {
    await assertViolates(
      VerticalWhitespaceRule.self,
      """


      import Foundation
      """)
  }

  // MARK: - Corrections (default: max_empty_lines = 1)

  @Test func correctsTripleNewlineToDouble() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "let b = 0\n\n\nclass AAA {}\n",
      expected: "let b = 0\n\nclass AAA {}\n")
  }

  @Test func correctsTripleNewlineInVarDeclaration() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "let c = 0\n\n\nlet num = 1\n",
      expected: "let c = 0\n\nlet num = 1\n")
  }

  @Test func correctsTripleNewlineAfterComment() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "// bca \n\n\n",
      expected: "// bca \n\n")
  }

  @Test func correctsMultipleEmptyLinesInClass() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "class CCCC {\n  \n  \n  \n}",
      expected: "class CCCC {\n  \n}")
  }

  // MARK: - max_empty_lines = 2

  @Test func tripleNewlineDoesNotTriggerWithMaxTwo() async {
    await assertNoViolation(
      VerticalWhitespaceRule.self,
      "let aaaa = 0\n\n\n",
      configuration: ["max_empty_lines": 2])
  }

  @Test func quadrupleNewlineTriggersWithMaxTwo() async {
    await assertViolates(
      VerticalWhitespaceRule.self,
      "struct AAAA {}\n\n\n\n",
      configuration: ["max_empty_lines": 2])
  }

  @Test func classWithThreeEmptyLinesTriggersWithMaxTwo() async {
    await assertViolates(
      VerticalWhitespaceRule.self,
      "class BBBB {\n  \n  \n  \n}",
      configuration: ["max_empty_lines": 2])
  }

  // MARK: - Corrections (max_empty_lines = 2)

  @Test func correctsExcessiveNewlinesWithMaxTwo() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "let b = 0\n\n\n\n\n\nclass AAA {}\n",
      expected: "let b = 0\n\n\nclass AAA {}\n",
      configuration: ["max_empty_lines": 2])
  }

  @Test func noChangeNeededWithMaxTwo() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "let b = 0\n\n\nclass AAA {}\n",
      expected: "let b = 0\n\n\nclass AAA {}\n",
      configuration: ["max_empty_lines": 2])
  }

  @Test func correctsClassInternalWhitespaceWithMaxTwo() async {
    await assertFormatting(
      VerticalWhitespaceRule.self,
      input: "class BB {\n  \n  \n  \n  let b = 0\n}\n",
      expected: "class BB {\n  \n  \n  let b = 0\n}\n",
      configuration: ["max_empty_lines": 2])
  }

  // MARK: - Violation messages

  @Test func violationMessageWithMaxTwo() async {
    await assertLint(
      VerticalWhitespaceRule.self,
      "let aaaa = 0\n\n\n1️⃣\nlet bbb = 2\n",
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Limit vertical whitespace to maximum 2 empty lines; currently 3")
      ],
      configuration: ["max_empty_lines": 2])
  }

  @Test func violationMessageWithDefault() async {
    await assertLint(
      VerticalWhitespaceRule.self,
      "let aaaa = 0\n\n1️⃣\n\nlet bbb = 2\n",
      findings: [
        FindingSpec(
          "1️⃣",
          message: "Limit vertical whitespace to a single empty line; currently 3")
      ])
  }
}
