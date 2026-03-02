import Foundation
import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ExpiringTodoRuleTests {
  @Test func expiringTodo() async {
    await verifyRule(ExpiringTodoRule.self, commentDoesNotViolate: false)
  }

  @Test func expiredTodo() async {
    let example = Example("fatalError() // TODO: [\(dateString(for: .expired))] Implement")
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "TODO/FIXME has expired and must be resolved")
  }

  @Test func expiredFixMe() async {
    let example = Example("fatalError() // FIXME: [\(dateString(for: .expired))] Implement")
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "TODO/FIXME has expired and must be resolved")
  }

  @Test func approachingExpiryTodo() async {
    let example = Example(
      "fatalError() // TODO: [\(dateString(for: .approachingExpiry))] Implement",
    )
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(
      violations.first?
        .reason == "TODO/FIXME is approaching its expiry and should be resolved soon",
    )
  }

  @Test func nonExpiredTodo() async {
    let example =
      Example("fatalError() // TODO: [\(dateString(for: .badFormatting))] Implement")
    #expect(await violations(example).isEmpty)
  }

  @Test func expiredCustomDelimiters() async {
    let ruleConfig = ExpiringTodoOptions(
      dateDelimiters: .init(opening: "<", closing: ">"),
    )
    let example = Example("fatalError() // TODO: <\(dateString(for: .expired))> Implement")
    let violations = await violations(example, ruleConfig)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "TODO/FIXME has expired and must be resolved")
  }

  @Test func expiredCustomSeparator() async {
    let ruleConfig = ExpiringTodoOptions(
      dateFormat: "MM-dd-yyyy",
      dateSeparator: "-",
    )
    let example = Example(
      "fatalError() // TODO: [\(dateString(for: .expired, format: ruleConfig.dateFormat))] Implement",
    )
    let violations = await violations(example, ruleConfig)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "TODO/FIXME has expired and must be resolved")
  }

  @Test func expiredCustomFormat() async {
    let ruleConfig = ExpiringTodoOptions(dateFormat: "yyyy/MM/dd")
    let example = Example(
      "fatalError() // TODO: [\(dateString(for: .expired, format: ruleConfig.dateFormat))] Implement",
    )
    let violations = await violations(example, ruleConfig)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "TODO/FIXME has expired and must be resolved")
  }

  @Test func multipleExpiredTodos() async {
    let example = Example(
      """
      fatalError() // TODO: [\(dateString(for: .expired))] Implement one
      fatalError() // TODO: Implement two by [\(dateString(for: .expired))]
      """,
    )
    let violations = await violations(example)
    #expect(violations.count == 2)
    #expect(violations[0].reason == "TODO/FIXME has expired and must be resolved")
    #expect(violations[0].location.line == 1)
    #expect(violations[1].reason == "TODO/FIXME has expired and must be resolved")
    #expect(violations[1].location.line == 2)
  }

  @Test func todoAndExpiredTodo() async {
    let example = Example(
      """
      // TODO: Implement one - without deadline
      fatalError()
      // TODO: Implement two by [\(dateString(for: .expired))]
      """,
    )
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(violations[0].reason == "TODO/FIXME has expired and must be resolved")
    #expect(violations[0].location.line == 3)
  }

  @Test func multilineExpiredTodo() async {
    let example = Example(
      """
      // TODO: Multi-line task
      //       for: @MATODOLU
      //       deadline: [\(dateString(for: .expired))]
      //       severity: fatal
      """,
    )
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(violations[0].reason == "TODO/FIXME has expired and must be resolved")
    #expect(violations[0].location.line == 3)
  }

  @Test func todoFunctionAndExpiredTodo() async {
    let example = Example(
      """
      TODO()
      // TODO: Implement two by [\(dateString(for: .expired))]
      """,
    )
    let violations = await violations(example)
    #expect(violations.count == 1)
    #expect(violations[0].reason == "TODO/FIXME has expired and must be resolved")
    #expect(violations[0].location.line == 2)
  }

  @Test func badExpiryTodoFormat() async {
    let ruleConfig = ExpiringTodoOptions(
      dateFormat: "dd/yyyy/MM",
    )
    let example = Example("fatalError() // TODO: [31/01/2020] Implement")
    let violations = await violations(example, ruleConfig)
    #expect(violations.count == 1)
    #expect(violations.first?.reason == "Expiring TODO/FIXME is incorrectly formatted")
  }

  private func violations(_ example: Example, _ config: ExpiringTodoOptions? = nil)
    async -> [RuleViolation]
  {
    let config = config ?? ExpiringTodoOptions()
    let serializedConfig =
      [
        "expired_severity": config.expiredSeverity.severity.rawValue,
        "approaching_expiry_severity": config.approachingExpirySeverity.severity.rawValue,
        "bad_formatting_severity": config.badFormattingSeverity.severity.rawValue,
        "approaching_expiry_threshold": config.approachingExpiryThreshold,
        "date_format": config.dateFormat,
        "date_delimiters": [
          "opening": config.dateDelimiters.opening,
          "closing": config.dateDelimiters.closing,
        ],
        "date_separator": config.dateSeparator,
      ] as [String: Any]
    return await SwiftiomaticTests.violations(
      example, config: makeConfig(serializedConfig, ExpiringTodoRule.identifier)!,
    )
  }

  private func dateString(
    for status: ExpiringTodoRule.ExpiryViolationLevel,
    format: String? = nil,
  )
    -> String
  {
    let formatter = DateFormatter()
    formatter.dateFormat = format ?? ExpiringTodoOptions().dateFormat
    return formatter.string(from: date(for: status))
  }

  private func date(for status: ExpiringTodoRule.ExpiryViolationLevel) -> Date {
    let ruleConfiguration = ExpiringTodoRule().options

    let daysToAdvance: Int

    switch status {
    case .approachingExpiry:
      daysToAdvance = ruleConfiguration.approachingExpiryThreshold
    case .expired:
      daysToAdvance = 0
    case .badFormatting:
      daysToAdvance = ruleConfiguration.approachingExpiryThreshold + 1
    }

    return Calendar.current
      .date(
        byAdding: .day,
        value: daysToAdvance,
        to: .init(),
      )!
  }
}
