import Testing

@testable import Swiftiomatic

@Suite struct SpaceInsideParensTests {
  @Test func spaceInsideParens() {
    let input = """
      ( 1, ( 2, 3 ) )
      """
    let output = """
      (1, (2, 3))
      """
    testFormatting(for: input, output, rule: .spaceInsideParens)
  }

  @Test func spaceBeforeCommentInsideParens() {
    let input = """
      ( /* foo */ 1, 2 )
      """
    let output = """
      ( /* foo */ 1, 2)
      """
    testFormatting(for: input, output, rule: .spaceInsideParens)
  }
}
