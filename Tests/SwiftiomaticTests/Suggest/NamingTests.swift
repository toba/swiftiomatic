import Testing
import Foundation
@testable import Swiftiomatic

@Suite("NamingHeuristicsRule")
struct NamingTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Naming.swift")
            .path
    }()

    @Test func detectsBoolNotReadingAsAssertion() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = NamingHeuristicsRule()
        let violations = rule.validate(file: file)

        let boolFindings = violations.filter { $0.reason.contains("assertion") }
        // Should flag 'enabled' but not 'isEnabled', 'hasError', 'canEdit'
        #expect(boolFindings.contains { $0.reason.contains("'enabled'") })
        #expect(!boolFindings.contains { $0.reason.contains("'isEnabled'") })
    }

    @Test func detectsFactoryMethodWithoutMakePrefix() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = NamingHeuristicsRule()
        let violations = rule.validate(file: file)

        let factoryFindings = violations.filter { $0.reason.contains("Factory") }
        #expect(factoryFindings.contains { $0.reason.contains("createWidget") })
        #expect(factoryFindings.contains { $0.reason.contains("newInstance") })
        #expect(!factoryFindings.contains { $0.reason.contains("makeWidget") })
    }
}
