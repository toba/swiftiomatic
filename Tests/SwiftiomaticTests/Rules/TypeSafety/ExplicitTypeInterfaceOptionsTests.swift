import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ExplicitTypeInterfaceOptionsTests {
  @Test func defaultConfiguration() {
    let config = ExplicitTypeInterfaceOptions()
    #expect(config.severityConfiguration.severity == .warning)
    #expect(config.allowedKinds == Set([.instance, .class, .static, .local]))
  }

  @Test func applyingCustomConfiguration() throws {
    var config = ExplicitTypeInterfaceOptions()
    try config.apply(
      configuration: [
        "severity": "error",
        "excluded": ["local"],
        "allow_redundancy": true,
      ] as [String: any Sendable],
    )
    #expect(config.severityConfiguration.severity == .error)
    #expect(config.allowedKinds == Set([.instance, .class, .static]))
    #expect(config.allowRedundancy)
  }

  @Test func invalidKeyInCustomConfiguration() async throws {
    let console = try await Console.captureConsole {
      var config = ExplicitTypeInterfaceOptions()
      try config.apply(configuration: ["invalidKey": "error"])
    }
    #expect(
      console
        == "warning: Configuration for 'explicit_type_interface' rule contains the invalid key(s) 'invalidKey'.",
    )
  }

  @Test func invalidTypeOfCustomConfiguration() {
    var config = ExplicitTypeInterfaceOptions()
    checkError(SwiftiomaticError.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier))
    {
      try config.apply(configuration: ["severity": "invalidKey"])
    }
  }

  @Test func invalidTypeOfValueInCustomConfiguration() {
    var config = ExplicitTypeInterfaceOptions()
    checkError(SwiftiomaticError.invalidConfiguration(ruleID: ExplicitTypeInterfaceRule.identifier))
    {
      try config.apply(configuration: ["severity": "foo"])
    }
  }

  @Test func consoleDescription() throws {
    var config = ExplicitTypeInterfaceOptions()
    try config.apply(configuration: ["excluded": ["class", "instance"]])
    #expect(
      RuleOptionsDescription.from(configuration: config).oneLiner()
        == "severity: warning; excluded: [class, instance]; allow_redundancy: false",
    )
  }
}
