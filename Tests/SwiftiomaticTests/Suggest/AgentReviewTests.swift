import Testing
import Foundation
@testable import Swiftiomatic

@Suite("AgentReview Rules")
struct AgentReviewTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/AgentReview.swift")
            .path
    }()

    @Test func detectsFireAndForgetTask() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = FireAndForgetTaskRule()
        let violations = rule.validate(file: file)

        let fireAndForget = violations.filter { $0.reason.contains("Fire-and-forget") }
        #expect(fireAndForget.count >= 1, "Should detect unassigned Task {}")
    }

    @Test func detectsErrorEnumWithoutLocalizedError() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = AgentReviewRule()
        let violations = rule.validate(file: file)

        let errorFindings = violations.filter { $0.reason.contains("LocalizedError") }
        #expect(errorFindings.count == 1, "Should flag AppError but not GoodError")
        #expect(errorFindings.first?.reason.contains("AppError") == true)
    }

    @Test func detectsNonisolatedUnsafe() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = AgentReviewRule()
        let violations = rule.validate(file: file)

        let nonisolated = violations.filter { $0.reason.contains("nonisolated(unsafe)") }
        #expect(nonisolated.count >= 1)
    }
}
