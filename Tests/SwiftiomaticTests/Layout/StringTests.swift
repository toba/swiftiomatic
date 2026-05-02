//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@testable import SwiftiomaticKit
import Testing

@Suite
struct StringTests: LayoutTesting {
  @Test func strings() {
    let input =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b = "A really long string that should not wrap"
      let c = "A really long string with \\(a + b) some expressions \\(c + d)"
      """

    let expected =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b =
        "A really long string that should not wrap"
      let c =
        "A really long string with \\(a + b) some expressions \\(c + d)"

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func longMultilinestringIsWrapped() {
    let input =
      #"""
      let someString = """
        this string's total lengths will be longer than the column limit even though its individual lines are as well, whoops.
        """
      """#

    let expected =
      #"""
      let someString = """
        this string's total \
        lengths will be longer \
        than the column limit even \
        though its individual \
        lines are as well, whoops.
        """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(
      input: input,
      expected: expected,
      linelength: 30,
      configuration: config
    )
  }

  @Test func multilineStringIsNotReformattedWithIgnore() {
    let input =
      #"""
      let someString =  // sm:ignore
        """
        lines \
        are \
        short.
        """
      """#

    let expected =
      #"""
      let someString =  // sm:ignore
        """
        lines \
        are \
        short.
        """

      """#

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func multilineStringIsNotReformattedWithReflowDisabled() {
    let input =
      #"""
      let someString =
        """
        lines \
        are \
        short.
        """
      """#

    let expected =
      #"""
      let someString = """
        lines \
        are \
        short.
        """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(input: input, expected: expected, linelength: 30, configuration: config)
  }

  @Test func multilineStringWithInterpolations() {
    let input =
      #"""
      if true {
        guard let opt else {
          functionCall("""
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero \(2) \(testVariable) ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, rhoncus leo. Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
            """)
        }
      }
      """#

    let expected =
      #"""
      if true {
        guard let opt else {
          functionCall(
            """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero \(2) \
            \(testVariable) ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In \
            vitae purus feugiat, euismod nulla in, rhoncus leo. Suspendisse feugiat sapien lobortis \
            facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel \
            blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
            """)
        }
      }

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(input: input, expected: expected, linelength: 100, configuration: config)
  }

  @Test func mutlilineStringsRespectsHardLineBreaks() {
    let input =
      #"""
      """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, rhoncus leo.
      Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
      """
      """#

    let expected =
      #"""
      """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero ids risus placerat \
      imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, \
      rhoncus leo.
      Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. \
      Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt \
      efficitur ante id fermentum.
      """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(input: input, expected: expected, linelength: 100, configuration: config)
  }

  @Test func multilineStringsWrapAroundInterpolations() {
    let input =
      #"""
      """
      An interpolation should be treated as a single "word" and can't be broken up \(aLongVariableName + anotherLongVariableName), so no line breaks should be available within the expr.
      """
      """#

    let expected =
      #"""
      """
      An interpolation should be treated as a single "word" and can't be broken up \
      \(aLongVariableName + anotherLongVariableName), so no line breaks should be available within the \
      expr.
      """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(input: input, expected: expected, linelength: 100, configuration: config)
  }

