import Testing

@testable import Swiftiomatic

@Suite struct TrailingSpaceTests {
  // truncateBlankLines = true

  @Test func trailingSpace() {
    let input = """
      foo\("    ")
      bar
      """
    let output = """
      foo
      bar
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func trailingSpaceAtEndOfFile() {
    let input = """
      foo\("    ")
      """
    let output = """
      foo
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func trailingSpaceInMultilineComments() {
    let input = """
      /* foo\("    ")
       bar  */
      """
    let output = """
      /* foo
       bar  */
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func trailingSpaceInSingleLineComments() {
    let input = """
      // foo\("    ")
      // bar  
      """
    let output = """
      // foo
      // bar
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func truncateBlankLine() {
    let input = """
      foo {
          // bar
      \("    ")
          // baz
      }
      """
    let output = """
      foo {
          // bar

          // baz
      }
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func trailingSpaceInArray() {
    let input = """
      let foo = [
          1,
      \("    ")
          2,
      ]
      """
    let output = """
      let foo = [
          1,

          2,
      ]
      """
    testFormatting(for: input, output, rule: .trailingSpace, exclude: [.redundantSelf])
  }

  @Test func multilineStringWithTrailingSpaces() {
    let input = """
      let foo = \"\"\"\u{20}\u{20}
      there is a space here\u{20}
      \"\"\"\u{20}
      """
    let output = """
      let foo = \"\"\"
      there is a space here\u{20}
      \"\"\"
      """
    testFormatting(for: input, output, rule: .trailingSpace)
  }

  @Test func multilineStringWithLeadingSpaceAfterInterpolation() {
    let input = """
      let foo = \"\"\"
      \\(foo)    bar
      \"\"\"
      """
    testFormatting(for: input, rule: .trailingSpace)
  }

  @Test func multilineStringWhiteSpaceNotRemovedFromBlankLines() {
    let input = """
      func test() {
          let foo = \"\"\"
          Test
          \u{20}
          \"\"\"
      }
      """
    testFormatting(for: input, rule: .trailingSpace)
  }

  // truncateBlankLines = false

  @Test func noTruncateBlankLine() {
    let input = """
      foo {
          // bar
      \("    ")
          // baz
      }
      """
    let options = FormatOptions(truncateBlankLines: false)
    testFormatting(for: input, rule: .trailingSpace, options: options)
  }

  @Test func multilineStringWhiteSpaceNotAddedToBlankLines() {
    let input = """
      func test() {
      \tlet foo = \"\"\"
      \tTest
      \t
      \t\"\"\"
      }
      """
    let options = FormatOptions(indent: "\t", truncateBlankLines: false)
    testFormatting(for: input, rule: .trailingSpace, options: options)
  }
}
