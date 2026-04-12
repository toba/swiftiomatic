import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite("CaseIterableUsageRule")
struct CaseIterableUsageTests {
  @Test func detectsCaseIterableWithoutAllCases() throws {
    let violations = try suggestViolations(CaseIterableUsageRule(), fixture: "CaseIterableUsage")

    // Should flag Status (no .allCases reference)
    #expect(violations.contains { $0.reason.contains("Status") })
  }

  @Test func doesNotFlagCaseIterableWithAllCases() throws {
    let violations = try suggestViolations(CaseIterableUsageRule(), fixture: "CaseIterableUsage")

    // Should NOT flag Direction (has .allCases reference)
    #expect(!violations.contains { $0.reason.contains("Direction") })
  }

  @Test func doesNotFlagNonCaseIterableEnums() throws {
    let violations = try suggestViolations(CaseIterableUsageRule(), fixture: "CaseIterableUsage")

    // Should NOT flag Color (not CaseIterable)
    #expect(!violations.contains { $0.reason.contains("Color") })
  }
}
