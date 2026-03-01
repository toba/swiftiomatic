import Testing

@testable import Swiftiomatic

extension IndentTests {
  // indent comments

  @Test func commentIndenting() {
    let input = """
      /* foo
      bar */
      """
    let output = """
      /* foo
       bar */
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func commentIndentingWithTrailingClose() {
    let input = """
      /*
      foo
      */
      """
    let output = """
      /*
       foo
       */
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func commentIndentingWithTrailingClose2() {
    let input = """
      /* foo
      */
      """
    let output = """
      /* foo
       */
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func nestedCommentIndenting() {
    let input = """
      /*
       class foo() {
           /*
            * Nested comment
            */
           bar {}
       }
       */
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func nestedCommentIndenting2() {
    let input = """
      /*
      Some description;
      ```
      func foo() {
          bar()
      }
      ```
      */
      """
    let output = """
      /*
       Some description;
       ```
       func foo() {
           bar()
       }
       ```
       */
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func commentedCodeBlocksNotIndented() {
    let input = """
      func foo() {
      //    var foo: Int
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func blankCodeCommentBlockLinesNotIndented() {
    let input = """
      func foo() {
      //
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func commentedCodeAfterBracketNotIndented() {
    let input = """
      let foo = [
      //    first,
          second,
      ]
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func commentedCodeAfterBracketNotIndented2() {
    let input = """
      let foo = [first,
      //           second,
                 third]
      """
    testFormatting(for: input, rule: .indent)
  }

  // TODO: maybe need special case handling for this?
  @Test func indentWrappedTrailingComment() {
    let input = """
      let foo = 5 // a wrapped
                  // comment
                  // block
      """
    let output = """
      let foo = 5 // a wrapped
      // comment
      // block
      """
    testFormatting(for: input, output, rule: .indent)
  }

  // indent multiline strings

  @Test func simpleMultilineString() {
    let input = """
      \"\"\"
          hello
          world
      \"\"\"
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentIndentedSimpleMultilineString() {
    let input = """
      {
      \"\"\"
          hello
          world
          \"\"\"
      }
      """
    let output = """
      {
          \"\"\"
          hello
          world
          \"\"\"
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func multilineStringWithEscapedLinebreak() {
    let input = """
      \"\"\"
          hello \
          world
      \"\"\"
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineStringWrappedAfter() {
    let input = """
      foo(baz:
          \"\""
          baz
          \"\"")
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineStringInNestedCalls() {
    let input = """
      foo(bar(\"\""
      baz
      \"\""))
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineStringInFunctionWithfollowingArgument() {
    let input = """
      foo(bar(\"\""
      baz
      \"\"", quux: 5))
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func reduceIndentForMultilineString() {
    let input = """
      switch foo {
          case bar:
              return \"\""
              baz
              \"\""
      }
      """
    let output = """
      switch foo {
      case bar:
          return \"\""
          baz
          \"\""
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func reduceIndentForMultilineString2() {
    let input = """
          foo(\"\""
          bar
          \"\"")
      """
    let output = """
      foo(\"\""
      bar
      \"\"")
      """
    testFormatting(for: input, output, rule: .indent)
  }

  @Test func indentMultilineStringWithMultilineInterpolation() {
    let input = """
      func foo() {
          \"\""
              bar
                  \\(bar.map {
                      baz
                  })
              quux
          \"\""
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineStringWithMultilineNestedInterpolation() {
    let input = """
      func foo() {
          \"\""
              bar
                  \\(bar.map {
                      \"\""
                          quux
                      \"\""
                  })
              quux
          \"\""
      }
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func indentMultilineStringWithMultilineNestedInterpolation2() {
    let input = """
      func foo() {
          \"\""
              bar
                  \\(bar.map {
                      \"\""
                          quux
                      \"\""
                  }
                  )
              quux
          \"\""
      }
      """
    testFormatting(for: input, rule: .indent, exclude: [.wrapArguments])
  }

  // indentStrings = true

  @Test func indentMultilineStringInMethod() {
    let input = #"""
      func foo() {
          let sql = """
          SELECT *
          FROM authors
          WHERE authors.name LIKE '%David%'
          """
      }
      """#
    let output = #"""
      func foo() {
          let sql = """
              SELECT *
              FROM authors
              WHERE authors.name LIKE '%David%'
              """
      }
      """#
    let options = FormatOptions(indentStrings: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func noIndentMultilineStringWithOmittedReturn() {
    let input = #"""
      var string: String {
          """
          SELECT *
          FROM authors
          WHERE authors.name LIKE '%David%'
          """
      }
      """#
    let options = FormatOptions(indentStrings: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func noIndentMultilineStringOnOwnLineInMethodCall() {
    let input = #"""
      #expect(loggingService.assertions == """
          My long multi-line assertion.
          This error was not recoverable.
          """)
      """#
    let options = FormatOptions(indentStrings: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func indentMultilineStringInMethodCall() {
    let input = #"""
      #expect(loggingService.assertions == """
      My long multi-line assertion.
      This error was not recoverable.
      """)
      """#
    let output = #"""
      #expect(loggingService.assertions == """
          My long multi-line assertion.
          This error was not recoverable.
          """)
      """#
    let options = FormatOptions(indentStrings: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentMultilineStringAtTopLevel() {
    let input = #"""
      let sql = """
      SELECT *
      FROM  authors,
            books
      WHERE authors.name LIKE '%David%'
           AND pubdate < $1
      """
      """#
    let output = #"""
      let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
      """#
    let options = FormatOptions(indent: "  ", indentStrings: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentMultilineStringWithBlankLine() {
    let input = #"""
      let generatedClass = """
      import UIKit

      class ViewController: UIViewController { }
      """
      """#

    let output = #"""
      let generatedClass = """
          import UIKit
      \#("    ")
          class ViewController: UIViewController { }
          """
      """#
    let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentMultilineStringPreservesBlankLines() {
    let input = #"""
      let generatedClass = """
          import UIKit
      \#("    ")
          class ViewController: UIViewController { }
          """
      """#
    let options = FormatOptions(truncateBlankLines: false, indentStrings: true)
    testFormatting(for: input, rule: .indent, options: options)
  }

  @Test func unindentMultilineStringAtTopLevel() {
    let input = #"""
      let sql = """
        SELECT *
        FROM  authors,
              books
        WHERE authors.name LIKE '%David%'
             AND pubdate < $1
        """
      """#
    let output = #"""
      let sql = """
      SELECT *
      FROM  authors,
            books
      WHERE authors.name LIKE '%David%'
           AND pubdate < $1
      """
      """#
    let options = FormatOptions(indent: "  ", indentStrings: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentUnderIndentedMultilineStringPreservesBlankLineIndent() {
    let input = #"""
      class Main {
          func main() {
              print("""
          That've been not indented at all.
          \#n\#
          After SwiftFormat it causes a compiler error in the line above.
          """)
          }
      }
      """#
    let output = #"""
      class Main {
          func main() {
              print("""
              That've been not indented at all.
              \#n\#
              After SwiftFormat it causes a compiler error in the line above.
              """)
          }
      }
      """#
    let options = FormatOptions(truncateBlankLines: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  @Test func indentUnderIndentedMultilineStringDoesNotAddIndent() {
    let input = #"""
      class Main {
          func main() {
              print("""
          That've been not indented at all.

          After SwiftFormat it causes a compiler error in the line above.
          """)
          }
      }
      """#
    let output = #"""
      class Main {
          func main() {
              print("""
              That've been not indented at all.
          \#("    ")
              After SwiftFormat it causes a compiler error in the line above.
              """)
          }
      }
      """#
    let options = FormatOptions(truncateBlankLines: false)
    testFormatting(for: input, output, rule: .indent, options: options)
  }

  // indent multiline raw strings

  @Test func indentIndentedSimpleRawMultilineString() {
    let input = """
      {
      ##\"\"\"
          hello
          world
          \"\"\"##
      }
      """
    let output = """
      {
          ##\"\"\"
          hello
          world
          \"\"\"##
      }
      """
    testFormatting(for: input, output, rule: .indent)
  }

  // indent multiline regex literals

  @Test func indentMultilineRegularExpression() {
    let input = """
      let regex = #/
          (foo+)
          [bar]*
          (baz?)
      /#
      """
    testFormatting(for: input, rule: .indent)
  }

  @Test func noMisindentCasePath() {
    let input = """
      reducer.pullback(
          casePath: /Action.action,
          environment: {}
      )
      """
    testFormatting(for: input, rule: .indent)
  }

}
