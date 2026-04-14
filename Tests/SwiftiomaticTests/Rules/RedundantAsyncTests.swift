@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantAsyncTests: RuleTesting {
  @Test func asyncWithoutAwait() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() 1️⃣async -> Int {
        return 42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'async' but contains no 'await'; consider removing 'async'"),
      ]
    )
  }

  @Test func asyncWithAwaitNotFlagged() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() async -> Int {
        return await bar()
      }
      """,
      findings: []
    )
  }

  @Test func nonAsyncNotFlagged() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() -> Int {
        return 42
      }
      """,
      findings: []
    )
  }

  @Test func nestedClosureAwaitNotCounted() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() 1️⃣async {
        let closure = {
          await bar()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'async' but contains no 'await'; consider removing 'async'"),
      ]
    )
  }

  @Test func nestedFunctionAwaitNotCounted() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() 1️⃣async {
        func inner() async {
          await bar()
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'async' but contains no 'await'; consider removing 'async'"),
      ]
    )
  }

  @Test func asyncThrowsWithAwait() {
    assertLint(
      RedundantAsync.self,
      """
      func foo() async throws -> Int {
        return try await bar()
      }
      """,
      findings: []
    )
  }

  @Test func protocolRequirementNotFlagged() {
    assertLint(
      RedundantAsync.self,
      """
      protocol P {
        func foo() async -> Int
      }
      """,
      findings: []
    )
  }
}
