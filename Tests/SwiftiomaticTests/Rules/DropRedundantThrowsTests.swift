@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantThrowsTests: RuleTesting {
  @Test func throwsWithoutThrow() {
    assertFormatting(
      DropRedundantThrows.self,
      input: """
        private func foo() 1️⃣throws -> Int {
          return 42
        }
        """,
      expected: """
        private func foo() -> Int {
          return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }

  @Test func internalFunctionNotFlagged() {
    // Default access (internal) and explicit `internal`/`public`/`package` functions are skipped:
    // stripping `throws` is source-breaking for callers in other files that wrap calls in `try`.
    assertFormatting(
      DropRedundantThrows.self,
      input: """
        func foo() throws -> Int {
          return 42
        }
        """,
      expected: """
        func foo() throws -> Int {
          return 42
        }
        """,
      findings: []
    )
  }

  @Test func publicFunctionNotFlagged() {
    assertFormatting(
      DropRedundantThrows.self,
      input: """
        public func foo() throws -> Int {
          return 42
        }
        """,
      expected: """
        public func foo() throws -> Int {
          return 42
        }
        """,
      findings: []
    )
  }

  @Test func overrideFunctionNotFlagged() {
    // Override may satisfy a throwing super requirement (`@objc` or otherwise);
    // stripping `throws` makes the override illegal.
    assertFormatting(
      DropRedundantThrows.self,
      input: """
        class C {
          private override func setUp() async throws {
            super.setUp()
          }
        }
        """,
      expected: """
        class C {
          private override func setUp() async throws {
            super.setUp()
          }
        }
        """,
      findings: []
    )
  }

  @Test func throwsWithThrowNotFlagged() {
    assertFormatting(
      DropRedundantThrows.self,
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
      DropRedundantThrows.self,
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
      DropRedundantThrows.self,
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
      DropRedundantThrows.self,
      input: """
        private func foo() 1️⃣throws {
          let closure = {
            throw MyError.failed
          }
        }
        """,
      expected: """
        private func foo() {
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
      DropRedundantThrows.self,
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
      DropRedundantThrows.self,
      input: """
        private func foo() 1️⃣throws(MyError) -> Int {
          return 42
        }
        """,
      expected: """
        private func foo() -> Int {
          return 42
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }
}
