import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct TypesafeArrayInitRuleTests {
    @Test func violationRuleIdentifier() async {
        let baseDescription = TypesafeArrayInitRule.description
        guard let triggeringExample = baseDescription.triggeringExamples.first else {
            Issue.record("No triggering examples found")
            return
        }
        guard let config = makeConfig(nil, baseDescription.identifier) else {
            Issue.record("Failed to create configuration")
            return
        }
        let allViolations = await violations(triggeringExample, config: config, requiresFileOnDisk: true)
        #expect(allViolations.count >= 1)
        #expect(allViolations.first?.ruleIdentifier == baseDescription.identifier)
    }
}
