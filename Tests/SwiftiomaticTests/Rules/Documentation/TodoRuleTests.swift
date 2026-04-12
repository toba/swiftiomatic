import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct TodoRuleTests {
  // MARK: - Non-triggering

  @Test func notATodoDoesNotTrigger() async {
    await assertNoViolation(TodoRule.self, "// notaTODO:")
  }

  @Test func notAFixmeDoesNotTrigger() async {
    await assertNoViolation(TodoRule.self, "// notaFIXME:")
  }

  // MARK: - Triggering

  @Test func todoInLineCommentTriggers() async {
    await assertLint(
      TodoRule.self, "// 1️⃣TODO:",
      findings: [FindingSpec("1️⃣", message: "TODOs should be resolved")])
  }

  @Test func fixmeInLineCommentTriggers() async {
    await assertLint(
      TodoRule.self, "// 1️⃣FIXME:",
      findings: [FindingSpec("1️⃣", message: "FIXMEs should be resolved")])
  }

  @Test func todoWithParenNoteTriggers() async {
    await assertViolates(TodoRule.self, "// TODO(note)")
  }

  @Test func fixmeWithParenNoteTriggers() async {
    await assertViolates(TodoRule.self, "// FIXME(note)")
  }

  @Test func fixmeInBlockCommentTriggers() async {
    await assertViolates(TodoRule.self, "/* FIXME: */")
  }

  @Test func todoInBlockCommentTriggers() async {
    await assertViolates(TodoRule.self, "/* TODO: */")
  }

  @Test func fixmeInDocBlockCommentTriggers() async {
    await assertViolates(TodoRule.self, "/** FIXME: */")
  }

  @Test func todoInDocBlockCommentTriggers() async {
    await assertViolates(TodoRule.self, "/** TODO: */")
  }

  // MARK: - Messages

  @Test func todoMessageIncludesDescription() async {
    await assertLint(
      TodoRule.self,
      "fatalError() // 1️⃣TODO: Implement",
      findings: [FindingSpec("1️⃣", message: "TODOs should be resolved (Implement)")])
  }

  @Test func fixmeMessageIncludesDescription() async {
    await assertLint(
      TodoRule.self,
      "fatalError() // 1️⃣FIXME: Implement",
      findings: [FindingSpec("1️⃣", message: "FIXMEs should be resolved (Implement)")])
  }

  // MARK: - Configuration: only

  @Test func onlyFixmeIgnoresTodo() async {
    await assertNoViolation(
      TodoRule.self,
      "fatalError() // TODO: Implement todo",
      configuration: ["only": ["FIXME"]])
  }

  @Test func onlyFixmeReportsFixme() async {
    await assertLint(
      TodoRule.self,
      "fatalError() // 1️⃣FIXME: Implement fixme",
      findings: [
        FindingSpec("1️⃣", message: "FIXMEs should be resolved (Implement fixme)")
      ],
      configuration: ["only": ["FIXME"]])
  }

  @Test func onlyTodoIgnoresFixme() async {
    await assertNoViolation(
      TodoRule.self,
      "fatalError() // FIXME: Implement fixme",
      configuration: ["only": ["TODO"]])
  }

  @Test func onlyTodoReportsTodo() async {
    await assertLint(
      TodoRule.self,
      "fatalError() // 1️⃣TODO: Implement todo",
      findings: [
        FindingSpec("1️⃣", message: "TODOs should be resolved (Implement todo)")
      ],
      configuration: ["only": ["TODO"]])
  }
}
