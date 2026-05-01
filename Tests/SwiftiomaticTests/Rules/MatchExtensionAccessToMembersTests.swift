@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct MatchExtensionAccessToMembersTests: RuleTesting {
  // MARK: - Removing redundant ACLs

  @Test func publicInsideStructIsRemoved() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "struct Foo { 1️⃣public func bar() {} }",
      expected: "struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicInsideEnumIsRemoved() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "enum Foo { 1️⃣public func bar() {} }",
      expected: "enum Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicInsidePrivateStructIsRemoved() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "private struct Foo { 1️⃣public func bar() {} }",
      expected: "private struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func openDowngradedToPublic() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "public class Foo { 1️⃣open func bar() {} }",
      expected: "public class Foo { public func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func internalInsidePrivateStructIsRemoved() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "private struct Foo { 1️⃣internal func bar() {} }",
      expected: "private struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicSetIsRemovedInsideClass() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "class Foo { 1️⃣public private(set) var bar: String? }",
      expected: "class Foo { private(set) var bar: String? }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  // MARK: - Non-triggering

  @Test func openInsideOpenClassOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "open class Foo { open func bar() {} }",
      expected: "open class Foo { open func bar() {} }",
      findings: []
    )
  }

  @Test func publicInsideOpenClassOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "open class Foo { public func bar() {} }",
      expected: "open class Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func publicInsidePublicStructOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "public struct Foo { public func bar() {} }",
      expected: "public struct Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func defaultsOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "struct Foo { func bar() {} }",
      expected: "struct Foo { func bar() {} }",
      findings: []
    )
  }

  @Test func internalInsideDefaultStructOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "struct Foo { internal func bar() {} }",
      expected: "struct Foo { internal func bar() {} }",
      findings: []
    )
  }

  @Test func publicInExtensionOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "extension Foo { public func bar() {} }",
      expected: "extension Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func nestedPublicInPublicExtensionOK() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "public extension Foo { struct Bar { public func baz() {} } }",
      expected: "public extension Foo { struct Bar { public func baz() {} } }",
      findings: []
    )
  }

  // MARK: - Extension parent traversal

  @Test func publicInsideStructInPrivateExtension() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "private extension Foo { struct Bar { 1️⃣public func baz() {} } }",
      expected: "private extension Foo { struct Bar { func baz() {} } }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func internalInsideStructInPrivateExtension() {
    assertFormatting(
      MatchExtensionAccessToMembers.self,
      input: "private extension Foo { struct Bar { 1️⃣internal func baz() {} } }",
      expected: "private extension Foo { struct Bar { func baz() {} } }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }
}
