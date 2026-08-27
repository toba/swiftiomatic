import Testing
import SwiftiomaticTestSupport
@testable import SwiftiomaticKit

@Suite
struct UseAsyncNotCompletionHandlerTests: RuleTesting {
  private static func message(_ name: String) -> String {
    "'\(name)' returns its result through an escaping closure — mark the function 'async' and return the value"
  }

  @Test func trailingCompletionFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func load(id: String, 1️⃣completion: @escaping (Data) -> Void) {
        fetch(id, completion)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("completion"))]
    )
  }

  @Test func completionHandlerLabelFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func load(id: String, 1️⃣completionHandler: @escaping @Sendable (Result<Data, Error>) -> Void) {
        fetch(id, completionHandler)
      }
      """,
      findings: [FindingSpec("1️⃣", message: Self.message("completionHandler"))]
    )
  }

  @Test func asyncFunctionNotFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func load(id: String) async -> Data {
        await fetch(id)
      }
      """,
      findings: []
    )
  }

  @Test func nonVoidReturningClosureNotFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func transform(_ completion: @escaping (Data) -> Data) -> Data {
        completion(base)
      }
      """,
      findings: []
    )
  }

  @Test func otherParameterNameNotFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func observe(_ handler: @escaping (Data) -> Void) {
        store(handler)
      }
      """,
      findings: []
    )
  }

  @Test func nonEscapingCompletionNotFlagged() {
    assertLint(
      UseAsyncNotCompletionHandler.self,
      """
      func withBuffer(completion: (Data) -> Void) {
        completion(base)
      }
      """,
      findings: []
    )
  }
}
