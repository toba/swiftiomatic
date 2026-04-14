@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantExtensionACLTests: RuleTesting {
  @Test func publicExtensionPublicMember() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        public extension Foo {
          1️⃣public func bar() {}
          2️⃣public var x: Int { 1 }
        }
        """,
      expected: """
        public extension Foo {
          func bar() {}
          var x: Int { 1 }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
      ]
    )
  }

  @Test func internalExtensionInternalMember() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        internal extension Foo {
          1️⃣internal func bar() {}
        }
        """,
      expected: """
        internal extension Foo {
          func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal'; it matches the extension's access level"),
      ]
    )
  }

  @Test func differentAccessLevelNotFlagged() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        public extension Foo {
          internal func bar() {}
          private func baz() {}
        }
        """,
      expected: """
        public extension Foo {
          internal func bar() {}
          private func baz() {}
        }
        """,
      findings: []
    )
  }

  @Test func noExtensionAccessLevelNotFlagged() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        extension Foo {
          public func bar() {}
        }
        """,
      expected: """
        extension Foo {
          public func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func memberWithNoAccessLevelNotFlagged() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        public extension Foo {
          func bar() {}
        }
        """,
      expected: """
        public extension Foo {
          func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func publicSetNotFlagged() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        public extension Foo {
          public(set) var x: Int { get { 1 } set {} }
        }
        """,
      expected: """
        public extension Foo {
          public(set) var x: Int { get { 1 } set {} }
        }
        """,
      findings: []
    )
  }

  @Test func memberWithOtherModifiers() {
    assertFormatting(
      RedundantExtensionACL.self,
      input: """
        public extension Foo {
          1️⃣public static func bar() {}
        }
        """,
      expected: """
        public extension Foo {
          static func bar() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
      ]
    )
  }
}
