import Testing

@testable import SwiftiomaticKit
@testable import SwiftiomaticSyntax

// MARK: - BlockCommentsRule

@Suite(.rulesRegistered)
struct BlockCommentsRuleTests {
  @Test func noViolationForLineComments() async {
    await assertNoViolation(
      BlockCommentsRule.self,
      """
      // A comment
      // on multiple lines
      """)
  }

  @Test func detectsBlockComment() async {
    await assertViolates(
      BlockCommentsRule.self,
      """
      /* A comment
         on multiple lines */
      """)
  }
}

// MARK: - DocCommentsBeforeModifiersRule

@Suite(.rulesRegistered)
struct DocCommentsBeforeModifiersRuleTests {
  @Test func noViolationForDocBeforeModifiers() async {
    await assertNoViolation(
      DocCommentsBeforeModifiersRule.self,
      """
      /// Doc comment
      @MainActor
      func foo() {}
      """)
  }

  // Detection requires attribute + doc comment adjacency analysis
}

// MARK: - DocCommentsRule

@Suite(.rulesRegistered)
struct DocCommentsRuleTests {
  @Test func noViolationForDocComment() async {
    await assertNoViolation(
      DocCommentsRule.self,
      """
      /// A placeholder type
      class Foo {}
      """)
  }

  @Test func detectsRegularCommentOnDeclaration() async {
    await assertViolates(
      DocCommentsRule.self,
      """
      // A placeholder type
      class Foo {}
      """)
  }
}

// MARK: - MarkTypesRule

@Suite(.rulesRegistered)
struct MarkTypesRuleTests {
  @Test func noViolationWithMark() async {
    await assertNoViolation(
      MarkTypesRule.self,
      """
      // MARK: - Foo

      class Foo {}
      """)
  }

  @Test func noViolationForSingleType() async {
    await assertNoViolation(
      MarkTypesRule.self,
      """
      import Foundation
      struct Foo {}
      """)
  }

  @Test func detectsMissingMarkForMultipleTypes() async {
    await assertViolates(
      MarkTypesRule.self,
      """
      class Foo {}
      class Bar {}
      """)
  }
}
