import Foundation
import Testing

@testable import Swiftiomatic

@Suite("Swift62ModernizationRule — new patterns")
struct Swift62ModernizationTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/Swift62Modernization.swift")
            .path
    }()

    @Test func detectsTupleAsFixedSizeBuffer() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = Swift62ModernizationRule()
        let violations = rule.validate(file: file)

        let tupleFindings = violations.filter { $0.reason.contains("InlineArray") }
        #expect(tupleFindings.count >= 1)
        // Should not flag heterogeneous or small tuples
        #expect(!tupleFindings.contains { $0.reason.contains("Int, String") })
    }

    @Test func detectsMutableStaticVarWithoutIsolation() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = Swift62ModernizationRule()
        let violations = rule.validate(file: file)

        let staticVarFindings = violations.filter { $0.reason.contains("static var") && $0.reason.contains("isolation") }
        #expect(staticVarFindings.count >= 1)
        // Should not flag private static vars
        #expect(!staticVarFindings.contains { $0.reason.contains("PrivateGlobalState") })
    }

    @Test func detectsNonisolatedInMainActorType() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = Swift62ModernizationRule()
        let violations = rule.validate(file: file)

        let nonisolatedFindings = violations.filter { $0.reason.contains("nonisolated") }
        #expect(nonisolatedFindings.count >= 1)
        #expect(nonisolatedFindings.contains { $0.reason.contains("hashValue") })
    }

    @Test func detectsContextParameterThreading() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = Swift62ModernizationRule()
        let violations = rule.validate(file: file)

        let contextFindings = violations.filter { $0.reason.contains("@TaskLocal") }
        #expect(contextFindings.count >= 1)
        #expect(contextFindings.contains { $0.reason.contains("processRequest") })
    }
}
