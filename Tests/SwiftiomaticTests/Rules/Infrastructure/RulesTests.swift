import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct RulesTests {
  // MARK: - LeadingWhitespaceRule

  @Test func leadingWhitespace_noLeadingWhitespaceDoesNotTrigger() async {
    await assertNoViolation(LeadingWhitespaceRule.self, "//")
  }

  @Test func leadingWhitespace_leadingNewlineViolates() async {
    await assertViolates(LeadingWhitespaceRule.self, "\n//")
  }

  @Test func leadingWhitespace_leadingSpaceViolates() async {
    await assertViolates(LeadingWhitespaceRule.self, " //")
  }

  @Test func leadingWhitespace_correctsLeadingWhitespace() async {
    await assertFormatting(
      LeadingWhitespaceRule.self,
      input: "\n //",
      expected: "//")
  }

  // MARK: - MarkRule

  @Test func mark_correctFormatDoesNotTrigger() async {
    await assertNoViolation(MarkRule.self, "// MARK: good")
  }

  @Test func mark_correctDashFormatDoesNotTrigger() async {
    await assertNoViolation(MarkRule.self, "// MARK: - good")
  }

  @Test func mark_dashOnlyDoesNotTrigger() async {
    await assertNoViolation(MarkRule.self, "// MARK: -")
  }

  @Test func mark_bookmarkDoesNotTrigger() async {
    await assertNoViolation(MarkRule.self, "// BOOKMARK")
  }

  @Test func mark_missingSpaceBeforeMarkViolates() async {
    await assertViolates(MarkRule.self, "//MARK: bad")
  }

  @Test func mark_missingSpaceAfterColonViolates() async {
    await assertViolates(MarkRule.self, "// MARK:bad")
  }

  @Test func mark_extraSpaceBeforeMarkViolates() async {
    await assertViolates(MarkRule.self, "//  MARK: bad")
  }

  @Test func mark_missingSpaceAfterDashViolates() async {
    await assertViolates(MarkRule.self, "// MARK: -bad")
  }

  @Test func mark_lowercaseMarkViolates() async {
    await assertViolates(MarkRule.self, "// Mark: bad")
  }

  @Test func mark_missingColonViolates() async {
    await assertViolates(MarkRule.self, "// MARK bad")
  }

  @Test func mark_tripleSlashMarkViolates() async {
    await assertViolates(MarkRule.self, "/// MARK:")
  }

  @Test func mark_correctsNoSpaceBeforeMark() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣//MARK: comment",
      expected: "// MARK: comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsExtraSpaceAfterColon() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣// MARK:  comment",
      expected: "// MARK: comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsMissingSpaceAfterColon() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣// MARK:comment",
      expected: "// MARK: comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsMissingDashSpace() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣// MARK:- comment",
      expected: "// MARK: - comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsLowercaseMark() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣// Mark: comment",
      expected: "// MARK: comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsMissingColon() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣// MARK - comment",
      expected: "// MARK: - comment",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsTripleSlash() async {
    await assertFormatting(
      MarkRule.self,
      input: "1️⃣/// MARK:",
      expected: "// MARK:",
      findings: [FindingSpec("1️⃣")])
  }

  @Test func mark_correctsMultipleBadMarks() async {
    await assertFormatting(
      MarkRule.self,
      input: """
        1️⃣//MARK:- Top-Level bad mark
        2️⃣//MARK:- Another bad mark
        struct MarkTest {}
        3️⃣// MARK:- Bad mark
        extension MarkTest {}
        """,
      expected: """
        // MARK: - Top-Level bad mark
        // MARK: - Another bad mark
        struct MarkTest {}
        // MARK: - Bad mark
        extension MarkTest {}
        """,
      findings: [
        FindingSpec("1️⃣"),
        FindingSpec("2️⃣"),
        FindingSpec("3️⃣"),
      ])
  }

  // MARK: - RequiredEnumCaseRule

  @Test func requiredEnumCase_conformingEnumWithAllCasesDoesNotTrigger() async {
    await assertNoViolation(
      RequiredEnumCaseRule.self,
      """
      enum MyNetworkResponse: String, NetworkResponsable {
          case success, error, notConnected
      }
      """,
      configuration: ["NetworkResponsable": ["notConnected": "error"]])
  }

  @Test func requiredEnumCase_missingCaseViolates() async {
    await assertViolates(
      RequiredEnumCaseRule.self,
      """
      enum MyNetworkResponse: String, NetworkResponsable {
          case success, error
      }
      """,
      configuration: ["NetworkResponsable": ["notConnected": "error"]])
  }

  // MARK: - TrailingNewlineRule

  @Test func trailingNewline_singleTrailingNewlineDoesNotTrigger() async {
    await assertNoViolation(TrailingNewlineRule.self, "let a = 0\n")
  }

  @Test func trailingNewline_noTrailingNewlineViolates() async {
    await assertViolates(TrailingNewlineRule.self, "let a = 0")
  }

  @Test func trailingNewline_doubleTrailingNewlineViolates() async {
    await assertViolates(TrailingNewlineRule.self, "let a = 0\n\n")
  }

  @Test func trailingNewline_correctsNoTrailingNewline() async {
    await assertFormatting(
      TrailingNewlineRule.self,
      input: "let a = 0",
      expected: "let a = 0\n")
  }

  @Test func trailingNewline_correctsDoubleTrailingNewline() async {
    await assertFormatting(
      TrailingNewlineRule.self,
      input: "let b = 0\n\n",
      expected: "let b = 0\n")
  }

  @Test func trailingNewline_correctsMultipleTrailingNewlines() async {
    await assertFormatting(
      TrailingNewlineRule.self,
      input: "let c = 0\n\n\n\n",
      expected: "let c = 0\n")
  }

  // MARK: - OrphanedDocCommentRule

  @Test func orphanedDocComment_attachedDocCommentDoesNotTrigger() async {
    await assertNoViolation(
      OrphanedDocCommentRule.self,
      """
      /// My great property
      var myGreatProperty: String!
      """)
  }

  @Test func orphanedDocComment_copyrightHeaderDoesNotTrigger() async {
    await assertNoViolation(
      OrphanedDocCommentRule.self,
      """
      //////////////////////////////////////
      //
      // Copyright header.
      //
      //////////////////////////////////////
      """)
  }

  @Test func orphanedDocComment_separatedByRegularCommentViolates() async {
    await assertViolates(
      OrphanedDocCommentRule.self,
      """
      /// My great property
      // Not a doc string
      var myGreatProperty: String!
      """)
  }

  @Test func orphanedDocComment_separatedByBlankLineAndCommentViolates() async {
    await assertViolates(
      OrphanedDocCommentRule.self,
      """
      /// Look here for more info: https://github.com.


      // Not a doc string
      var myGreatProperty: String!
      """)
  }

  @Test func orphanedDocComment_multipleOrphanedDocCommentsViolate() async {
    await assertViolates(
      OrphanedDocCommentRule.self,
      """
      /// Look here for more info: https://github.com.
      // Not a doc string
      /// My great property
      // Not a doc string
      var myGreatProperty: String!
      """)
  }
}
