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

    @Test func detectsCatchAsPattern() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = TypedThrowsRule()
        let violations = rule.validate(file: file)

        let catchFindings = violations.filter { $0.reason.contains("Catch clause") }
        #expect(catchFindings.count >= 1)
        #expect(catchFindings.contains { $0.reason.contains("ParseError") })
    }

    @Test func detectsResultReturnType() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = TypedThrowsRule()
        let violations = rule.validate(file: file)

        let resultFindings = violations.filter { $0.reason.contains("Result<") }
        #expect(resultFindings.count >= 1)
        #expect(resultFindings.contains { $0.reason.contains("fetchResult") })
        // Should NOT flag Result<T, Error>
        #expect(!resultFindings.contains { $0.reason.contains("fetchAnyResult") })
    }
}
