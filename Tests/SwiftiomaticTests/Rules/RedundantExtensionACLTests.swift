@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct RedundantExtensionACLTests: RuleTesting {
  @Test func publicExtensionPublicMember() {
    assertLint(
      RedundantExtensionACL.self,
      """
      public extension Foo {
        1️⃣public func bar() {}
        2️⃣public var x: Int { 1 }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
        FindingSpec("2️⃣", message: "remove redundant 'public'; it matches the extension's access level"),
      ]
    )
  }

  @Test func internalExtensionInternalMember() {
    assertLint(
      RedundantExtensionACL.self,
      """
      internal extension Foo {
        1️⃣internal func bar() {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove redundant 'internal'; it matches the extension's access level"),
      ]
    )
  }

  @Test func differentAccessLevelNotFlagged() {
    assertLint(
      RedundantExtensionACL.self,
      """
      public extension Foo {
        internal func bar() {}
        private func baz() {}
      }
      """,
      findings: []
    )
  }

  @Test func noExtensionAccessLevelNotFlagged() {
    assertLint(
      RedundantExtensionACL.self,
      """
      extension Foo {
        public func bar() {}
      }
      """,
      findings: []
    )
  }

  @Test func memberWithNoAccessLevelNotFlagged() {
    assertLint(
      RedundantExtensionACL.self,
      """
      public extension Foo {
        func bar() {}
      }
      """,
      findings: []
    )
  }

  @Test func publicSetNotFlagged() {
    assertLint(
      RedundantExtensionACL.self,
      """
      public extension Foo {
        public(set) var x: Int { get { 1 } set {} }
      }
      """,
      findings: []
    )
  }
}
