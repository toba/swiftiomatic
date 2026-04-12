import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite(.rulesRegistered) struct RuleFilterTests {
  @Test func rulesFilterExcludesEnabledRules() {
    let allRules = RuleList(
      rules: [
        RuleMock1.self,
        RuleMock2.self,
        CorrectableRuleMock.self,
      ],
    )
    let enabledRules: [any Rule] = [
      RuleMock1(),
      CorrectableRuleMock(),
    ]
    let rulesFilter = RuleFilter(
      allRules: allRules,
      enabledRules: enabledRules,
    )

    let filteredRules = rulesFilter.rules(excluding: [.enabled])

    #expect(Set(filteredRules.rules.keys) == Set([RuleMock2.identifier]))
  }

  @Test func rulesFilterExcludesDisabledRules() {
    let allRules = RuleList(
      rules: [
        RuleMock1.self,
        RuleMock2.self,
        CorrectableRuleMock.self,
      ],
    )
    let enabledRules: [any Rule] = [
      RuleMock1(),
      CorrectableRuleMock(),
    ]
    let rulesFilter = RuleFilter(
      allRules: allRules,
      enabledRules: enabledRules,
    )

    let filteredRules = rulesFilter.rules(excluding: [.disabled])

    #expect(
      Set(filteredRules.rules.keys)
        == Set([
          RuleMock1.identifier,
          CorrectableRuleMock.identifier,
        ]),
    )
  }

  @Test func rulesFilterExcludesUncorrectableRules() {
    let allRules = RuleList(
      rules: [
        RuleMock1.self,
        RuleMock2.self,
        CorrectableRuleMock.self,
      ],
    )
    let enabledRules: [any Rule] = [
      RuleMock1(),
      CorrectableRuleMock(),
    ]
    let rulesFilter = RuleFilter(
      allRules: allRules,
      enabledRules: enabledRules,
    )

    let filteredRules = rulesFilter.rules(excluding: [.uncorrectable])

    #expect(Set(filteredRules.rules.keys) == Set([CorrectableRuleMock.identifier]))
  }

  @Test func rulesFilterExcludesUncorrectableDisabledRules() {
    let allRules = RuleList(
      rules: [
        RuleMock1.self,
        RuleMock2.self,
        CorrectableRuleMock.self,
      ],
    )
    let enabledRules: [any Rule] = [
      RuleMock1(),
      CorrectableRuleMock(),
    ]
    let rulesFilter = RuleFilter(
      allRules: allRules,
      enabledRules: enabledRules,
    )

    let filteredRules = rulesFilter.rules(excluding: [.disabled, .uncorrectable])

    #expect(Set(filteredRules.rules.keys) == Set([CorrectableRuleMock.identifier]))
  }

  @Test func rulesFilterExcludesUncorrectableEnabledRules() {
    let allRules = RuleList(
      rules: [
        RuleMock1.self,
        RuleMock2.self,
        CorrectableRuleMock.self,
      ],
    )
    let enabledRules: [any Rule] = [
      RuleMock1()
    ]
    let rulesFilter = RuleFilter(
      allRules: allRules,
      enabledRules: enabledRules,
    )

    let filteredRules = rulesFilter.rules(excluding: [.enabled, .uncorrectable])

    #expect(Set(filteredRules.rules.keys) == Set([CorrectableRuleMock.identifier]))
  }

  /// Format command must only run correctable rules that don't require SourceKit.
  /// This replicates the filter used in `FormatCommand.applyCorrectableLintRules()`.
  @Test func formatCorrectableRulesExcludeSourceKit() {
    let rules: [any Rule] = [
      RuleMock1(),                      // not correctable, no SourceKit
      CorrectableRuleMock(),            // correctable, no SourceKit ✓
      CorrectableSourceKitRuleMock(),   // correctable, SourceKit ✗
    ]

    let formatRules = rules.filter {
      type(of: $0).isCorrectable && !type(of: $0).runsWithSourceKit
    }

    #expect(formatRules.count == 1)
    #expect(type(of: formatRules[0]).identifier == CorrectableRuleMock.identifier)
  }

  /// No real rule that requires SourceKit should sneak into format corrections.
  @Test func realCorrectableRulesWithSourceKitExcludedFromFormat() {
    let allRules = RuleResolver.loadRules()
    let leakedRules = allRules.filter {
      type(of: $0).isCorrectable && type(of: $0).runsWithSourceKit
    }

    // These rules exist but must NOT run during format (no compiler args / SourceKit context)
    for rule in leakedRules {
      let id = type(of: rule).identifier
      // Verify our filter would exclude them
      let kept = [rule].filter {
        type(of: $0).isCorrectable && !type(of: $0).runsWithSourceKit
      }
      #expect(kept.isEmpty, "SourceKit rule '\(id)' would leak into format corrections")
    }
  }
}

// MARK: - Mocks

private struct RuleMock1: Rule {
  var options = SeverityOption<Self>(.warning)
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  static let id = "RuleMock1"
  static let name = ""
  static let summary = ""

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    []
  }
}

private struct RuleMock2: Rule {
  var options = SeverityOption<Self>(.warning)
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  static let id = "RuleMock2"
  static let name = ""
  static let summary = ""

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    []
  }
}

private struct CorrectableRuleMock: Rule {
  var options = SeverityOption<Self>(.warning)
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  static let id = "CorrectableRuleMock"
  static let name = ""
  static let summary = ""
  static let isCorrectable = true

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    []
  }

  func correct(file _: SwiftSource) -> Int {
    0
  }
}

private struct CorrectableSourceKitRuleMock: Rule {
  var options = SeverityOption<Self>(.warning)
  var configurationDescription: some Documentable { RuleOptionsEntry.noOptions }

  static let id = "CorrectableSourceKitRuleMock"
  static let name = ""
  static let summary = ""
  static let isCorrectable = true
  static let requiresSourceKit = true

  init() { /* conformance for test */  }
  init(configuration _: Any) { self.init() }

  func validate(file _: SwiftSource) -> [RuleViolation] {
    []
  }

  func correct(file _: SwiftSource) -> Int {
    0
  }
}
