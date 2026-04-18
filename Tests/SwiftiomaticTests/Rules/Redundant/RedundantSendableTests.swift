@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantSendableTests: RuleTesting {
  @Test func internalStruct() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        struct Foo: 1️⃣Sendable {
          let x: Int
        }
        """,
      expected: """
        struct Foo {
          let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func internalEnum() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        enum Foo: 1️⃣Sendable {
          case a, b
        }
        """,
      expected: """
        enum Foo {
          case a, b
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func publicStructNotFlagged() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        public struct Foo: Sendable {
          let x: Int
        }
        """,
      expected: """
        public struct Foo: Sendable {
          let x: Int
        }
        """,
      findings: []
    )
  }

  @Test func packageStructNotFlagged() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        package struct Foo: Sendable {
          let x: Int
        }
        """,
      expected: """
        package struct Foo: Sendable {
          let x: Int
        }
        """,
      findings: []
    )
  }

  @Test func classNotFlagged() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        class Foo: Sendable {
          let x: Int
        }
        """,
      expected: """
        class Foo: Sendable {
          let x: Int
        }
        """,
      findings: []
    )
  }

  @Test func noSendableNotFlagged() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        struct Foo: Codable {
          let x: Int
        }
        """,
      expected: """
        struct Foo: Codable {
          let x: Int
        }
        """,
      findings: []
    )
  }

  @Test func privateStruct() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        private struct Foo: 1️⃣Sendable {
          let x: Int
        }
        """,
      expected: """
        private struct Foo {
          let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func sendableWithOtherConformances() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        struct Foo: Codable, 1️⃣Sendable {
          let x: Int
        }
        """,
      expected: """
        struct Foo: Codable {
          let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func sendableFirstWithOtherConformances() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        struct Foo: 1️⃣Sendable, Codable {
          let x: Int
        }
        """,
      expected: """
        struct Foo: Codable {
          let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }

  @Test func nestedStruct() {
    assertFormatting(
      RedundantSendable.self,
      input: """
        struct Outer {
          struct Inner: 1️⃣Sendable {
            let x: Int
          }
        }
        """,
      expected: """
        struct Outer {
          struct Inner {
            let x: Int
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove explicit 'Sendable'; it is inferred for non-public structs and enums"),
      ]
    )
  }
}
