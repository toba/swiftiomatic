import Foundation
import Testing

@testable import SwiftiomaticKit

@Suite("DelegateToAsyncStreamRule")
struct DelegateToAsyncStreamTests {
  @Test func detectsDelegateProtocol() throws {
    let violations = try suggestViolations(
      DelegateToAsyncStreamRule(), fixture: "DelegateToAsyncStream")

    #expect(violations.contains { $0.reason.contains("DownloadDelegate") })
  }

  @Test func detectsObserverProtocol() throws {
    let violations = try suggestViolations(
      DelegateToAsyncStreamRule(), fixture: "DelegateToAsyncStream")

    #expect(violations.contains { $0.reason.contains("StateObserver") })
  }

  @Test func doesNotFlagDataSourceProtocol() throws {
    let violations = try suggestViolations(
      DelegateToAsyncStreamRule(), fixture: "DelegateToAsyncStream")

    // DataSource has return types — not delegate-shaped
    #expect(!violations.contains { $0.reason.contains("DataSource") })
  }

  @Test func doesNotFlagSingleMethodProtocol() throws {
    let violations = try suggestViolations(
      DelegateToAsyncStreamRule(), fixture: "DelegateToAsyncStream")

    // SingleCallback has only one method
    #expect(!violations.contains { $0.reason.contains("SingleCallback") })
  }
}
