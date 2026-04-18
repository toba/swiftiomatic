@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantThrowsTests: RuleTesting {
  @Test func throwsWithoutThrow() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        func foo() 1️⃣throws -> Int {
          return 42
        }
        """,
      expected: """
        func foo() -> Int {
          return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }

  @Test func throwsWithThrowNotFlagged() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        func foo() throws -> Int {
          throw MyError.failed
        }
        """,
      expected: """
        func foo() throws -> Int {
          throw MyError.failed
        }
        """,
      findings: []
    )
  }

  @Test func throwsWithTryNotFlagged() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        func foo() throws -> Int {
          return try bar()
        }
        """,
      expected: """
        func foo() throws -> Int {
          return try bar()
        }
        """,
      findings: []
    )
  }

  @Test func nonThrowingNotFlagged() {
    assertFormatting(
      RedundantThrows.self,
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

  @Test func nestedClosureThrowNotCounted() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        func foo() 1️⃣throws {
          let closure = {
            throw MyError.failed
          }
        }
        """,
      expected: """
        func foo() {
          let closure = {
            throw MyError.failed
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }

  @Test func protocolRequirementNotFlagged() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        protocol P {
          func foo() throws -> Int
        }
        """,
      expected: """
        protocol P {
          func foo() throws -> Int
        }
        """,
      findings: []
    )
  }

  @Test func typedThrowsWithoutThrow() {
    assertFormatting(
      RedundantThrows.self,
      input: """
        func foo() 1️⃣throws(MyError) -> Int {
          return 42
        }
        """,
      expected: """
        func foo() -> Int {
          return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }
}
