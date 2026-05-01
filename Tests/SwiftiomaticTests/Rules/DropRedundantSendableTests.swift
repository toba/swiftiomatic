@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct DropRedundantSendableTests: RuleTesting {
  @Test func internalStruct() {
    assertFormatting(
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
      DropRedundantSendable.self,
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
