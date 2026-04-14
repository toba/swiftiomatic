@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantPublicTests: RuleTesting {
  @Test func publicMemberInInternalType() {
    assertLint(
      RedundantPublic.self,
      """
      struct Foo {
        1️⃣public func bar() {}
        2️⃣public var x = 1
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func publicMemberInPrivateType() {
    assertLint(
      RedundantPublic.self,
      """
      private class Foo {
        1️⃣public func bar() {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func publicMemberInPublicTypeNotFlagged() {
    assertLint(
      RedundantPublic.self,
      """
      public struct Foo {
        public func bar() {}
      }
      """,
      findings: []
    )
  }

  @Test func internalMemberNotFlagged() {
    assertLint(
      RedundantPublic.self,
      """
      struct Foo {
        func bar() {}
      }
      """,
      findings: []
    )
  }

  @Test func publicMemberInEnum() {
    assertLint(
      RedundantPublic.self,
      """
      enum Foo {
        1️⃣public static func make() -> Foo { .init() }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func packageTypeNotFlagged() {
    assertLint(
      RedundantPublic.self,
      """
      package struct Foo {
        public func bar() {}
      }
      """,
      findings: []
    )
  }
}
