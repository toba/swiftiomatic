@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantAsyncTests: RuleTesting {
  @Test func asyncWithoutAwait() {
    assertFormatting(
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
      DropRedundantAsync.self,
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
