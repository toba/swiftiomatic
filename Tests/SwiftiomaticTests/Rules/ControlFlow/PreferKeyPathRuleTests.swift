import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct PreferKeyPathRuleTests {
  private static let extendedMode = ["restrict_to_standard_functions": false]
  private static let ignoreIdentity = ["ignore_identity_closures": true]
  private static let extendedModeAndIgnoreIdentity = [
    "restrict_to_standard_functions": false,
    "ignore_identity_closures": true,
  ]

  @Test func identityExpressionInSwift6() async {
    guard SwiftVersion.current >= .v6 else {
      withKnownIssue("Skipped when Swift version < 6") {}
      return
    }

    let description = TestExamples(from: PreferKeyPathRule.self)
      .with(
        nonTriggeringExamples: [
          Example("f.filter { a in b }"),
          Example("f.g { $1 }", configuration: Self.extendedMode),
          Example("f { $0 }", configuration: Self.extendedModeAndIgnoreIdentity),
          Example("f.map { $0 }", configuration: Self.ignoreIdentity),
        ],
        triggeringExamples: [
          Example("f.compactMap ↓{ $0 }"),
          Example("f.map ↓{ a in a }"),
          Example("f.g { $0 }", configuration: Self.extendedMode),
        ],
        corrections: [
          Example("f.map ↓{ $0 }"):
            Example("f.map(\\.self)"),
          Example("f.g { $0 }", configuration: Self.extendedMode):
            Example("f.g(\\.self)"),
          Example("f { $0 }", configuration: Self.extendedModeAndIgnoreIdentity):
            Example("f { $0 }"),
          Example("f.map { $0 }", configuration: Self.ignoreIdentity):
            Example("f.map { $0 }"),
        ],
      )

    await verifyRule(description)
  }
}

private struct SwiftVersionError: Error {}