  @Test func multilineStringOpenQuotesDoNotWrapIfStringIsVeryLong() {
    let input =
      #"""
      let someString = """
        this string's total
        length will be longer
        than the column limit
        even though none of
        its individual lines
        are.
        """
      """#

    assertLayout(input: input, expected: input + "\n", linelength: 30)
  }

  @Test func multilineStringWithAssignmentOperatorInsteadOfPatternBinding() {
    let input =
      #"""
      someString = """
        this string's total
        length will be longer
        than the column limit
        even though none of
        its individual lines
        are.
        """
      """#

    assertLayout(input: input, expected: input + "\n", linelength: 30)
  }

  @Test func multilineStringUnlabeledArgumentIsReindentedCorrectly() {
    let input =
      #"""
      functionCall(longArgument, anotherLongArgument, """
            some multi-
              line string
            """)
      """#

    let expected =
      #"""
      functionCall(
        longArgument,
        anotherLongArgument,
        """
        some multi-
          line string
        """)

      """#

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func multilineStringLabeledArgumentIsReindentedCorrectly() {
    let input =
      #"""
      functionCall(longArgument: x, anotherLongArgument: y, longLabel: """
            some multi-
              line string
            """)
      """#

    let expected =
      #"""
      functionCall(
        longArgument: x,
        anotherLongArgument: y,
        longLabel: """
          some multi-
            line string
          """)

      """#

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func multilineStringWithWordLongerThanLineLength() {
    let input =
      #"""
      """
      there isn't an opportunity to break up this long url: https://www.cool-math-games.org/games/id?=01913310-b7c3-77d8-898e-300ccd451ea8
      """
      """#
    let expected =
      #"""
      """
      there isn't an opportunity to break up this long url: \
      https://www.cool-math-games.org/games/id?=01913310-b7c3-77d8-898e-300ccd451ea8
      """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .onlyLinesOverLength
    assertLayout(input: input, expected: expected, linelength: 70, configuration: config)
  }

  @Test func multilineStringInterpolations() {
    let input =
      #"""
      let x = """
        \(1) 2 3
        4 \(5) 6
        7 8 \(9)
        """
      """#

    assertLayout(input: input, expected: input + "\n", linelength: 25)
  }

  @Test func multilineRawString() {
    let input =
      ##"""
      let x = #"""
        """who would
        ever do this"""
        """#
      """##

    assertLayout(input: input, expected: input + "\n", linelength: 25)
  }

  @Test func multilineRawStringOpenQuotesWrap() {
    let input =
      #"""
      let aLongVariableName = """
        some
        multi-
        line
        string
        """
      """#

    let expected =
      #"""
      let aLongVariableName =
        """
        some
        multi-
        line
        string
        """

      """#

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func multilineStringAutocorrectMisalignedLines() {
    let input =
      #"""
      let x = """
          the
        second
          line is
          wrong
          """
      """#

    let expected =
      #"""
      let x = """
        the
        second
        line is
        wrong
        """

      """#

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func multilineStringKeepsBlankLines() {
    // This test not only ensures that the blank lines are retained in the first place, but that
    // the newlines are mandatory and not collapsed to the maximum number allowed by the formatter
    // configuration.
    let input =
      #"""
      let x = """


          there should be




          gaps all around here


          """
      """#

    let expected =
      #"""
      let x = """


        there should be




        gaps all around here


        """

      """#

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func multilineStringReflowsTrailingBackslashes() {
    let input =
      #"""
      let x = """
          there should be \
          backslashes at \
          the end of \
          every line \
          except this one
          """
      """#

    let expected =
      #"""
      let x = """
        there should be \
        backslashes at \
        the end of every \
        line except this \
        one
        """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .always
    assertLayout(input: input, expected: expected, linelength: 20, configuration: config)
  }

  @Test func rawMultilineStringIsNotFormatted() {
    let input =
      ##"""
      #"""
      this is a long line that is not broken.
      """#
      """##
    let expected =
      ##"""
      #"""
      this is a long line that is not broken.
      """#

      """##

    assertLayout(input: input, expected: expected, linelength: 10)
  }

  @Test func multilineStringIsNotFormattedWithNeverReflowBehavior() {
    let input =
      #"""
      """
      this is a long line that is not broken.
      """
      """#
    let expected =
      #"""
      """
      this is a long line that is not broken.
      """

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .never
    assertLayout(input: input, expected: expected, linelength: 10, configuration: config)
  }

  @Test func multilineStringWithInterpolationsNotMangledWithNeverReflow() {
    // Regression for issue 9yv-e8j: with reflow=never, a multiline string with `\(...)`
    // interpolations must not have its content reflowed and its interpolations must remain
    // atomic — splitting an interpolation across lines produces "Insufficient indentation"
    // errors in the resulting Swift source.
    let input =
      #"""
      func foo() -> String {
        return """
          @Dependency(\(argument)) has no live implementation, but was accessed from a live context.

          \(dependencyDescription)

          • Conform '\(typeName(Key.self))' to the 'DependencyKey' protocol by providing a live implementation of your dependency.
          """
      }
      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .never
    assertLayout(input: input, expected: input + "\n", linelength: 100, configuration: config)
  }

