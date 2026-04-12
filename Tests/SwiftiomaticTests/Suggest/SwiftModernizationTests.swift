import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite("SwiftModernizationRule — new patterns")
struct SwiftModernizationTests {
  @Test func detectsTupleAsFixedSizeBuffer() throws {
    let violations = try suggestViolations(
      SwiftModernizationRule(), fixture: "SwiftModernization")

    let tupleFindings = violations.filter { $0.reason.contains("InlineArray") }
    #expect(tupleFindings.count >= 1)
    // Should not flag heterogeneous or small tuples
    #expect(!tupleFindings.contains { $0.reason.contains("Int, String") })
  }

  @Test func detectsMutableStaticVarWithoutIsolation() throws {
    let violations = try suggestViolations(
      SwiftModernizationRule(), fixture: "SwiftModernization")

    let staticVarFindings = violations.filter {
      $0.reason.contains("static var") && $0.reason.contains("isolation")
    }
    #expect(staticVarFindings.count >= 1)
    // Should not flag private static vars
    #expect(!staticVarFindings.contains { $0.reason.contains("PrivateGlobalState") })
  }

  @Test func detectsNonisolatedInMainActorType() throws {
    let violations = try suggestViolations(
      SwiftModernizationRule(), fixture: "SwiftModernization")

    let nonisolatedFindings = violations.filter { $0.reason.contains("nonisolated") }
    #expect(nonisolatedFindings.count >= 1)
    #expect(nonisolatedFindings.contains { $0.reason.contains("hashValue") })
  }

  @Test func detectsWeakVarNotReassigned() throws {
    let violations = try suggestViolations(
      SwiftModernizationRule(), fixture: "SwiftModernization")

    let weakVarFindings = violations.filter {
      $0.reason.contains("weak var") && $0.reason.contains("weak let")
    }
    // Should flag WeakVarHolder.delegate and localWeakVar's ref
    #expect(weakVarFindings.count == 2)
    // Should NOT flag reassigned or observer cases
    #expect(!weakVarFindings.contains { $0.reason.contains("WeakVarReassigned") })
    // All findings should have suggestions
    #expect(weakVarFindings.allSatisfy { $0.suggestion != nil })
  }

  @Test func detectsContextParameterThreading() throws {
    let violations = try suggestViolations(
      SwiftModernizationRule(), fixture: "SwiftModernization")

    let contextFindings = violations.filter { $0.reason.contains("@TaskLocal") }
    #expect(contextFindings.count >= 1)
    #expect(contextFindings.contains { $0.reason.contains("processRequest") })
  }
}
