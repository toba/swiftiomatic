import Testing

@testable import Swiftiomatic

@Suite struct WrapConditionalBodiesTests {
  @Test func guardReturnWraps() {
    let input = """
      guard let foo = bar else { return }
      """
    let output = """
      guard let foo = bar else {
          return
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func emptyGuardReturnWithSpaceDoesNothing() {
    let input = """
      guard let foo = bar else { }
      """
    testFormatting(
      for: input, rule: .wrapConditionalBodies,
      exclude: [.emptyBraces],
    )
  }

  @Test func emptyGuardReturnWithoutSpaceDoesNothing() {
    let input = """
      guard let foo = bar else {}
      """
    testFormatting(
      for: input, rule: .wrapConditionalBodies,
      exclude: [.emptyBraces],
    )
  }

  @Test func guardReturnWithValueWraps() {
    let input = """
      guard let foo = bar else { return baz }
      """
    let output = """
      guard let foo = bar else {
          return baz
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardBodyWithClosingBraceAlreadyOnNewlineWraps() {
    let input = """
      guard foo else { return
      }
      """
    let output = """
      guard foo else {
          return
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardContinueWithNoSpacesToCleanupWraps() {
    let input = """
      guard let foo = bar else {continue}
      """
    let output = """
      guard let foo = bar else {
          continue
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardReturnWrapsSemicolonDelimitedStatements() {
    let input = """
      guard let foo = bar else { var baz = 0; let boo = 1; fatalError() }
      """
    let output = """
      guard let foo = bar else {
          var baz = 0; let boo = 1; fatalError()
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardReturnWrapsSemicolonDelimitedStatementsWithNoSpaces() {
    let input = """
      guard let foo = bar else {var baz=0;let boo=1;fatalError()}
      """
    let output = """
      guard let foo = bar else {
          var baz=0;let boo=1;fatalError()
      }
      """
    testFormatting(
      for: input, output, rule: .wrapConditionalBodies,
      exclude: [.spaceAroundOperators],
    )
  }

  @Test func guardReturnOnNewlineUnchanged() {
    let input = """
      guard let foo = bar else {
          return
      }
      """
    testFormatting(for: input, rule: .wrapConditionalBodies)
  }

  @Test func guardCommentSameLineUnchanged() {
    let input = """
      guard let foo = bar else { // Test comment
          return
      }
      """
    testFormatting(for: input, rule: .wrapConditionalBodies)
  }

  @Test func guardMultilineCommentSameLineUnchanged() {
    let input = """
      guard let foo = bar else { /* Test comment */ return }
      """
    let output = """
      guard let foo = bar else { /* Test comment */
          return
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardTwoMultilineCommentsSameLine() {
    let input = """
      guard let foo = bar else { /* Test comment 1 */ return /* Test comment 2 */ }
      """
    let output = """
      guard let foo = bar else { /* Test comment 1 */
          return /* Test comment 2 */
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func nestedGuardElseIfStatementsPutOnNewline() {
    let input = """
      guard let foo = bar else { if qux { return quux } else { return quuz } }
      """
    let output = """
      guard let foo = bar else {
          if qux {
              return quux
          } else {
              return quuz
          }
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func nestedGuardElseGuardStatementPutOnNewline() {
    let input = """
      guard let foo = bar else { guard qux else { return quux } }
      """
    let output = """
      guard let foo = bar else {
          guard qux else {
              return quux
          }
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func guardWithClosureOnlyWrapsElseBody() {
    let input = """
      guard foo { $0.bar } else { return true }
      """
    let output = """
      guard foo { $0.bar } else {
          return true
      }
      """
    testFormatting(
      for: input, output, rule: .wrapConditionalBodies,
      exclude: [.blankLinesAfterGuardStatements],
    )
  }

  @Test func ifElseReturnsWrap() {
    let input = """
      if foo { return bar } else if baz { return qux } else { return quux }
      """
    let output = """
      if foo {
          return bar
      } else if baz {
          return qux
      } else {
          return quux
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func ifElseBodiesWrap() {
    let input = """
      if foo { bar } else if baz { qux } else { quux }
      """
    let output = """
      if foo {
          bar
      } else if baz {
          qux
      } else {
          quux
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func ifElsesWithClosuresDontWrapClosures() {
    let input = """
      if foo { $0.bar } { baz } else if qux { $0.quux } { quuz } else { corge }
      """
    let output = """
      if foo { $0.bar } {
          baz
      } else if qux { $0.quux } {
          quuz
      } else {
          corge
      }
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }

  @Test func emptyIfElseBodiesWithSpaceDoNothing() {
    let input = """
      if foo { } else if baz { } else { }
      """
    testFormatting(
      for: input, rule: .wrapConditionalBodies,
      exclude: [.emptyBraces],
    )
  }

  @Test func emptyIfElseBodiesWithoutSpaceDoNothing() {
    let input = """
      if foo {} else if baz {} else {}
      """
    testFormatting(
      for: input, rule: .wrapConditionalBodies,
      exclude: [.emptyBraces],
    )
  }

  @Test func guardElseBraceStartingOnDifferentLine() {
    let input = """
      guard foo else
          { return bar }
      """
    let output = """
      guard foo else
          {
              return bar
          }
      """

    testFormatting(
      for: input, output, rule: .wrapConditionalBodies,
      exclude: [.braces, .indent, .elseOnSameLine],
    )
  }

  @Test func ifElseBracesStartingOnDifferentLines() {
    let input = """
      if foo
          { return bar }
      else if baz
          { return qux }
      else
          { return quux }
      """
    let output = """
      if foo
          {
              return bar
          }
      else if baz
          {
              return qux
          }
      else
          {
              return quux
          }
      """
    testFormatting(
      for: input, output, rule: .wrapConditionalBodies,
      exclude: [.braces, .indent, .elseOnSameLine],
    )
  }

  @Test func insideStringLiteralDoesNothing() {
    let input = """
      "\\(list.map { if $0 % 2 == 0 { return 0 } else { return 1 } })"
      """
    testFormatting(for: input, rule: .wrapConditionalBodies)
  }

  @Test func insideMultilineStringLiteral() {
    let input = """
      let foo = \"""
      \\(list.map { if $0 % 2 == 0 { return 0 } else { return 1 } })
      \"""
      """
    let output = """
      let foo = \"""
      \\(list.map { if $0 % 2 == 0 {
          return 0
      } else {
          return 1
      } })
      \"""
      """
    testFormatting(for: input, output, rule: .wrapConditionalBodies)
  }
}
