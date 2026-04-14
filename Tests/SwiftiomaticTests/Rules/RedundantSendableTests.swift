@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantSendableTests: RuleTesting {
  @Test func internalStruct() {
    assertLint(
      RedundantSendable.self,
      """
      struct Foo: 1️⃣Sendable {
        let x: Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func internalEnum() {
    assertLint(
      RedundantSendable.self,
      """
      enum Foo: 1️⃣Sendable {
        case a, b
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func publicStructNotFlagged() {
    assertLint(
      RedundantSendable.self,
      """
      public struct Foo: Sendable {
        let x: Int
      }
      """,
      findings: []
    )
  }

  @Test func packageStructNotFlagged() {
    assertLint(
      RedundantSendable.self,
      """
      package struct Foo: Sendable {
        let x: Int
      }
      """,
      findings: []
    )
  }

  @Test func classNotFlagged() {
    assertLint(
      RedundantSendable.self,
      """
      class Foo: Sendable {
        let x: Int
      }
      """,
      findings: []
    )
  }

  @Test func noSendableNotFlagged() {
    assertLint(
      RedundantSendable.self,
      """
      struct Foo: Codable {
        let x: Int
      }
      """,
      findings: []
    )
  }

  @Test func privateStruct() {
    assertLint(
      RedundantSendable.self,
      """
      private struct Foo: 1️⃣Sendable {
        let x: Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }
}
