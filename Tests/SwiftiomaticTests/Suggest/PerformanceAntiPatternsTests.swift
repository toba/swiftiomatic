import Foundation
import Testing

@testable import Swiftiomatic

@Suite("PerformanceAntiPatternsRule — new patterns")
struct PerformanceAntiPatternsTests {
    let fixturePath: String = {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("SuggestFixtures/PerformanceAntiPatterns.swift")
            .path
    }()

    @Test func detectsChainedTransformsWithoutLazy() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = PerformanceAntiPatternsRule()
        let violations = rule.validate(file: file)

        let chainFindings = violations.filter { $0.reason.contains("functional transforms") }
        #expect(chainFindings.count >= 1)
    }

    @Test func detectsTaskLocalForBusinessState() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = PerformanceAntiPatternsRule()
        let violations = rule.validate(file: file)

        let taskLocalFindings = violations.filter { $0.reason.contains("@TaskLocal") && $0.reason.contains("business-logic") }
        // Should flag currentUser but not requestID/traceID
        #expect(taskLocalFindings.contains { $0.reason.contains("currentUser") })
        #expect(!taskLocalFindings.contains { $0.reason.contains("requestID") })
    }

    @Test func detectsPublicGenericWithoutInlinable() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = PerformanceAntiPatternsRule()
        let violations = rule.validate(file: file)

        let inlinableFindings = violations.filter { $0.reason.contains("@inlinable") }
        #expect(inlinableFindings.count >= 1)
        // Should flag transform but not inlinableTransform
        #expect(inlinableFindings.contains { $0.reason.contains("'transform'") })
        #expect(!inlinableFindings.contains { $0.reason.contains("'inlinableTransform'") })
    }

    @Test func detectsCollectionParameterForSpan() throws {
        let file = try #require(SwiftSource(path: fixturePath))
        let rule = PerformanceAntiPatternsRule()
        let violations = rule.validate(file: file)

        let spanFindings = violations.filter { $0.reason.contains("Span") }
        #expect(spanFindings.count >= 1)
    }
}
