@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct AnyObjectProtocolTests: RuleTesting {
  @Test func classReplacedWithAnyObject() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        protocol Foo: 1️⃣class {}
        """,
      expected: """
        protocol Foo: AnyObject {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'AnyObject' instead of 'class' for class-constrained protocols"),
      ]
    )
  }

  @Test func classWithOtherInheritance() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        protocol Foo: 1️⃣class, Bar {}
        """,
      expected: """
        protocol Foo: AnyObject, Bar {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "use 'AnyObject' instead of 'class' for class-constrained protocols"),
      ]
    )
  }

  @Test func alreadyAnyObject() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        protocol Foo: AnyObject {}
        """,
      expected: """
        protocol Foo: AnyObject {}
        """,
      findings: []
    )
  }

  @Test func noInheritanceClause() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        protocol Foo {}
        """,
      expected: """
        protocol Foo {}
        """,
      findings: []
    )
  }

  @Test func protocolWithOtherInheritanceOnly() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        protocol Foo: Bar, Baz {}
        """,
      expected: """
        protocol Foo: Bar, Baz {}
        """,
      findings: []
    )
  }

  @Test func classKeywordInNonProtocol() {
    assertFormatting(
      UseAnyObjectOnDelegate.self,
      input: """
        class Foo: Bar {}
        """,
      expected: """
        class Foo: Bar {}
        """,
      findings: []
    )
  }
}
