import Testing

@testable import Swiftiomatic

@Suite struct SemicolonsTests {
  @Test func semicolonRemovedAtEndOfLine() {
    let input = """
      print(\"hello\");

      """
    let output = """
      print(\"hello\")

      """
    testFormatting(for: input, output, rule: .semicolons)
  }

  @Test func semicolonRemovedAtStartOfLine() {
    let input = """

      ;print(\"hello\")
      """
    let output = """

      print(\"hello\")
      """
    testFormatting(for: input, output, rule: .semicolons)
  }

  @Test func semicolonRemovedAtEndOfProgram() {
    let input = """
      print(\"hello\");
      """
    let output = """
      print(\"hello\")
      """
    testFormatting(for: input, output, rule: .semicolons)
  }

  @Test func semicolonRemovedAtStartOfProgram() {
    let input = """
      ;print(\"hello\")
      """
    let output = """
      print(\"hello\")
      """
    testFormatting(for: input, output, rule: .semicolons)
  }

  @Test func ignoreInlineSemicolon() {
    let input = """
      print(\"hello\"); print(\"goodbye\")
      """
    let options = FormatOptions(semicolons: .inlineOnly)
    testFormatting(for: input, rule: .semicolons, options: options)
  }

  @Test func replaceInlineSemicolon() {
    let input = """
      print(\"hello\"); print(\"goodbye\")
      """
    let output = """
      print(\"hello\")
      print(\"goodbye\")
      """
    let options = FormatOptions(semicolons: .never)
    testFormatting(for: input, output, rule: .semicolons, options: options)
  }

  @Test func replaceSemicolonFollowedByComment() {
    let input = """
      print(\"hello\"); // comment
      print(\"goodbye\")
      """
    let output = """
      print(\"hello\") // comment
      print(\"goodbye\")
      """
    let options = FormatOptions(semicolons: .inlineOnly)
    testFormatting(for: input, output, rule: .semicolons, options: options)
  }

  @Test func semicolonNotReplacedAfterReturn() {
    let input = """
      return;
      foo()
      """
    testFormatting(for: input, rule: .semicolons)
  }

  @Test func semicolonReplacedAfterReturnIfEndOfScope() {
    let input = """
      do { return; }
      """
    let output = """
      do { return }
      """
    testFormatting(for: input, output, rule: .semicolons)
  }

  @Test func requiredSemicolonNotRemovedAfterInferredVar() {
    let input = """
      func foo() {
          @Environment(\\.colorScheme) var colorScheme;
          print(colorScheme)
      }
      """
    testFormatting(for: input, rule: .semicolons)
  }
}
