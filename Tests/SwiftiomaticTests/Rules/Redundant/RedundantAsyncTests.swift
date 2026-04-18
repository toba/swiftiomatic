@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantAsyncTests: RuleTesting {
  @Test func asyncWithoutAwait() {
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() 1️⃣async -> Int {
          return 42
        }
        """,
      expected: """
        func foo() -> Int {
          return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'async' but contains no 'await'; consider removing 'async'"),
      ]
    )
  }

  @Test func asyncWithAwaitNotFlagged() {
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() async -> Int {
          return await bar()
        }
        """,
      expected: """
        func foo() async -> Int {
          return await bar()
        }
        """,
      findings: []
    )
  }

  @Test func nonAsyncNotFlagged() {
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() -> Int {
          return 42
        }
        """,
      expected: """
        func foo() -> Int {
          return 42
        }
        """,
      findings: []
    )
  }

  @Test func nestedClosureAwaitNotCounted() {
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() 1️⃣async {
          let closure = {
            await bar()
          }
        }
        """,
      expected: """
        func foo() {
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
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() 1️⃣async {
          func inner() async {
            await bar()
          }
        }
        """,
      expected: """
        func foo() {
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
    assertFormatting(
      RedundantAsync.self,
      input: """
        func foo() async throws -> Int {
          return try await bar()
        }
        """,
      expected: """
        func foo() async throws -> Int {
          return try await bar()
        }
        """,
      findings: []
    )
  }

  @Test func protocolRequirementNotFlagged() {
    assertFormatting(
      RedundantAsync.self,
      input: """
        protocol P {
          func foo() async -> Int
        }
        """,
      expected: """
        protocol P {
          func foo() async -> Int
        }
        """,
      findings: []
    )
  }
}
