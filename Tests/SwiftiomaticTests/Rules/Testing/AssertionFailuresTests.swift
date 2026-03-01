import Testing

@testable import Swiftiomatic

@Suite struct AssertionFailuresTests {
  @Test func assertionFailuresForAssertFalse() {
    let input = """
      assert(false)
      """
    let output = """
      assertionFailure()
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }

  @Test func assertionFailuresForAssertFalseWithSpaces() {
    let input = """
      assert ( false )
      """
    let output = """
      assertionFailure()
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }

  @Test func assertionFailuresForAssertFalseWithLinebreaks() {
    let input = """
      assert(
          false
      )
      """
    let output = """
      assertionFailure()
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }

  @Test func assertionFailuresForAssertTrue() {
    let input = """
      assert(true)
      """
    testFormatting(for: input, rule: .assertionFailures)
  }

  @Test func assertionFailuresForAssertFalseWithArgs() {
    let input = """
      assert(false, msg, 20, 21)
      """
    let output = """
      assertionFailure(msg, 20, 21)
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }

  @Test func assertionFailuresForPreconditionFalse() {
    let input = """
      precondition(false)
      """
    let output = """
      preconditionFailure()
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }

  @Test func assertionFailuresForPreconditionTrue() {
    let input = """
      precondition(true)
      """
    testFormatting(for: input, rule: .assertionFailures)
  }

  @Test func assertionFailuresForPreconditionFalseWithArgs() {
    let input = """
      precondition(false, msg, 0, 1)
      """
    let output = """
      preconditionFailure(msg, 0, 1)
      """
    testFormatting(for: input, output, rule: .assertionFailures)
  }
}
