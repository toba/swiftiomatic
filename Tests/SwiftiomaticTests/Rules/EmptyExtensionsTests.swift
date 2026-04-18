@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct EmptyExtensionsTests: RuleTesting {

  @Test func emptyExtensionRemoved() {
    assertFormatting(
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
      EmptyExtensions.self,
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
