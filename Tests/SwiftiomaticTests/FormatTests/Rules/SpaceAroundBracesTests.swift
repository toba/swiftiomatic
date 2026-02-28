import Testing

@testable import Swiftiomatic

@Suite struct SpaceAroundBracesTests {
  @Test func spaceAroundTrailingClosure() {
    let input = """
      if x{ y }else{ z }
      """
    let output = """
      if x { y } else { z }
      """
    testFormatting(
      for: input, output, rule: .spaceAroundBraces,
      exclude: [.wrapConditionalBodies])
  }

  @Test func noSpaceAroundClosureInsiderParens() {
    let input = """
      foo({ $0 == 5 })
      """
    testFormatting(
      for: input, rule: .spaceAroundBraces,
      exclude: [.trailingClosures])
  }

  @Test func noExtraSpaceAroundBracesAtStartOrEndOfFile() {
    let input = """
      { foo }
      """
    testFormatting(for: input, rule: .spaceAroundBraces)
  }

  @Test func noSpaceAfterPrefixOperator() {
    let input = """
      let foo = ..{ bar }
      """
    testFormatting(for: input, rule: .spaceAroundBraces)
  }

  @Test func noSpaceBeforePostfixOperator() {
    let input = """
      let foo = { bar }..
      """
    testFormatting(for: input, rule: .spaceAroundBraces)
  }

  @Test func spaceAroundBracesAfterOptionalProperty() {
    let input = """
      var: Foo?{}
      """
    let output = """
      var: Foo? {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBraces)
  }

  @Test func spaceAroundBracesAfterImplicitlyUnwrappedProperty() {
    let input = """
      var: Foo!{}
      """
    let output = """
      var: Foo! {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBraces)
  }

  @Test func spaceAroundBracesAfterNumber() {
    let input = """
      if x = 5{}
      """
    let output = """
      if x = 5 {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBraces)
  }

  @Test func spaceAroundBracesAfterString() {
    let input = """
      if x = \"\"{}
      """
    let output = """
      if x = \"\" {}
      """
    testFormatting(for: input, output, rule: .spaceAroundBraces)
  }
}
