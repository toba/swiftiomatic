import Foundation
import Testing

@testable import Swiftiomatic

@Suite("ConcurrencyModernizationRule — new patterns")
struct ConcurrencyModernizationTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/ConcurrencyModernization.swift")
            .path
    }()

    @Test func detectsAsyncStreamMissingFinish() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = ConcurrencyModernizationRule()
        let violations = rule.validate(file: file)

        let finishFindings = violations.filter { $0.reason.contains("continuation.finish()") }
        #expect(finishFindings.count >= 1)
    }

    @Test func detectsAsyncStreamMissingOnTermination() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = ConcurrencyModernizationRule()
        let violations = rule.validate(file: file)

        let termFindings = violations.filter { $0.reason.contains("onTermination") }
        #expect(termFindings.count >= 1)
    }

    @Test func detectsUnnecessaryContinuation() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = ConcurrencyModernizationRule()
        let violations = rule.validate(file: file)

        let contFindings = violations.filter { $0.reason.contains("continuation wrapper") }
        #expect(contFindings.count >= 1)
    }

    @Test func detectsOperationQueue() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = ConcurrencyModernizationRule()
        let violations = rule.validate(file: file)

        let opQueueFindings = violations.filter { $0.reason.contains("OperationQueue") }
        #expect(opQueueFindings.count >= 1)
    }

    @Test func detectsLegacyTimer() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = ConcurrencyModernizationRule()
        let violations = rule.validate(file: file)

        let timerFindings = violations.filter { $0.reason.contains("Timer") || $0.reason.contains("timer") }
        #expect(timerFindings.count >= 1)
    }
}
