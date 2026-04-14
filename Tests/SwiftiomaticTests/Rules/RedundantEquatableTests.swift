@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantEquatableTests: RuleTesting {
  @Test func simpleStructEquatable() {
    assertLint(
      RedundantEquatable.self,
      """
      struct Foo: Equatable {
        let x: Int
        let y: String
        static func 1️⃣== (lhs: Foo, rhs: Foo) -> Bool {
          lhs.x == rhs.x && lhs.y == rhs.y
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is likely equivalent"),
      ]
    )
  }

  @Test func enumEquatable() {
    assertLint(
      RedundantEquatable.self,
      """
      enum Direction: Equatable {
        case north, south
        static func 1️⃣== (lhs: Direction, rhs: Direction) -> Bool {
          return true
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove hand-written '==' operator; compiler-synthesized Equatable conformance is likely equivalent"),
      ]
    )
  }

  @Test func noEquatableConformanceNotFlagged() {
    assertLint(
      RedundantEquatable.self,
      """
      struct Foo {
        let x: Int
        static func == (lhs: Foo, rhs: Foo) -> Bool {
          lhs.x == rhs.x
        }
      }
      """,
      findings: []
    )
  }

  @Test func multiStatementBodyNotFlagged() {
    assertLint(
      RedundantEquatable.self,
      """
      struct Foo: Equatable {
        let x: Int
        static func == (lhs: Foo, rhs: Foo) -> Bool {
          guard lhs.x == rhs.x else { return false }
          return true
        }
      }
      """,
      findings: []
    )
  }

  @Test func noEqualsFuncNotFlagged() {
    assertLint(
      RedundantEquatable.self,
      """
      struct Foo: Equatable {
        let x: Int
      }
      """,
      findings: []
    )
  }

  @Test func classNotFlagged() {
    assertLint(
      RedundantEquatable.self,
      """
      class Foo: Equatable {
        let x: Int
        static func == (lhs: Foo, rhs: Foo) -> Bool {
          lhs.x == rhs.x
        }
      }
      """,
      findings: []
    )
  }
}
