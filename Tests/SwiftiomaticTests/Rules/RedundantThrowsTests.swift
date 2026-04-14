@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantThrowsTests: RuleTesting {
  @Test func throwsWithoutThrow() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() 1️⃣throws -> Int {
        return 42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }

  @Test func throwsWithThrowNotFlagged() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() throws -> Int {
        throw MyError.failed
      }
      """,
      findings: []
    )
  }

  @Test func throwsWithTryNotFlagged() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() throws -> Int {
        return try bar()
      }
      """,
      findings: []
    )
  }

  @Test func nonThrowingNotFlagged() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() -> Int {
        return 42
      }
      """,
      findings: []
    )
  }

  @Test func nestedClosureThrowNotCounted() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() 1️⃣throws {
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
    assertLint(
      RedundantThrows.self,
      """
      protocol P {
        func foo() throws -> Int
      }
      """,
      findings: []
    )
  }

  @Test func typedThrowsWithoutThrow() {
    assertLint(
      RedundantThrows.self,
      """
      func foo() 1️⃣throws(MyError) -> Int {
        return 42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "function is 'throws' but contains no 'throw' or 'try'; consider removing 'throws'"),
      ]
    )
  }
}
