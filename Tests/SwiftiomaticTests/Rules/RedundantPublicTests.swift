@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantPublicTests: RuleTesting {
  @Test func publicMemberInInternalType() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        struct Foo {
          1️⃣public func bar() {}
          2️⃣public var x = 1
        }
        """,
      expected: """
        struct Foo {
          func bar() {}
          var x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func publicMemberInPrivateType() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        private class Foo {
          1️⃣public func bar() {}
        }
        """,
      expected: """
        private class Foo {
          func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func publicMemberInPublicTypeNotFlagged() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        public struct Foo {
          public func bar() {}
        }
        """,
      expected: """
        public struct Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func internalMemberNotFlagged() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        struct Foo {
          func bar() {}
        }
        """,
      expected: """
        struct Foo {
          func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func publicMemberInEnum() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        enum Foo {
          1️⃣public static func make() -> Foo { .init() }
        }
        """,
      expected: """
        enum Foo {
          static func make() -> Foo { .init() }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; the enclosing type is not public"),
      ]
    )
  }

  @Test func packageTypeNotFlagged() {
    assertFormatting(
      RedundantPublic.self,
      input: """
        package struct Foo {
          public func bar() {}
        }
        """,
      expected: """
        package struct Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }
}
