@testable import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct EmptyBracesTests: LayoutTesting {

  @Test func emptyFunctionBody() {
    assertLayout(
      input: """
        func foo() { }
        """,
      expected: """
        func foo() {}

        """,
      linelength: 100
    )
  }

  @Test func emptyFunctionBodyMultiline() {
    assertLayout(
      input: """
        func foo() {
        }
        """,
      expected: """
        func foo() {}

        """,
      linelength: 100
    )
  }

  @Test func emptyStructBody() {
    assertLayout(
      input: """
        struct Foo { }
        """,
      expected: """
        struct Foo {}

        """,
      linelength: 100
    )
  }

  @Test func emptyClassBody() {
    assertLayout(
      input: """
        class Bar {
        }
        """,
      expected: """
        class Bar {}

        """,
      linelength: 100
    )
  }

  @Test func emptyClosure() {
    assertLayout(
      input: """
        let action = { }
        """,
      expected: """
        let action = {}

        """,
      linelength: 100
    )
  }

  @Test func alreadyCollapsed() {
    assertLayout(
      input: """
        func foo() {}
        """,
      expected: """
        func foo() {}

        """,
      linelength: 100
    )
  }

  @Test func nonEmptyBodyUnchanged() {
    assertLayout(
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
      linelength: 100
    )
  }

  @Test func commentInsideBracesUnchanged() {
    assertLayout(
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
      linelength: 100
    )
  }

  @Test func emptyEnumBody() {
    assertLayout(
      input: """
        enum Empty { }
        """,
      expected: """
        enum Empty {}

        """,
      linelength: 100
    )
  }

  @Test func emptyExtensionBody() {
    assertLayout(
      input: """
        extension Foo { }
        """,
      expected: """
        extension Foo {}

        """,
      linelength: 100
    )
  }

  @Test func blockCommentInsideBracesUnchanged() {
    // Block comment makes braces non-empty; the open+close breaks each add one space
    assertLayout(
      input: """
        func foo() { /* TODO */ }
        """,
      expected: """
        func foo() { /* TODO */  }

        """,
      linelength: 100
    )
  }
}
