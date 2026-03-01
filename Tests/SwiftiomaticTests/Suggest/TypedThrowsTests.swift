import Testing
import Foundation
@testable import Swiftiomatic

@Suite("TypedThrowsRule")
struct TypedThrowsTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/TypedThrows.swift")
            .path
    }()

    @Test func detectsUntypedThrowsWithSingleErrorType() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = TypedThrowsRule()
        let violations = rule.validate(file: file)

        // Should find parse() and validate() — both throw only ParseError
        let reasons = violations.map(\.reason)
        #expect(reasons.contains { $0.contains("parse") && $0.contains("ParseError") })
        #expect(reasons.contains { $0.contains("validate") && $0.contains("ParseError") })
    }

    @Test func ignoresAlreadyTypedThrows() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = TypedThrowsRule()
        let violations = rule.validate(file: file)

        let reasons = violations.map(\.reason)
        #expect(!reasons.contains { $0.contains("strictParse") })
    }

    @Test func ignoresMultipleErrorTypes() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = TypedThrowsRule()
        let violations = rule.validate(file: file)

        let reasons = violations.map(\.reason)
        #expect(!reasons.contains { $0.contains("fetchAndParse") })
    }
}
