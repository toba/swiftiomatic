import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ImplicitReturnOptionsTests {
  @Test func implicitReturnConfigurationFromDictionary() throws {
    var configuration = ImplicitReturnOptions(
      includedKinds: Set<ImplicitReturnOptions.ReturnKind>(),
    )
    let config: [String: Any] = [
      "severity": "error",
      "included": [
        "closure",
        "function",
        "getter",
        "initializer",
        "subscript",
      ],
    ]

    try configuration.apply(configuration: config)
    let expectedKinds: Set<ImplicitReturnOptions.ReturnKind> = Set([
      .closure,
      .function,
      .getter,
      .initializer,
      .subscript,
    ])
    #expect(configuration.severityConfiguration.severity == .error)
    #expect(configuration.includedKinds == expectedKinds)
  }

  @Test func implicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
    var configuration = ImplicitReturnOptions()
    let config = ["included": ["foreach"]] as [String: any Sendable]

    checkError(SwiftiomaticError.invalidConfiguration(ruleID: ImplicitReturnRule.identifier)) {
      try configuration.apply(configuration: config)
    }
  }
}
