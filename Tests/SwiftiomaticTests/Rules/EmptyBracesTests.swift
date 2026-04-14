@_spi(Rules) import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct EmptyBracesTests: RuleTesting {

  @Test func emptyFunctionBody() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() 1️⃣{ }
        """,
      expected: """
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func emptyFunctionBodyMultiline() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() 1️⃣{
        }
        """,
      expected: """
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func emptyStructBody() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        struct Foo 1️⃣{ }
        """,
      expected: """
        struct Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func emptyClassBody() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        class Bar 1️⃣{
        }
        """,
      expected: """
        class Bar {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func emptyClosure() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        let action = 1️⃣{ }
        """,
      expected: """
        let action = {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func alreadyCollapsed() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func nonEmptyBodyUnchanged() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() {
          print("hello")
        }
        """,
      expected: """
        func foo() {
          print("hello")
        }
        """,
      findings: []
    )
  }

  @Test func commentInsideBracesUnchanged() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() {
          // TODO: implement
        }
        """,
      expected: """
        func foo() {
          // TODO: implement
        }
        """,
      findings: []
    )
  }

  @Test func closureWithSignatureUnchanged() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        let action = { [weak self] in }
        """,
      expected: """
        let action = { [weak self] in }
        """,
      findings: []
    )
  }

  @Test func emptyEnumBody() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        enum Empty 1️⃣{ }
        """,
      expected: """
        enum Empty {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func emptyExtensionBody() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        extension Foo 1️⃣{ }
        """,
      expected: """
        extension Foo {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove whitespace inside empty braces"),
      ]
    )
  }

  @Test func blockCommentInsideBracesUnchanged() {
    assertFormatting(
      EmptyBraces.self,
      input: """
        func foo() { /* TODO */ }
        """,
      expected: """
        func foo() { /* TODO */ }
        """,
      findings: []
    )
  }
}
