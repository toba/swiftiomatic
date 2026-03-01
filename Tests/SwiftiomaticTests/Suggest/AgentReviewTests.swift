import Foundation
import Testing

@testable import Swiftiomatic

@Suite("AgentReview Rules")
struct AgentReviewTests {
  @Test func detectsFireAndForgetTask() throws {
    let violations = try suggestViolations(FireAndForgetTaskRule(), fixture: "AgentReview")

    let fireAndForget = violations.filter { $0.reason.contains("Fire-and-forget") }
    #expect(fireAndForget.count >= 1, "Should detect unassigned Task {}")
  }

  @Test func detectsErrorEnumWithoutLocalizedError() throws {
    let violations = try suggestViolations(AgentReviewRule(), fixture: "AgentReview")

    let errorFindings = violations.filter { $0.reason.contains("LocalizedError") }
    #expect(errorFindings.count == 1, "Should flag AppError but not GoodError")
    #expect(errorFindings.first?.reason.contains("AppError") == true)
  }

  @Test func detectsNonisolatedUnsafe() throws {
    let violations = try suggestViolations(AgentReviewRule(), fixture: "AgentReview")

    let nonisolated = violations.filter { $0.reason.contains("nonisolated(unsafe)") }
    #expect(nonisolated.count >= 1)
  }
}
