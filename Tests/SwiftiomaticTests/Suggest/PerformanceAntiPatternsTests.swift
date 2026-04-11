import Foundation
import Testing

@testable import Swiftiomatic

@Suite("PerformanceAntiPatternsRule — new patterns")
struct PerformanceAntiPatternsTests {
  @Test func detectsChainedTransformsWithoutLazy() throws {
    let violations = try suggestViolations(
      PerformanceAntiPatternsRule(), fixture: "PerformanceAntiPatterns")

    expectFindings(violations, containing: "functional transforms")
  }

  @Test func detectsTaskLocalForBusinessState() throws {
    let violations = try suggestViolations(
      PerformanceAntiPatternsRule(), fixture: "PerformanceAntiPatterns")

    let taskLocalFindings = violations.filter {
      $0.reason.contains("@TaskLocal") && $0.reason.contains("business-logic")
    }
    // Should flag currentUser but not requestID/traceID
    #expect(taskLocalFindings.contains { $0.reason.contains("currentUser") })
    #expect(!taskLocalFindings.contains { $0.reason.contains("requestID") })
  }

  @Test func detectsPublicGenericWithoutInlinable() throws {
    let violations = try suggestViolations(
      PerformanceAntiPatternsRule(), fixture: "PerformanceAntiPatterns")

    let inlinableFindings = violations.filter { $0.reason.contains("@inlinable") }
    #expect(inlinableFindings.count >= 1)
    // Should flag transform but not inlinableTransform
    #expect(inlinableFindings.contains { $0.reason.contains("'transform'") })
    #expect(!inlinableFindings.contains { $0.reason.contains("'inlinableTransform'") })
  }

  @Test func detectsCollectionParameterForSpan() throws {
    let violations = try suggestViolations(
      PerformanceAntiPatternsRule(), fixture: "PerformanceAntiPatterns")

    expectFindings(violations, containing: "Span")
  }
}
