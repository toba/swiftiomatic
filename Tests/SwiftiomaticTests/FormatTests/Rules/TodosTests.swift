import Testing

@testable import Swiftiomatic

@Suite struct TodosTests {
  @Test func markIsUpdated() {
    let input = """
      // MARK foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func todoIsUpdated() {
    let input = """
      // TODO foo
      """
    let output = """
      // TODO: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func fixmeIsUpdated() {
    let input = """
      //    FIXME foo
      """
    let output = """
      //    FIXME: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func markWithColonSeparatedBySpace() {
    let input = """
      // MARK : foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func markWithTripleSlash() {
    let input = """
      /// MARK: foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func todoReplacedInMiddleOfCommentBlock() {
    let input = """
      // Some comment
      // todo : foo
      // Some more comment
      """
    let output = """
      // Some comment
      // TODO: foo
      // Some more comment
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func todoNotReplacedInMiddleOfDocBlock() {
    let input = """
      /// Some docs
      /// TODO: foo
      /// Some more docs
      """
    testFormatting(for: input, rule: .todos, exclude: [.docComments])
  }

  @Test func todoNotReplacedAtStartOfDocBlock() {
    let input = """
      /// TODO: foo
      /// Some docs
      """
    testFormatting(for: input, rule: .todos, exclude: [.docComments])
  }

  @Test func todoNotReplacedAtEndOfDocBlock() {
    let input = """
      /// Some docs
      /// TODO: foo
      """
    testFormatting(for: input, rule: .todos, exclude: [.docComments])
  }

  @Test func markWithNoSpaceAfterColon() {
    // NOTE: this was an unintended side-effect, but I like it
    let input = """
      // MARK:foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func markInsideMultilineComment() {
    let input = """
      /* MARK foo */
      """
    let output = """
      /* MARK: foo */
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func noExtraSpaceAddedAfterTodo() {
    let input = """
      /* TODO: */
      """
    testFormatting(for: input, rule: .todos)
  }

  @Test func lowercaseMarkColonIsUpdated() {
    let input = """
      // mark: foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func mixedCaseMarkColonIsUpdated() {
    let input = """
      // Mark: foo
      """
    let output = """
      // MARK: foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func lowercaseMarkIsNotUpdated() {
    let input = """
      // mark as read
      """
    testFormatting(for: input, rule: .todos)
  }

  @Test func mixedCaseMarkIsNotUpdated() {
    let input = """
      // Mark as read
      """
    testFormatting(for: input, rule: .todos)
  }

  @Test func lowercaseMarkDashIsUpdated() {
    let input = """
      // mark - foo
      """
    let output = """
      // MARK: - foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func spaceAddedBeforeMarkDash() {
    let input = """
      // MARK:- foo
      """
    let output = """
      // MARK: - foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func spaceAddedAfterMarkDash() {
    let input = """
      // MARK: -foo
      """
    let output = """
      // MARK: - foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func spaceAddedAroundMarkDash() {
    let input = """
      // MARK:-foo
      """
    let output = """
      // MARK: - foo
      """
    testFormatting(for: input, output, rule: .todos)
  }

  @Test func spaceNotAddedAfterMarkDashAtEndOfString() {
    let input = """
      // MARK: -
      """
    testFormatting(for: input, rule: .todos)
  }
}
