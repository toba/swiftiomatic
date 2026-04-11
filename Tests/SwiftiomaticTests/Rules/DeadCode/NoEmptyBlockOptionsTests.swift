import Testing

@testable import SwiftiomaticKit

@Suite(.rulesRegistered) struct NoEmptyBlockOptionsTests {
  @Test func defaultConfiguration() {
    let config = NoEmptyBlockOptions()
    #expect(config.severityConfiguration.severity == .warning)
    #expect(config.enabledBlockTypes == NoEmptyBlockOptions.CodeBlockType.all)
  }

  @Test func applyingCustomConfiguration() throws {
    var config = NoEmptyBlockOptions()
    try config.apply(
      configuration: [
        "severity": "error",
        "disabled_block_types": ["function_bodies"],
      ] as [String: any Sendable],
    )
    #expect(config.severityConfiguration.severity == .error)
    #expect(
      config.enabledBlockTypes == Set([.initializerBodies, .statementBlocks, .closureBlocks]),
    )
  }

  @Test func invalidKeyInCustomConfiguration() async throws {
    let console = try await Console.captureConsole {
      var config = NoEmptyBlockOptions()
      try config.apply(configuration: ["invalidKey": "error"])
    }
    #expect(
      console
        == "warning: Configuration for 'no_empty_block' rule contains the invalid key(s) 'invalidKey'.",
    )
  }

  @Test func invalidTypeOfCustomConfiguration() {
    var config = NoEmptyBlockOptions()
    checkError(SwiftiomaticError.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
      try config.apply(configuration: ["severity": "invalidKey"])
    }
  }

  @Test func invalidTypeOfValueInCustomConfiguration() {
    var config = NoEmptyBlockOptions()
    checkError(SwiftiomaticError.invalidConfiguration(ruleID: NoEmptyBlockRule.identifier)) {
      try config.apply(configuration: ["severity": "foo"])
    }
  }

  @Test func consoleDescription() throws {
    var config = NoEmptyBlockOptions()
    try config.apply(configuration: [
      "disabled_block_types": ["initializer_bodies", "statement_blocks"]
    ])
    #expect(
      RuleOptionsDescription.from(configuration: config).oneLiner()
        == "severity: warning; disabled_block_types: [initializer_bodies, statement_blocks]",
    )
  }
}
