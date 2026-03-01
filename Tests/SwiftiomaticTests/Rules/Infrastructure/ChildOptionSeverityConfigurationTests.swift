import Testing
@testable import Swiftiomatic

@Suite(.rulesRegistered) struct ChildOptionSeverityConfigurationTests {
    typealias TesteeType = ChildOptionSeverityConfiguration<MockRule>

    @Test func severity() {
        #expect(TesteeType.off.severity == nil)
        #expect(TesteeType.warning.severity == .warning)
        #expect(TesteeType.error.severity == .error)
    }

    @Test func fromConfig() throws {
        var testee = TesteeType.off

        try testee.apply(configuration: ["severity": "warning"])
        #expect(testee == .warning)

        try testee.apply(configuration: ["severity": "error"])
        #expect(testee == .error)

        try testee.apply(configuration: ["severity": "off"])
        #expect(testee == .off)
    }

    @Test func invalidConfig() {
        var testee = TesteeType.off

        #expect(throws: (any Error).self) { try testee.apply(configuration: ["severity": "no"]) }
        #expect(throws: (any Error).self) { try testee.apply(configuration: ["severity": 1]) }
    }
}
