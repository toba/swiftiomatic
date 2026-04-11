import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct TrailingClosureOptionsTests {
  @Test func defaultConfiguration() {
    let config = TrailingClosureOptions()
    #expect(config.severityConfiguration.severity == .warning)
    #expect(!config.onlySingleMutedParameter)
  }

  @Test func applyingCustomConfiguration() throws {
    var config = TrailingClosureOptions()
    try config.apply(
      configuration: [
        "severity": "error",
        "only_single_muted_parameter": true,
      ] as [String: any Sendable],
    )
    #expect(config.severityConfiguration.severity == .error)
    #expect(config.onlySingleMutedParameter)
  }
}
