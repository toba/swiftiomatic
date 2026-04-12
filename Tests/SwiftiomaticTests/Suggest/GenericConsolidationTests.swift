import Foundation
import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

@Suite("GenericConsolidationRule")
struct GenericConsolidationTests {
  @Test func detectsAnyProtocolInParameterPosition() throws {
    let violations = try suggestViolations(
      GenericConsolidationRule(), fixture: "GenericConsolidation")

    let anyFindings = violations.filter {
      $0.reason.contains("any") && $0.reason.contains("existential")
    }
    #expect(anyFindings.count >= 1)
  }

  @Test func doesNotFlagSomeProtocol() throws {
    let violations = try suggestViolations(
      GenericConsolidationRule(), fixture: "GenericConsolidation")

    let reasons = violations.map(\.reason)
    #expect(!reasons.contains { $0.contains("some Sequence") && $0.contains("existential") })
  }

  @Test func detectsOverConstrainedCollectionParam() throws {
    let violations = try suggestViolations(
      GenericConsolidationRule(), fixture: "GenericConsolidation")

    let overConstrainedFindings = violations.filter { $0.reason.contains("Sequence operations") }
    #expect(overConstrainedFindings.count >= 1)
  }
}
