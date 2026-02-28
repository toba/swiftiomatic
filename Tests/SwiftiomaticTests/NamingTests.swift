import Testing
import Foundation
import SwiftParser
import SwiftSyntax
@testable import Swiftiomatic

@Suite("NamingHeuristicsCheck")
struct NamingTests {
    let fixturePath: String = {
        let thisFile = #filePath
        let dir = (thisFile as NSString).deletingLastPathComponent
        return (dir as NSString).appendingPathComponent("Fixtures/Naming.swift")
    }()

    @Test func detectsBoolNotReadingAsAssertion() throws {
        let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
        let tree = Parser.parse(source: source)
        let check = NamingHeuristicsCheck(filePath: fixturePath)
        check.walk(tree)

        let boolFindings = check.findings.filter { $0.message.contains("assertion") }
        // Should flag 'enabled' but not 'isEnabled', 'hasError', 'canEdit'
        #expect(boolFindings.contains { $0.message.contains("'enabled'") })
        #expect(!boolFindings.contains { $0.message.contains("'isEnabled'") })
    }

    @Test func detectsFactoryMethodWithoutMakePrefix() throws {
        let source = try String(contentsOfFile: fixturePath, encoding: .utf8)
        let tree = Parser.parse(source: source)
        let check = NamingHeuristicsCheck(filePath: fixturePath)
        check.walk(tree)

        let factoryFindings = check.findings.filter { $0.message.contains("Factory") }
        #expect(factoryFindings.contains { $0.message.contains("createWidget") })
        #expect(factoryFindings.contains { $0.message.contains("newInstance") })
        #expect(!factoryFindings.contains { $0.message.contains("makeWidget") })
    }
}
