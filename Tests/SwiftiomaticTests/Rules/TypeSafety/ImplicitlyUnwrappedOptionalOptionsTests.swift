import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct ImplicitlyUnwrappedOptionalOptionsTests {
  @Test func implicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary()
    throws
  {
    var configuration = ImplicitlyUnwrappedOptionalOptions(
      severityConfiguration: SeverityOption(.warning),
      mode: .allExceptIBOutlets,
    )

    try configuration.apply(configuration: ["mode": "all", "severity": "error"])
    #expect(configuration.mode == .all)
    #expect(configuration.severity == .error)

    try configuration.apply(configuration: ["mode": "all_except_iboutlets"])
    #expect(configuration.mode == .allExceptIBOutlets)
    #expect(configuration.severity == .error)

    try configuration.apply(configuration: ["severity": "warning"])
    #expect(configuration.mode == .allExceptIBOutlets)
    #expect(configuration.severity == .warning)

    try configuration.apply(configuration: ["mode": "all", "severity": "warning"])
    #expect(configuration.mode == .all)
    #expect(configuration.severity == .warning)
  }

  @Test func implicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig() {
    let badConfigs: [[String: Any]] = [
      ["mode": "everything"],
      ["mode": false],
      ["mode": 42],
    ]

    for badConfig in badConfigs {
      var configuration = ImplicitlyUnwrappedOptionalOptions(
        severityConfiguration: SeverityOption(.warning),
        mode: .allExceptIBOutlets,
      )

      checkError(
        SwiftiomaticError
          .invalidConfiguration(ruleID: ImplicitlyUnwrappedOptionalRule.identifier)
      ) {
        try configuration.apply(configuration: badConfig)
      }
    }
  }
}
