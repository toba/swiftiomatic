@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct RemoveEmptyExtensionsTests: RuleTesting {

  @Test func emptyExtensionRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        1️⃣extension Foo {}
        """,
      expected: """

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Foo'"),
      ]
    )
  }

  @Test func emptyExtensionWithSpaceRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        1️⃣extension Foo { }
        """,
      expected: """

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Foo'"),
      ]
    )
  }

  @Test func emptyExtensionMultilineRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        1️⃣extension Foo {
        }
        """,
      expected: """

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Foo'"),
      ]
    )
  }

  @Test func extensionWithConformanceKept() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        extension Foo: Equatable {}
        """,
      expected: """
        extension Foo: Equatable {}
        """,
      findings: []
    )
  }

  @Test func extensionWithMembersKept() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        extension Foo {
          func bar() {}
        }
        """,
      expected: """
        extension Foo {
          func bar() {}
        }
        """,
      findings: []
    )
  }

  @Test func extensionWithCommentKept() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        extension Foo {
          // TODO: implement
        }
        """,
      expected: """
        extension Foo {
          // TODO: implement
        }
        """,
      findings: []
    )
  }

  @Test func extensionWithWhereClauseRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        1️⃣extension Array where Element: Equatable {}
        """,
      expected: """

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Array'"),
      ]
    )
  }

  @Test func extensionWithAccessModifierRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        public 1️⃣extension Foo {}
        """,
      expected: """

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Foo'"),
      ]
    )
  }

  @Test func multipleExtensionsOnlyEmptyRemoved() {
    assertFormatting(
      RemoveEmptyExtensions.self,
      input: """
        1️⃣extension Foo {}
        extension Bar: Equatable {}
        """,
      expected: """
        extension Bar: Equatable {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty extension on 'Foo'"),
      ]
    )
  }
}
