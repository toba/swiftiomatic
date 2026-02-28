import Testing

@testable import Swiftiomatic

@Suite struct RequiredEnumCaseConfigurationTests {
  init() { RuleRegistry.registerAllRulesOnce() }

  private typealias RuleConfiguration = RequiredEnumCaseConfiguration
  private typealias RequiredCase = RuleConfiguration.RequiredCase

  private static let protocol1 = "RequiredProtocol"
  private static let protocol2 = "NetworkResults"
  private static let protocol3 = "RequiredProtocolWithSeverity"
  private static let rule1 = RuleConfiguration.RequiredCase(name: "success", severity: .warning)
  private static let rule2 = RuleConfiguration.RequiredCase(name: "error", severity: .warning)
  private static let rule3 = RuleConfiguration.RequiredCase(name: "success", severity: .error)

  private static func makeConfig() -> RuleConfiguration {
    var config = RuleConfiguration()
    config.protocols[protocol1] = [rule1, rule2]
    config.protocols[protocol2] = [rule2]
    return config
  }

  @Test func requiredCaseHashValue() {
    let requiredCase = RequiredCase(name: "success")
    #expect(requiredCase.hashValue == RequiredCase(name: "success").hashValue)
  }

  @Test func requiredCaseEquatableReturnsTrue() {
    let lhs = RequiredCase(name: "success")
    let rhs = RequiredCase(name: "success")
    #expect(lhs == rhs)
  }

  @Test func requiredCaseEquatableReturnsFalseBecauseOfDifferentName() {
    let lhs = RequiredCase(name: "success")
    let rhs = RequiredCase(name: "error")
    #expect(lhs != rhs)
  }

  @Test func consoleDescriptionReturnsAllConfiguredProtocols() {
    let config = Self.makeConfig()
    let expected =
      "NetworkResults: error: warning; RequiredProtocol: error: warning, success: warning"
    #expect(config.parameterDescription?.oneLiner() == expected)
  }

  @Test func consoleDescriptionReturnsNoConfiguredProtocols() {
    var config = Self.makeConfig()
    let expected = "{Protocol Name}: {Case Name 1}: {warning|error}, {Case Name 2}: {warning|error}"

    config.protocols.removeAll()
    #expect(config.parameterDescription?.oneLiner() == expected)
  }

  private static func validateRulesExistForProtocol1(in config: RuleConfiguration) {
    #expect(config.protocols[protocol1]?.contains(rule1) ?? false)
    #expect(config.protocols[protocol1]?.contains(rule2) ?? false)
  }

  @Test func registerProtocolCasesRegistersCasesWithSpecifiedSeverity() {
    var config = Self.makeConfig()
    config.register(protocol: Self.protocol3, cases: ["success": "error", "error": "warning"])
    Self.validateRulesExistForProtocol3(in: config)
  }

  private static func validateRulesExistForProtocol3(in config: RuleConfiguration) {
    #expect(config.protocols[protocol3]?.contains(rule3) ?? false)
    #expect(config.protocols[protocol3]?.contains(rule2) ?? false)
  }

  @Test func registerProtocols() {
    var config = Self.makeConfig()
    config.register(protocols: [Self.protocol1: ["success": "warning", "error": "warning"]])
    Self.validateRulesExistForProtocol1(in: config)
  }

  @Test func applyThrowsErrorBecausePassedConfigurationCantBeCast() {
    var config = Self.makeConfig()
    var errorThrown = false

    do {
      try config.apply(configuration: "Howdy")
    } catch {
      errorThrown = true
    }

    #expect(errorThrown)
  }

  @Test func applyRegistersProtocols() {
    var config = Self.makeConfig()
    try? config.apply(configuration: [Self.protocol1: ["success": "warning", "error": "warning"]])
    Self.validateRulesExistForProtocol1(in: config)
  }

  @Test func equalsReturnsTrue() {
    var lhs = RuleConfiguration()
    try? lhs.apply(configuration: [Self.protocol1: ["success", "error"]])

    var rhs = RuleConfiguration()
    try? rhs.apply(configuration: [Self.protocol1: ["success", "error"]])

    #expect(lhs == rhs)
  }

  @Test func equalsReturnsFalseBecauseProtocolsArentEqual() {
    var lhs = RuleConfiguration()
    try? lhs.apply(configuration: [Self.protocol1: ["success": "error"]])

    var rhs = RuleConfiguration()
    try? rhs.apply(configuration: [Self.protocol2: ["success": "error", "error": "warning"]])

    #expect(lhs != rhs)
  }

  @Test func equalsReturnsFalseBecauseSeverityIsntEqual() {
    var lhs = RuleConfiguration()
    try? lhs.apply(configuration: [Self.protocol1: ["success": "error", "error": "error"]])

    var rhs = RuleConfiguration()
    try? rhs.apply(configuration: [Self.protocol1: ["success": "warning", "error": "error"]])

    #expect(lhs != rhs)
  }
}
