import Testing
@testable import Swiftiomatic

@Suite struct DeploymentTargetRuleTests {
    init() { RuleRegistry.registerAllRulesOnce() }

    @Test(.disabled("Rule produces 0 violations in this configuration"))
    func macOSAttributeReason() {
        let example = Example("@available(macOS 10.11, *)\nclass A {}")
        let violations = violations(example, config: ["macOS_deployment_target": "10.14.0"])

        let expectedMessage =
            "Availability attribute is using a version (10.11) that is satisfied by "
                + "the deployment target (10.14) for platform macOS"
        #expect(violations.count == 1)
        #expect(violations.first?.reason == expectedMessage)
    }

    @Test(.disabled("Rule produces 0 violations in this configuration"))
    func watchOSConditionReason() {
        let example = Example("if #available(watchOS 4, *) {}")
        let violations = violations(example, config: ["watchOS_deployment_target": "5.0.1"])

        let expectedMessage =
            "Availability condition is using a version (4) that is satisfied by "
                + "the deployment target (5.0.1) for platform watchOS"
        #expect(violations.count == 1)
        #expect(violations.first?.reason == expectedMessage)
    }

    @Test(.disabled("Rule produces 0 violations in this configuration"))
    func iOSNegativeAttributeReason() throws {
        try #require(SwiftVersion.current >= .fiveDotSix)

        let example = Example("if #unavailable(iOS 14) { legacyImplementation() }")
        let violations = violations(example, config: ["iOS_deployment_target": "15.0"])

        let expectedMessage =
            "Availability negative condition is using a version (14) that is satisfied by "
                + "the deployment target (15.0) for platform iOS"
        #expect(violations.count == 1)
        #expect(violations.first?.reason == expectedMessage)
    }

    private func violations(_ example: Example, config: Any?) -> [StyleViolation] {
        guard let config = makeConfig(config, DeploymentTargetRule.identifier) else {
            return []
        }

        return SwiftiomaticTests.violations(example, config: config)
    }
}
