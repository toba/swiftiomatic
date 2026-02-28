import Testing

@testable import Swiftiomatic

@Suite struct LeadingDelimitersTests {
  @Test func leadingCommaMovedToPreviousLine() {
    let input = """
      let foo = 5
          , bar = 6
      """
    let output = """
      let foo = 5,
          bar = 6
      """
    testFormatting(for: input, output, rule: .leadingDelimiters, exclude: [.singlePropertyPerLine])
  }

  @Test func leadingColonFollowedByCommentMovedToPreviousLine() {
    let input = """
      let foo
          : /* string */ String
      """
    let output = """
      let foo:
          /* string */ String
      """
    testFormatting(for: input, output, rule: .leadingDelimiters)
  }

  @Test func commaMovedBeforeCommentIfLineEndsInComment() {
    let input = """
      let foo = 5 // first
          , bar = 6
      """
    let output = """
      let foo = 5, // first
          bar = 6
      """
    testFormatting(for: input, output, rule: .leadingDelimiters, exclude: [.singlePropertyPerLine])
  }
}
