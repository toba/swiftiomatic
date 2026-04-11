import Foundation
import Testing

@testable import SwiftiomaticKit

// NOTE: PerformanceAntiPatternsRule was split into 5 focused rules:
//   - DateForTimingRule (date_for_timing)
//   - LockAntiPatternsRule (lock_anti_patterns)
//   - MutationDuringIterationRule (mutation_during_iteration)
//   - LazyChainRule (lazy_chain)
//   - InlinableGenericRule (inlinable_generic)
//
// @TaskLocal and Span parameter checks were removed — they will be
// added to Swift62ModernizationRule separately.

@Suite("LazyChainRule — chained transforms")
struct LazyChainTests {
  @Test func detectsChainedTransformsWithoutLazy() throws {
    let violations = try suggestViolations(
      LazyChainRule(), fixture: "PerformanceAntiPatterns")

    expectFindings(violations, containing: "functional transforms")
  }
}

@Suite("InlinableGenericRule — public generic without @inlinable")
struct InlinableGenericTests {
  @Test func detectsPublicGenericWithoutInlinable() throws {
    let violations = try suggestViolations(
      InlinableGenericRule(), fixture: "PerformanceAntiPatterns")

    let inlinableFindings = violations.filter { $0.reason.contains("@inlinable") }
    #expect(inlinableFindings.count >= 1)
    // Should flag transform but not inlinableTransform
    #expect(inlinableFindings.contains { $0.reason.contains("'transform'") })
    #expect(!inlinableFindings.contains { $0.reason.contains("'inlinableTransform'") })
  }
}
