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

import SwiftiomaticKit
import SwiftiomaticTestSupport
import Testing

@Suite
struct CommentTests: LayoutTesting {
  @Test func documentationComments() {
    let input =
      """
      /// This is a documentation comment
      ///
      /// - Parameters:
      ///   - param1: Param1 comment
      ///   - param2: Param2 comment
      /// - Returns: The output
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /// A brief doc comment
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /// Doc comment
        var myVariable: Int

        /// Method doc comment
        ///
        /// - Parameters:
        ///   - param1: Param1 comment
        ///   - param2: Param2 comment
        /// - Returns: The output
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }
      """

    let expected =
      """
      /// This is a documentation comment
      ///
      /// - Parameters:
      ///   - param1: Param1 comment
      ///   - param2: Param2 comment
      /// - Returns: The output
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /// A brief doc comment
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /// Doc comment
        var myVariable: Int

        /// Method doc comment
        ///
        /// - Parameters:
        ///   - param1: Param1 comment
        ///   - param2: Param2 comment
        /// - Returns: The output
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 55)
  }

  @Test func lineComments() {
    let input =
      """
      // Line Comment0

      // Line Comment1
      // Line Comment2
      let a = 123
      let b = "456"  // End of line comment
      let c = "More content"

      // Comment 3
      // Comment 4

      let reallyLongVariableName = 123 // This comment should not wrap
      // and should not combine with this comment

      func MyFun() {
        // just a comment
      }

      func MyFun() {
        // Comment 1
        // Comment 2
        let a = 123

        let b = 456  // Comment 3
      }

      func MyFun() {
        let c = 789 // Comment 4
        // Comment 5
      }

      let a = myfun(123 // Cmt 7
      )
      let a = myfun(var1: 123 // Cmt 7
      )

      guard condition else { return // Cmt 6
      }

      switch myvar {
      case .one, .two, // three
           .four:
        dostuff()
      default: ()
      }

      let a = 123 +  // comment
        b + c

      let d = 123
      // Trailing Comment
      """

    let expected =
      """
      // Line Comment0

      // Line Comment1
      // Line Comment2
      let a = 123
      let b = "456"  // End of line comment
      let c = "More content"

      // Comment 3
      // Comment 4

      let reallyLongVariableName = 123  // This comment should not wrap
      // and should not combine with this comment

      func MyFun() {
        // just a comment
      }

      func MyFun() {
        // Comment 1
        // Comment 2
        let a = 123

        let b = 456  // Comment 3
      }

      func MyFun() {
        let c = 789  // Comment 4
        // Comment 5
      }

      let a = myfun(
        123  // Cmt 7
      )
      let a = myfun(
        var1: 123  // Cmt 7
      )

      guard condition else {
        return  // Cmt 6
      }

      switch myvar {
      case .one, .two,  // three
        .four:
        dostuff()
      default: ()
      }

      let a = 123  // comment
        + b + c

      let d = 123
      // Trailing Comment

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func lineCommentsWithCustomLeadingSpaces() {
    let pairs: [(String, String)] = [
      (
        """
        // Line Comment0

        // Line Comment1
        // Line Comment2
        let a = 123
        let b = "456"  // End of line comment
        let c = "More content"

        """,
        """
        // Line Comment0

        // Line Comment1
        // Line Comment2
        let a = 123
        let b = "456"   // End of line comment
        let c = "More content"

        """
      ),
      (
        """
        // Comment 3
        // Comment 4

        let reallyLongVariableName = 123 // This comment should not wrap
        // and should not combine with this comment

        func MyFun() {
          // just a comment
        }
        """,
        """
        // Comment 3
        // Comment 4

        let reallyLongVariableName = 123   // This comment should not wrap
        // and should not combine with this comment

        func MyFun() {
          // just a comment
        }

        """
      ),
      (
        """
        func MyFun() {
          // Comment 1
          // Comment 2
          let a = 123

          let b = 456  // Comment 3
        }

        func MyFun() {
          let c = 789 // Comment 4
          // Comment 5
        }
        """,
        """
        func MyFun() {
          // Comment 1
          // Comment 2
          let a = 123

          let b = 456   // Comment 3
        }

        func MyFun() {
          let c = 789   // Comment 4
          // Comment 5
        }

        """
      ),
      (
        """
        let a = myfun(123 // Cmt 7
        )
        let a = myfun(var1: 123 // Cmt 7
        )

        guard condition else { return // Cmt 6
        }

        switch myvar {
        case .one, .two, // three
             .four:
          dostuff()
        default: ()
        }

        """,
        """
        let a = myfun(
          123   // Cmt 7
        )
        let a = myfun(
          var1: 123   // Cmt 7
        )

        guard condition else {
          return   // Cmt 6
        }

        switch myvar {
        case .one, .two,   // three
          .four:
          dostuff()
        default: ()
        }

        """
      ),
      (
        """
        let a = 123 +  // comment
          b + c

        let d = 123
        // Trailing Comment
        """,
        """
        let a = 123   // comment
          + b + c

        let d = 123
        // Trailing Comment

        """
      ),
    ]

    var config = Configuration.forTesting
    config[SpacesBeforeEndOfLineComments.self] = 3
    for (input, expected) in pairs {
      assertLayout(input: input, expected: expected, linelength: 45, configuration: config)
    }
  }

  @Test func containerLineComments() {
    let input =
      """
      // Array comment
      let a = [456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456, // small comment
        "def": 789]

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      // Multiline comment
      let d = [123,
        // comment line 1
        // comment line 2
        456
      ]

      /* Array comment */
      let a = [456, /* small comment */
        789]

      /* Dictionary comment */
      let b = ["abc": 456, /* small comment */
        "def": 789]
      """

    let expected =
      """
      // Array comment
      let a = [
        456,  // small comment
        789,
      ]

      // Dictionary comment
      let b = [
        "abc": 456,  // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [
        123, 456,  // small comment
      ]

      // Multiline comment
      let d = [
        123,
        // comment line 1
        // comment line 2
        456,
      ]

      /* Array comment */
      let a = [
        456, /* small comment */
        789,
      ]

      /* Dictionary comment */
      let b = [
        "abc": 456, /* small comment */
        "def": 789,
      ]

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func containerLineCommentsWithCustomLeadingSpaces() {
    let input =
      """
      // Array comment
      let a = [456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456, // small comment
        "def": 789]

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      // Multiline comment
      let d = [123,
        // comment line 1
        // comment line 2
        456
      ]

      /* Array comment */
      let a = [456, /* small comment */
        789]

      /* Dictionary comment */
      let b = ["abc": 456, /* small comment */
        "def": 789]
      """

    let expected =
      """
      // Array comment
      let a = [
        456, // small comment
        789,
      ]

      // Dictionary comment
      let b = [
        "abc": 456, // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [
        123, 456, // small comment
      ]

      // Multiline comment
      let d = [
        123,
        // comment line 1
        // comment line 2
        456,
      ]

      /* Array comment */
      let a = [
        456, /* small comment */
        789,
      ]

      /* Dictionary comment */
      let b = [
        "abc": 456, /* small comment */
        "def": 789,
      ]

      """
    var config = Configuration.forTesting
    config[SpacesBeforeEndOfLineComments.self] = 1
    assertLayout(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func documentationBlockComments() {
    let input =
      """
      /** This is a documentation comment
       *
       * - Parameters:
       *   - param1: Param1 comment
       *   - param2: Param2 comment
       * - Returns: The output
      **/
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /** A brief doc comment **/
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /** Doc comment **/
        var myVariable: Int

        /** Method doc comment
         *
         * - Parameters:
         *   - param1: Param1 comment
         *   - param2: Param2 comment
         * - Returns: The output
        **/
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }
      """

    let expected =
      """
      /** This is a documentation comment
       *
       * - Parameters:
       *   - param1: Param1 comment
       *   - param2: Param2 comment
       * - Returns: The output
      **/
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /** A brief doc comment **/
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /** Doc comment **/
        var myVariable: Int

        /** Method doc comment
         *
         * - Parameters:
         *   - param1: Param1 comment
         *   - param2: Param2 comment
         * - Returns: The output
        **/
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 55)
  }

  @Test func blockComments() {
    let input =
      """
              /* Line Comment1 */
      /* Line Comment2 */
      let a = 123
      let b = "456"  /* End of line comment */
      let c = "More content"

            /* Comment 3
               Comment 4 */

      let reallyLongVariableName = 123  /* This comment should wrap */

      let a = myfun(123 /* Cmt 5 */
      )
      let a = myfun(var1: 123 /* Cmt 5 */
      )

      guard condition else { return /* Cmt 6 */
      }

      let d = 123
        /* Trailing Comment */
        /* Trailing
           Block Comment */
      """

    let expected =
      """
      /* Line Comment1 */
      /* Line Comment2 */
      let a = 123
      let b = "456" /* End of line comment */
      let c = "More content"

      /* Comment 3
         Comment 4 */

      let reallyLongVariableName =
        123 /* This comment should wrap */

      let a = myfun(
        123 /* Cmt 5 */
      )
      let a = myfun(
        var1: 123 /* Cmt 5 */
      )

      guard condition else {
        return /* Cmt 6 */
      }

      let d = 123
      /* Trailing Comment */
      /* Trailing
         Block Comment */

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func doesNotInsertExtraNewlinesAfterTrailingComments() {
    let input =
      """
      struct Foo {
        var foo: Int  // foo
        var bar: Int  // bar
      }

      enum Foo {
        case foo
        case bar  // bar
        case baz  // baz
        case quux
      }
      """

    let expected =
      """
      struct Foo {
        var foo: Int  // foo
        var bar: Int  // bar
      }

      enum Foo {
        case foo
        case bar  // bar
        case baz  // baz
        case quux
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func commentOnContinuationLine() {
    let input =
      """
      func foo() {
        return true
          // comment
          && false
      }

      func foo() {
        return
          // comment
          false
      }

      struct Foo {
        typealias Bar =
          // comment
          SomeOtherType
      }
      """

    assertLayout(input: input, expected: input + "\n", linelength: 60)
  }

  @Test func lineCommentAtEndOfMemberDeclList() {
    let input =
      """
      enum Foo {
        case bar
          // This should be indented the same as the previous line
      }
      """

    let expected =
      """
      enum Foo {
        case bar
        // This should be indented the same as the previous line
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func commentsAroundIfElseStatements() {
    let input =
      """
      if foo {
      }// Comment about else-if
      else // comment about else
      if bar {
      }
      // another comment
      else
      {
      }
      """

    let expected =
      """
      if foo {
      }  // Comment about else-if
      else  // comment about else
      if bar {
      }
      // another comment
      else {
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func commentsMoveAroundOperators() {
    let input =
      """
      let x = a +  // comment about b
        b
      let x =  // comment about RHS
        a + b + c
      x = a + b +
      // comment about c
      c
      x = a + /* block */
      // line 2
      b
      x = a + // comment 1

      // comment 2

      b
      """

    let expected =
      """
      let x = a  // comment about b
        + b
      let x =  // comment about RHS
        a + b + c
      x = a + b
        // comment about c
        + c
      x = a
        // line 2
        + /* block */ b
      x = a  // comment 1

        // comment 2

        + b

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func commentsAllowedInParenthesizedExpressions() {
    // There is no group applied outside of single element tuples that don't contain sequence
    // expressions, hence the examples with a tuple wrapping `foo()` and a tuple wrapping a
    // multiline string don't break before the left paren.
    let input =
      #"""
      let x = (// call foo
        foo())
      x = (// do some addition
        x + y)
      x = (
        // localize this string?
        // second line of comment
        // third line of comment
        """
        This is a multiline string inside of a multiline
        string!
        """)
      """#

    let expected =
      #"""
      let x = (  // call foo
        foo())
      x =
        (  // do some addition
          x + y)
      x = (
        // localize this string?
        // second line of comment
        // third line of comment
        """
        This is a multiline string inside of a multiline
        string!
        """)

      """#

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func operatorOnNewLineWithTrailingLineComment() {
    let input =
      """
      if next
        && // final is important
        // second line about final
        final
      {
      }
      """

    let expected =
      """
      if next
        // final is important
        // second line about final
        && final
      {
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func operatorOnSameLineWithTrailingLineComment() {
    let input =
      """
      if next && // final is important
        // second line about final
        final
      {
      }
      """

    let expected =
      """
      if next  // final is important
        // second line about final
        && final
      {
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func commentsInIfStatements() {
    let input =
      """
      if foo.bar && false && // comment about foo.bar
        baz && // comment about baz
        // comment about next
        next
        && // other is important
        // second line about other
        other &&
        // comment about final on a new line
        final
      {
      }
      if foo.bar && foo.baz
        && // comment about the next line
        // another comment line
        next.line
      {
      }
      """

    let expected =
      """
      if foo.bar && false  // comment about foo.bar
        && baz  // comment about baz
        // comment about next
        && next
        // other is important
        // second line about other
        && other
        // comment about final on a new line
        && final
      {
      }
      if foo.bar && foo.baz
        // comment about the next line
        // another comment line
        && next.line
      {
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func trailingSpacesInComments() {
    // Xcode has a commonly enabled setting to delete trailing spaces, which also applies to
    // multi-line strings. The trailing spaces are intentionally written using a unicode escape
    // sequence to ensure they aren't deleted.
    let input = """
      /// This is a trailing space documentation comment.\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      ///        This is a leading space documentation comment.
      func foo() {
        //       leading spaces are fine
        // trailing spaces should go\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
        let out = "123"
      }

      /**
       *    This is a leading space doc block comment
       * This is a trailing space doc block comment\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
       */
      func foo() {
        /*    block comment    */ let out = "123"
      }
      """

    let expected = """
      /// This is a trailing space documentation comment.
      ///        This is a leading space documentation comment.
      func foo() {
        //       leading spaces are fine
        // trailing spaces should go
        let out = "123"
      }

      /**
       *    This is a leading space doc block comment
       * This is a trailing space doc block comment
       */
      func foo() {
        /*    block comment    */ let out = "123"
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func diagnoseMoveEndOfLineComment() {
    assertLayout(
      input: """
        import veryveryverylongmodulenameherebecauseitistypical  // special sentinel comment

        func fooBarBazRunningOutOfIdeas() {  1️⃣// comment that needs to move
          if foo {  // comment is fine
          }
        }

        """,
      expected: """
        import veryveryverylongmodulenameherebecauseitistypical  // special sentinel comment

        func fooBarBazRunningOutOfIdeas() {  // comment that needs to move
          if foo {  // comment is fine
          }
        }

        """,
      linelength: 45,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  // Tests that "end of line" comments are flagged only when they exceed the configured line length.
  @Test func diagnoseMoveEndOfLineCommentAroundBoundary() {
    assertLayout(
      input: """
        x  // 789
        x  // 7890
        x  1️⃣// 78901

        """,
      expected: """
        x  // 789
        x  // 7890
        x  // 78901

        """,
      linelength: 10,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  @Test func lineWithDocLineComment() {
    // none of these should be merged if/when there is comment formatting
    let input =
      """
      /// Doc line comment
      // Line comment
      /// Doc line comment
      // Line comment

      // Another line comment

      """
    assertLayout(input: input, expected: input, linelength: 80)
  }

  @Test func nonmergeableComments() {
    // none of these should be merged if/when there is comment formatting
    let input =
      """
      let x = 1  // end of line comment
      //

      let y =  // eol comment
        1  // another
        + 2  // and another

      """

    assertLayout(input: input, expected: input, linelength: 80)
  }

  @Test func mergeableComments() {
    // these examples should be merged and formatted if/when there is comment formatting
    let input =
      """
      let z =
        // one comment
        // and another comment
        1 + 2

      let w = [1, 2, 3]
        .foo()
        // this comment
        // could be merged with this one
        .bar()

      """

    assertLayout(input: input, expected: input, linelength: 80)
  }

  @Test func unexpectedUnicodeCharacters() {
    let input =
      """
      // Hello World\u{2028}
      // Hello\u{20}\u{2028}World
      // Hello World\u{2028}\u{2029}\u{2029}
      // Hello World\u{20}\u{20}\u{20}\u{2028}

      """

    assertLayout(input: input, expected: input, linelength: 80)
  }
}
