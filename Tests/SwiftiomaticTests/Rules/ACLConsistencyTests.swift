@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct ACLConsistencyTests: RuleTesting {
  // MARK: - Removing redundant ACLs

  @Test func publicInsideStructIsRemoved() {
    assertFormatting(
      ACLConsistency.self,
      input: "struct Foo { 1️⃣public func bar() {} }",
      expected: "struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicInsideEnumIsRemoved() {
    assertFormatting(
      ACLConsistency.self,
      input: "enum Foo { 1️⃣public func bar() {} }",
      expected: "enum Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicInsidePrivateStructIsRemoved() {
    assertFormatting(
      ACLConsistency.self,
      input: "private struct Foo { 1️⃣public func bar() {} }",
      expected: "private struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func openDowngradedToPublic() {
    assertFormatting(
      ACLConsistency.self,
      input: "public class Foo { 1️⃣open func bar() {} }",
      expected: "public class Foo { public func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func internalInsidePrivateStructIsRemoved() {
    assertFormatting(
      ACLConsistency.self,
      input: "private struct Foo { 1️⃣internal func bar() {} }",
      expected: "private struct Foo { func bar() {} }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func publicSetIsRemovedInsideClass() {
    assertFormatting(
      ACLConsistency.self,
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
      ACLConsistency.self,
      input: "open class Foo { open func bar() {} }",
      expected: "open class Foo { open func bar() {} }",
      findings: []
    )
  }

  @Test func publicInsideOpenClassOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "open class Foo { public func bar() {} }",
      expected: "open class Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func publicInsidePublicStructOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "public struct Foo { public func bar() {} }",
      expected: "public struct Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func defaultsOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "struct Foo { func bar() {} }",
      expected: "struct Foo { func bar() {} }",
      findings: []
    )
  }

  @Test func internalInsideDefaultStructOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "struct Foo { internal func bar() {} }",
      expected: "struct Foo { internal func bar() {} }",
      findings: []
    )
  }

  @Test func publicInExtensionOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "extension Foo { public func bar() {} }",
      expected: "extension Foo { public func bar() {} }",
      findings: []
    )
  }

  @Test func nestedPublicInPublicExtensionOK() {
    assertFormatting(
      ACLConsistency.self,
      input: "public extension Foo { struct Bar { public func baz() {} } }",
      expected: "public extension Foo { struct Bar { public func baz() {} } }",
      findings: []
    )
  }

  // MARK: - Extension parent traversal

  @Test func publicInsideStructInPrivateExtension() {
    assertFormatting(
      ACLConsistency.self,
      input: "private extension Foo { struct Bar { 1️⃣public func baz() {} } }",
      expected: "private extension Foo { struct Bar { func baz() {} } }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }

  @Test func internalInsideStructInPrivateExtension() {
    assertFormatting(
      ACLConsistency.self,
      input: "private extension Foo { struct Bar { 1️⃣internal func baz() {} } }",
      expected: "private extension Foo { struct Bar { func baz() {} } }",
      findings: [
        FindingSpec("1️⃣", message: "declaration should not have a higher access level than its enclosing parent")
      ]
    )
  }
}
