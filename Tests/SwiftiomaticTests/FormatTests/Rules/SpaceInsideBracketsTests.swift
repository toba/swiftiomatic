import Testing

@testable import Swiftiomatic

@Suite struct SpaceInsideBracketsTests {
  @Test func spaceInsideBrackets() {
    let input = """
      foo[ 5 ]
      """
    let output = """
      foo[5]
      """
    testFormatting(for: input, output, rule: .spaceInsideBrackets)
  }

  @Test func spaceInsideWrappedArray() {
    let input = """
      [ foo,
       bar ]
      """
    let output = """
      [foo,
       bar]
      """
    let options = FormatOptions(wrapCollections: .disabled)
    testFormatting(for: input, output, rule: .spaceInsideBrackets, options: options)
  }

  @Test func spaceBeforeCommentInsideWrappedArray() {
    let input = """
      [ // foo
          bar,
      ]
      """
    let options = FormatOptions(wrapCollections: .disabled)
    testFormatting(for: input, rule: .spaceInsideBrackets, options: options)
  }
}
