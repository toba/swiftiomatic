import Foundation
import Testing

@testable import Swiftiomatic

@Suite("GenericConsolidationRule")
struct GenericConsolidationTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/GenericConsolidation.swift")
            .path
    }()

    @Test func detectsAnyProtocolInParameterPosition() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = GenericConsolidationRule()
        let violations = rule.validate(file: file)

        let anyFindings = violations.filter { $0.reason.contains("any") && $0.reason.contains("existential") }
        #expect(anyFindings.count >= 1)
    }

    @Test func doesNotFlagSomeProtocol() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = GenericConsolidationRule()
        let violations = rule.validate(file: file)

        let reasons = violations.map(\.reason)
        #expect(!reasons.contains { $0.contains("some Sequence") && $0.contains("existential") })
    }

    @Test func detectsOverConstrainedCollectionParam() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = GenericConsolidationRule()
        let violations = rule.validate(file: file)

        let overConstrainedFindings = violations.filter { $0.reason.contains("Sequence operations") }
        #expect(overConstrainedFindings.count >= 1)
    }
}