  @Test func multilineStringWithPreSplitInterpolationKeepsValidIndent() {
    // Regression for issue 9yv-e8j (reopened): when an interpolation `\(...)` is already
    // split across multiple source lines (or a `\(typeName(Key\n    .self))` chain spans
    // lines), the formatter must not emit raw newlines from inside the interpolation into
    // the output, because subsequent string segments on those lines fall below the closing
    // `"""` indent — producing a Swift compile error:
    //   "Insufficient indentation of line in multi-line string literal"
    let input =
      #"""
      func foo() -> String {
        return """
          @Dependency(\(
            argument
          )) has no live implementation, but was accessed from a live \
          context.

          \(dependencyDescription)

          • Conform '\(typeName(Key
              .self))' to the 'DependencyKey' protocol by providing \
          a live implementation of your dependency.
          """
      }
      """#

    let expected =
      #"""
      func foo() -> String {
        return """
          @Dependency(\(argument)) has no live implementation, but was accessed from a live \
          context.

          \(dependencyDescription)

          • Conform '\(typeName(Key.self))' to the 'DependencyKey' protocol by providing \
          a live implementation of your dependency.
          """
      }

      """#

    var config = Configuration.forTesting
    config[ReflowMultilineStringLiterals.self] = .never
    assertLayout(input: input, expected: expected, linelength: 200, configuration: config)
  }

  @Test func multilineStringInParenthesizedExpression() {
    let input =
      #"""
      let x = ("""
          this is a
          multiline string
          """)
      """#

    let expected =
      #"""
      let x =
        ("""
        this is a
        multiline string
        """)

      """#

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func multilineStringAfterStatementKeyword() {
    let input =
      #"""
      return """
          this is a
          multiline string
          """
      return """
          this is a
          multiline string
          """ + "hello"
      """#

    let expected =
      #"""
      return """
        this is a
        multiline string
        """
      return """
        this is a
        multiline string
        """ + "hello"

      """#

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func multilineStringsInExpressionWithNarrowMargins() {
    let input =
      #"""
      x = """
          abcdefg
          hijklmn
          """ + """
          abcde
          hijkl
          """
      """#

    let expected =
      #"""
      x = """
        abcdefg
        hijklmn
        """
          + """
          abcde
          hijkl
          """

      """#

    assertLayout(input: input, expected: expected, linelength: 9)
  }

  @Test func multilineStringsInExpression() {
    let input =
      #"""
      let x = """
          this is a
          multiline string
          """ + """
          this is more
          multiline string
          """
      """#

    let expected =
      #"""
      let x = """
      this is a
      multiline string
      """ + """
        this is more
        multiline string
        """

      """#

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func leadingMultilineStringsInOtherExpressions() {
    // The stacked indentation behavior needs to drill down into different node types to find the
    // leftmost multiline string literal. This makes sure that we cover various cases.
    let input =
      #"""
      let bytes = """
        {
          "key": "value"
        }
        """.utf8.count
      let json = """
        {
          "key": "value"
        }
        """.data(using: .utf8)
      let slice = """
        {
          "key": "value"
        }
        """[...]
      let forceUnwrap = """
        {
          "key": "value"
        }
        """!
      let optionalChaining = """
        {
          "key": "value"
        }
        """?
      let postfix = """
        {
          "key": "value"
        }
        """^*^
      let prefix = +"""
        {
          "key": "value"
        }
        """
      let postfixIf = """
        {
          "key": "value"
        }
        """
        #if FLAG
          .someMethod
        #endif

      // Cast operations no longer force the string's open quotes to wrap because the break after
      // `=` ignores discretionary line breaks. The quotes stay on the same line when it fits.
      let cast =
        """
        {
          "key": "value"
        }
        """ as NSString
      let typecheck =
        """
        {
          "key": "value"
        }
        """ is NSString
      """#

    let expected =
      #"""
      let bytes = """
      {
        "key": "value"
      }
      """.utf8.count
      let json = """
      {
        "key": "value"
      }
      """.data(using: .utf8)
      let slice = """
      {
        "key": "value"
      }
      """[...]
      let forceUnwrap = """
        {
          "key": "value"
        }
        """!
      let optionalChaining = """
        {
          "key": "value"
        }
        """?
      let postfix = """
        {
          "key": "value"
        }
        """^*^
      let prefix = +"""
        {
          "key": "value"
        }
        """
      let postfixIf = """
        {
          "key": "value"
        }
        """
        #if FLAG
          .someMethod
        #endif

      // Cast operations no longer force the string's open quotes to wrap because the break after
      // `=` ignores discretionary line breaks. The quotes stay on the same line when it fits.
      let cast = """
        {
          "key": "value"
        }
        """ as NSString
      let typecheck = """
        {
          "key": "value"
        }
        """ is NSString

      """#
    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func multilineStringsAsEnumRawValues() {
    let input = #"""
      enum E: String {
        case x = """
          blah blah
          """
      }
      """#
    assertLayout(input: input, expected: input + "\n", linelength: 100)
  }

  @Test func multilineStringsNestedInAnotherWrappingContext() {
    let input =
      #"""
      guard
          let x = """
              blah
              blah
              """.data(using: .utf8) else {
          print(x)
      }
      """#

    let expected =
      #"""
      guard
        let x = """
          blah
          blah
          """.data(using: .utf8)
      else {
        print(x)
      }

      """#
    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func emptyMultilineStrings() {
    let input =
      ##"""
      let x = """
        """
      let y =
        """
        """
      let x = #"""
        """#
      let y =
        #"""
        """#
      """##

    let expected =
      ##"""
      let x = """
        """
      let y = """
        """
      let x = #"""
        """#
      let y = #"""
        """#

      """##

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func onlyBlankLinesMultilineStrings() {
    let input =
      ##"""
      let x = """

        """
      let y =
        """

        """
      let x = #"""

        """#
      let y =
        #"""

        """#
      """##

    let expected =
      ##"""
      let x = """

        """
      let y = """

        """
      let x = #"""

        """#
      let y = #"""

        """#

      """##

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  // Regression: a long string-literal argument should not be wrapped onto its own line when
  // wrapping doesn't bring the line below the limit. A continuation break before such a string
  // is suppressed by the savings-threshold heuristic when wrapping wouldn't meaningfully shorten
  // the line.
  @Test func longStringArgumentStaysOnLabelLineWhenWrapDoesNotHelp() {
    let input =
      #"""
      func expectNodesNotFound(_ ids: [Node.ID]) async throws {
        let count = try await sqlite.read { try Int.fetchOne(
          $0,
          sql: "SELECT COUNT(*) FROM node WHERE id IN (\(repeatElement("?", count: ids.count).joined(separator: ", ")));",
          arguments: StatementArguments(ids)
        ) ?? 0 }

        #expect(count == 0)
      }
      """#

    // Closure body still expands onto its own line — that is a separate layout issue tracked
    // outside this test. The point here is that `sql: "..."` does not get a wrap before the
    // string literal: the string already overflows even at the wrapped column, so wrapping
    // would just make the layout uglier without bringing the line under the limit.
    let expected =
      #"""
      func expectNodesNotFound(_ ids: [Node.ID]) async throws {
        let count = try await sqlite.read {
          try Int.fetchOne(
            $0,
            sql: "SELECT COUNT(*) FROM node WHERE id IN (\(repeatElement("?", count: ids.count).joined(separator: ", ")));",
            arguments: StatementArguments(ids)
          ) ?? 0
        }

        #expect(count == 0)
      }

      """#

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func multilineStringWithContinuations() {
    let input =
      ##"""
      let someString =
        """
        lines \
        \nare \
        short.
        """
      let someString =
        #"""
        lines \#
        \#nare \#
        short.
        """#
      """##

    let expected =
      ##"""
      let someString = """
        lines \
        \nare \
        short.
        """
      let someString = #"""
        lines \#
        \#nare \#
        short.
        """#

      """##

    assertLayout(input: input, expected: expected, linelength: 30)
  }
}
