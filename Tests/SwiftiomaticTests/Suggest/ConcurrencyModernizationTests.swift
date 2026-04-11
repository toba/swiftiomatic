import Foundation
import Testing

@testable import SwiftiomaticKit

@Suite("ConcurrencyModernizationRule — new patterns")
struct ConcurrencyModernizationTests {
  @Test func detectsAsyncStreamMissingFinish() throws {
    let violations = try suggestViolations(
      AsyncStreamSafetyRule(), fixture: "ConcurrencyModernization")

    expectFindings(violations, containing: "continuation.finish()")
  }

  @Test func detectsAsyncStreamMissingOnTermination() throws {
    let violations = try suggestViolations(
      AsyncStreamSafetyRule(), fixture: "ConcurrencyModernization")

    expectFindings(violations, containing: "onTermination")
  }

  @Test func detectsUnnecessaryContinuation() throws {
    let violations = try suggestViolations(
      ConcurrencyModernizationRule(), fixture: "ConcurrencyModernization")

    expectFindings(violations, containing: "continuation wrapper")
  }

  @Test func detectsOperationQueue() throws {
    let violations = try suggestViolations(
      ConcurrencyModernizationRule(), fixture: "ConcurrencyModernization")

    expectFindings(violations, containing: "OperationQueue")
  }

  @Test func detectsLegacyTimer() throws {
    let violations = try suggestViolations(
      ConcurrencyModernizationRule(), fixture: "ConcurrencyModernization")

    let timerFindings = violations.filter {
      $0.reason.contains("Timer") || $0.reason.contains("timer")
    }
    #expect(timerFindings.count >= 1)
  }
}
