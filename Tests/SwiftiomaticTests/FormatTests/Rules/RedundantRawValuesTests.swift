import Testing

@testable import Swiftiomatic

@Suite struct RedundantRawValuesTests {
  @Test func removeRedundantRawString() {
    let input = """
      enum Foo: String {
          case bar = \"bar\"
          case baz = \"baz\"
      }
      """
    let output = """
      enum Foo: String {
          case bar
          case baz
      }
      """
    testFormatting(for: input, output, rule: .redundantRawValues)
  }

  @Test func removeCommaDelimitedCaseRawStringCases() {
    let input = """
      enum Foo: String { case bar = \"bar\", baz = \"baz\" }
      """
    let output = """
      enum Foo: String { case bar, baz }
      """
    testFormatting(
      for: input, output, rule: .redundantRawValues,
      exclude: [.wrapEnumCases])
  }

  @Test func removeBacktickCaseRawStringCases() {
    let input = """
      enum Foo: String { case `as` = \"as\", `let` = \"let\" }
      """
    let output = """
      enum Foo: String { case `as`, `let` }
      """
    testFormatting(
      for: input, output, rule: .redundantRawValues,
      exclude: [.wrapEnumCases])
  }

  @Test func noRemoveRawStringIfNameDoesntMatch() {
    let input = """
      enum Foo: String {
          case bar = \"foo\"
      }
      """
    testFormatting(for: input, rule: .redundantRawValues)
  }
}
