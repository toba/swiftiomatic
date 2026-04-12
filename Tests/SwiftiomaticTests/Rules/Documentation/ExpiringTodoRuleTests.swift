import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct ExpiringTodoRuleTests {
  // MARK: - Non-triggering

  @Test func notATodoDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "// notaTODO:")
  }

  @Test func notAFixmeDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "// notaFIXME:")
  }

  @Test func todoWithFarFutureDateDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "// TODO: [12/31/9999]")
  }

  @Test func todoWithParenNoteDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "// TODO(note)")
  }

  @Test func fixmeWithParenNoteDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "// FIXME(note)")
  }

  @Test func blockFixmeDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "/* FIXME: */")
  }

  @Test func blockTodoDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "/* TODO: */")
  }

  @Test func docBlockFixmeDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "/** FIXME: */")
  }

  @Test func docBlockTodoDoesNotTrigger() async {
    await assertNoViolation(ExpiringTodoRule.self, "/** TODO: */")
  }

  @Test func nonExpiredTodoDoesNotTrigger() async {
    let date = dateString(for: .badFormatting)
    await assertNoViolation(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [\(date)] Implement")
  }

  // MARK: - Triggering (expired)

  @Test func expiredTodo() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [1️⃣\(date)] Implement",
      findings: [FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")])
  }

  @Test func expiredFixme() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // FIXME: [1️⃣\(date)] Implement",
      findings: [FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")])
  }

  @Test func hardcodedExpiredTodo() async {
    await assertLint(
      ExpiringTodoRule.self,
      "// TODO: [1️⃣10/14/2019]",
      findings: [FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")])
  }

  @Test func hardcodedExpiredFixme() async {
    await assertLint(
      ExpiringTodoRule.self,
      "// FIXME: [1️⃣10/14/2019]",
      findings: [FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")])
  }

  @Test func hardcodedExpiredFixmeShortMonth() async {
    await assertLint(
      ExpiringTodoRule.self,
      "// FIXME: [1️⃣1/14/2019]",
      findings: [FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")])
  }

  // MARK: - Triggering (approaching expiry)

  @Test func approachingExpiryTodo() async {
    let date = dateString(for: .approachingExpiry)
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [1️⃣\(date)] Implement",
      findings: [
        FindingSpec(
          "1️⃣",
          message: "TODO/FIXME is approaching its expiry and should be resolved soon")
      ])
  }

  // MARK: - Triggering (bad formatting)

  @Test func badExpiryTodoFormat() async {
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [1️⃣31/01/2020] Implement",
      findings: [
        FindingSpec("1️⃣", message: "Expiring TODO/FIXME is incorrectly formatted")
      ],
      configuration: ["date_format": "dd/yyyy/MM"])
  }

  @Test func hardcodedBadFormatTodo() async {
    await assertLint(
      ExpiringTodoRule.self,
      "// TODO: [1️⃣9999/14/10]",
      findings: [
        FindingSpec("1️⃣", message: "Expiring TODO/FIXME is incorrectly formatted")
      ])
  }

  // MARK: - Multiple violations

  @Test func multipleExpiredTodos() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      """
      fatalError() // TODO: [1️⃣\(date)] Implement one
      fatalError() // TODO: Implement two by [2️⃣\(date)]
      """,
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved"),
        FindingSpec("2️⃣", message: "TODO/FIXME has expired and must be resolved"),
      ])
  }

  @Test func todoAndExpiredTodo() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      """
      // TODO: Implement one - without deadline
      fatalError()
      // TODO: Implement two by [1️⃣\(date)]
      """,
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ])
  }

  @Test func multilineExpiredTodo() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      """
      // TODO: Multi-line task
      //       for: @MATODOLU
      //       deadline: [1️⃣\(date)]
      //       severity: fatal
      """,
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ])
  }

  @Test func todoFunctionAndExpiredTodo() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      """
      TODO()
      // TODO: Implement two by [1️⃣\(date)]
      """,
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ])
  }

  // MARK: - Custom configuration

  @Test func expiredCustomDelimiters() async {
    let date = dateString(for: .expired)
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: <1️⃣\(date)> Implement",
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ],
      configuration: [
        "date_delimiters": ["opening": "<", "closing": ">"]
      ])
  }

  @Test func expiredCustomSeparator() async {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd-yyyy"
    let date = formatter.string(from: date(for: .expired))
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [1️⃣\(date)] Implement",
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ],
      configuration: [
        "date_format": "MM-dd-yyyy",
        "date_separator": "-",
      ])
  }

  @Test func expiredCustomFormat() async {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    let date = formatter.string(from: date(for: .expired))
    await assertLint(
      ExpiringTodoRule.self,
      "fatalError() // TODO: [1️⃣\(date)] Implement",
      findings: [
        FindingSpec("1️⃣", message: "TODO/FIXME has expired and must be resolved")
      ],
      configuration: ["date_format": "yyyy/MM/dd"])
  }

  // MARK: - Date Helpers

  private func dateString(
    for status: ExpiringTodoRule.ExpiryViolationLevel,
    format: String? = nil
  ) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format ?? ExpiringTodoOptions().dateFormat
    return formatter.string(from: date(for: status))
  }

  private func date(for status: ExpiringTodoRule.ExpiryViolationLevel) -> Date {
    let config = ExpiringTodoRule().options

    let daysToAdvance: Int
    switch status {
    case .approachingExpiry:
      daysToAdvance = config.approachingExpiryThreshold
    case .expired:
      daysToAdvance = 0
    case .badFormatting:
      daysToAdvance = config.approachingExpiryThreshold + 1
    }

    return Calendar.current.date(
      byAdding: .day,
      value: daysToAdvance,
      to: .init()
    )!
  }
}
