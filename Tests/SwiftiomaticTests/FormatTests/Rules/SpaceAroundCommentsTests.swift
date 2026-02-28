import Testing

@testable import Swiftiomatic

@Suite struct SpaceAroundCommentsTests {
  @Test func spaceAroundCommentInParens() {
    let input = """
      (/* foo */)
      """
    let output = """
      ( /* foo */ )
      """
    testFormatting(
      for: input, output, rule: .spaceAroundComments,
      exclude: [.redundantParens])
  }

  @Test func noSpaceAroundCommentAtStartAndEndOfFile() {
    let input = """
      /* foo */
      """
    testFormatting(for: input, rule: .spaceAroundComments)
  }

  @Test func noSpaceAroundCommentBeforeComma() {
    let input = """
      (foo /* foo */ , bar)
      """
    let output = """
      (foo /* foo */, bar)
      """
    testFormatting(for: input, output, rule: .spaceAroundComments)
  }

  @Test func spaceAroundSingleLineComment() {
    let input = """
      func foo() {// comment
      }
      """
    let output = """
      func foo() { // comment
      }
      """
    testFormatting(for: input, output, rule: .spaceAroundComments)
  }
}
