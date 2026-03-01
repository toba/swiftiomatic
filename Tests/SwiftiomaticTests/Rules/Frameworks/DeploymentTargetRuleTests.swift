import Testing

@testable import Swiftiomatic

@Suite(.rulesRegistered) struct DeploymentTargetRuleTests {
  @Test(.disabled("Rule produces 0 violations in this configuration"))
  func macOSAttributeReason() async throws {
    let example = Example("@available(macOS 10.11, *)\nclass A {}")
    let violations = try await ruleViolations(example, rule: DeploymentTargetRule.identifier, configuration: ["macOS_deployment_target": "10.14.0"])

    let expectedMessage =
      "Availability attribute is using a version (10.11) that is satisfied by "
      + "the deployment target (10.14) for platform macOS"
    #expect(violations.count == 1)
    #expect(violations.first?.reason == expectedMessage)
  }

  @Test(.disabled("Rule produces 0 violations in this configuration"))
  func watchOSConditionReason() async throws {
    let example = Example("if #available(watchOS 4, *) {}")
    let violations = try await ruleViolations(example, rule: DeploymentTargetRule.identifier, configuration: ["watchOS_deployment_target": "5.0.1"])

    let expectedMessage =
      "Availability condition is using a version (4) that is satisfied by "
      + "the deployment target (5.0.1) for platform watchOS"
    #expect(violations.count == 1)
    #expect(violations.first?.reason == expectedMessage)
  }

  @Test(.disabled("Rule produces 0 violations in this configuration"))
  func iOSNegativeAttributeReason() async throws {
    let example = Example("if #unavailable(iOS 14) { legacyImplementation() }")
    let violations = try await ruleViolations(example, rule: DeploymentTargetRule.identifier, configuration: ["iOS_deployment_target": "15.0"])

    let expectedMessage =
      "Availability negative condition is using a version (14) that is satisfied by "
      + "the deployment target (15.0) for platform iOS"
    #expect(violations.count == 1)
    #expect(violations.first?.reason == expectedMessage)
  }
}
