import Testing

@testable import Swiftiomatic

@Suite struct WrapMultilineConditionalAssignmentTests {
  @Test func wrapIfExpressionAssignment() {
    let input = """
      let foo = if let bar {
          bar
      } else {
          baaz
      }
      """

    let output = """
      let foo =
          if let bar {
              bar
          } else {
              baaz
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }

  @Test func unwrapsAssignmentOperatorInIfExpressionAssignment() {
    let input = """
      let foo
          = if let bar {
              bar
          } else {
              baaz
          }
      """

    let output = """
      let foo =
          if let bar {
              bar
          } else {
              baaz
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }

  @Test func unwrapsAssignmentOperatorInIfExpressionFollowingComment() {
    let input = """
      let foo
          // In order to unwrap the `=` here it has to move it to
          // before the comment, rather than simply unwrapping it.
          = if let bar {
              bar
          } else {
              baaz
          }
      """

    let output = """
      let foo =
          // In order to unwrap the `=` here it has to move it to
          // before the comment, rather than simply unwrapping it.
          if let bar {
              bar
          } else {
              baaz
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }

  @Test func wrapIfAssignmentWithoutIntroducer() {
    let input = """
      property = if condition {
          Foo("foo")
      } else {
          Foo("bar")
      }
      """

    let output = """
      property =
          if condition {
              Foo("foo")
          } else {
              Foo("bar")
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }

  @Test func wrapSwitchAssignmentWithoutIntroducer() {
    let input = """
      property = switch condition {
      case true:
          Foo("foo")
      case false:
          Foo("bar")
      }
      """

    let output = """
      property =
          switch condition {
          case true:
              Foo("foo")
          case false:
              Foo("bar")
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }

  @Test func wrapSwitchAssignmentWithComplexLValue() {
    let input = """
      property?.foo!.bar["baaz"] = switch condition {
      case true:
          Foo("foo")
      case false:
          Foo("bar")
      }
      """

    let output = """
      property?.foo!.bar["baaz"] =
          switch condition {
          case true:
              Foo("foo")
          case false:
              Foo("bar")
          }
      """

    testFormatting(for: input, [output], rules: [.wrapMultilineConditionalAssignment, .indent])
  }
}
