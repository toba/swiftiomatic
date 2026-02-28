import Testing

@testable import Swiftiomatic

@Suite struct LinebreakAtEndOfFileTests {
  @Test func linebreakAtEndOfFile() {
    let input = """
      foo
      bar
      """
    let output = """
      foo
      bar

      """
    testFormatting(for: input, output, rule: .linebreakAtEndOfFile)
  }

  @Test func noLinebreakAtEndOfFragment() {
    let input = """
      foo
      bar
      """
    let options = FormatOptions(fragment: true)
    testFormatting(for: input, rule: .linebreakAtEndOfFile, options: options)
  }
}
