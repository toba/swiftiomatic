import Foundation
import Testing

@testable import Swiftiomatic

@Suite("TypedThrowsRule")
struct TypedThrowsTests {
  @Test func detectsUntypedThrowsWithSingleErrorType() throws {
    let violations = try suggestViolations(TypedThrowsRule(), fixture: "TypedThrows")

    // Should find parse() and validate() — both throw only ParseError
    let reasons = violations.map(\.reason)
    #expect(reasons.contains { $0.contains("parse") && $0.contains("ParseError") })
    #expect(reasons.contains { $0.contains("validate") && $0.contains("ParseError") })
  }

  @Test func ignoresAlreadyTypedThrows() throws {
    let violations = try suggestViolations(TypedThrowsRule(), fixture: "TypedThrows")

    let reasons = violations.map(\.reason)
    #expect(!reasons.contains { $0.contains("strictParse") })
  }

  @Test func ignoresMultipleErrorTypes() throws {
    let violations = try suggestViolations(TypedThrowsRule(), fixture: "TypedThrows")

    let reasons = violations.map(\.reason)
    #expect(!reasons.contains { $0.contains("fetchAndParse") })
  }

  @Test func detectsCatchAsPattern() throws {
    let violations = try suggestViolations(TypedThrowsRule(), fixture: "TypedThrows")

    let catchFindings = violations.filter { $0.reason.contains("Catch clause") }
    #expect(catchFindings.count >= 1)
    #expect(catchFindings.contains { $0.reason.contains("ParseError") })
  }

  @Test func detectsResultReturnType() throws {
    let violations = try suggestViolations(TypedThrowsRule(), fixture: "TypedThrows")

    let resultFindings = violations.filter { $0.reason.contains("Result<") }
    #expect(resultFindings.count >= 1)
    #expect(resultFindings.contains { $0.reason.contains("fetchResult") })
    // Should NOT flag Result<T, Error>
    #expect(!resultFindings.contains { $0.reason.contains("fetchAnyResult") })
  }
}
