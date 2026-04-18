@testable import Swiftiomatic
import SwiftiomaticTestSupport
import Testing

@Suite
struct DocCommentsBeforeModifiersTests: RuleTesting {

  @Test func docCommentBeforeAttribute() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        @MainActor
        /// Doc comment on this type declaration
        public 1️⃣struct Baaz {}
        """,
      expected: """
        /// Doc comment on this type declaration
        @MainActor
        public struct Baaz {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place doc comments before attributes and modifiers"),
      ]
    )
  }

  @Test func alreadyCorrect() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        /// Doc comment
        @MainActor
        public struct Foo {}
        """,
      expected: """
        /// Doc comment
        @MainActor
        public struct Foo {}
        """,
      findings: []
    )
  }

  @Test func noAttributesOrModifiers() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        /// Doc comment
        struct Foo {}
        """,
      expected: """
        /// Doc comment
        struct Foo {}
        """,
      findings: []
    )
  }

  @Test func docCommentBeforeModifier() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        public
        /// Doc comment
        1️⃣func bar() {}
        """,
      expected: """
        /// Doc comment
        public
        func bar() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "place doc comments before attributes and modifiers"),
      ]
    )
  }

  @Test func caseCommentsNotMangled() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        enum Symbol {
          /// A named variable
          case variable(String)

          /// An infix operator
          case infix(String)
        }
        """,
      expected: """
        enum Symbol {
          /// A named variable
          case variable(String)

          /// An infix operator
          case infix(String)
        }
        """,
      findings: []
    )
  }

  @Test func preservesRegularComments() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        @MainActor
        // Regular comment
        func foo() {}
        """,
      expected: """
        @MainActor
        // Regular comment
        func foo() {}
        """,
      findings: []
    )
  }

  @Test func multilineDocComment() {
    assertFormatting(
      DocCommentsBeforeModifiers.self,
      input: """
        @available(*, deprecated)
        /// Doc comment on this property declaration.
        /// This comment spans multiple lines.
        private 1️⃣var bar: Int = 0
        """,
      expected: """
        /// Doc comment on this property declaration.
        /// This comment spans multiple lines.
        @available(*, deprecated)
        private var bar: Int = 0
        """,
      findings: [
        FindingSpec("1️⃣", message: "place doc comments before attributes and modifiers"),
      ]
    )
  }
}
