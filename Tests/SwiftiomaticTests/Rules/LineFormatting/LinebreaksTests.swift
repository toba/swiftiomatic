import Testing

@testable import Swiftiomatic

@Suite struct LinebreaksTests {
  @Test func carriageReturn() {
    let input = """
      foo\rbar
      """
    let output = """
      foo
      bar
      """
    testFormatting(for: input, output, rule: .linebreaks)
  }

  @Test func carriageReturnLinefeed() {
    let input = """
      foo\r
      bar
      """
    let output = """
      foo
      bar
      """
    testFormatting(for: input, output, rule: .linebreaks)
  }

  @Test func verticalTab() {
    let input = """
      foo\u{000B}bar
      """
    let output = """
      foo
      bar
      """
    testFormatting(for: input, output, rule: .linebreaks)
  }

  @Test func formfeed() {
    let input = """
      foo\u{000C}bar
      """
    let output = """
      foo
      bar
      """
    testFormatting(for: input, output, rule: .linebreaks)
  }
}
