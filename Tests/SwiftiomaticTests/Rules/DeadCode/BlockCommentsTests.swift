import Testing

@testable import Swiftiomatic

@Suite struct BlockCommentsTests {
  @Test func blockCommentsOneLine() {
    let input = """
      foo = bar /* comment */
      """
    let output = """
      foo = bar // comment
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func docBlockCommentsOneLine() {
    let input = """
      foo = bar /** doc comment */
      """
    let output = """
      foo = bar /// doc comment
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func preservesBlockCommentInSingleLineScope() {
    let input = """
      if foo { /* code */ }
      """
    testFormatting(for: input, rule: .blockComments)
  }

  @Test func blockCommentsMultiLine() {
    let input = """
      /*
       * foo
       * bar
       */
      """
    let output = """
      // foo
      // bar
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentsWithoutBlankFirstLine() {
    let input = """
      /* foo
       * bar
       */
      """
    let output = """
      // foo
      // bar
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentsWithBlankLine() {
    let input = """
      /*
       * foo
       *
       * bar
       */
      """
    let output = """
      // foo
      //
      // bar
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockDocCommentsWithAsterisksOnEachLine() {
    let input = """
      /**
       * This is a documentation comment,
       * not a regular comment.
       */
      """
    let output = """
      /// This is a documentation comment,
      /// not a regular comment.
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }

  @Test func blockDocCommentsWithoutAsterisksOnEachLine() {
    let input = """
      /**
       This is a documentation comment,
       not a regular comment.
       */
      """
    let output = """
      /// This is a documentation comment,
      /// not a regular comment.
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }

  @Test func blockCommentWithBulletPoints() {
    let input = """
      /*
       This is a list of nice colors:

       * green
       * blue
       * red

       Yellow is also great.
       */

      /*
       * Another comment.
       */
      """
    let output = """
      // This is a list of nice colors:
      //
      // * green
      // * blue
      // * red
      //
      // Yellow is also great.

      // Another comment.
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentsNested() {
    let input = """
      /*
       * comment
       * /* inside */
       * a comment
       */
      """
    let output = """
      // comment
      // inside
      // a comment
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentsIndentPreserved() {
    let input = """
      func foo() {
          /*
           foo
           bar.
           */
      }
      """
    let output = """
      func foo() {
          // foo
          // bar.
      }
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentsIndentPreserved2() {
    let input = """
      func foo() {
          /*
           * foo
           * bar.
           */
      }
      """
    let output = """
      func foo() {
          // foo
          // bar.
      }
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockDocCommentsIndentPreserved() {
    let input = """
      func foo() {
          /**
           * foo
           * bar.
           */
      }
      """
    let output = """
      func foo() {
          /// foo
          /// bar.
      }
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }

  @Test func longBlockCommentsWithoutPerLineMarkersFullyConverted() {
    let input = """
      /*
          The beginnings of the lines in this multiline comment body
          have only spaces in them. There are no asterisks, only spaces.

          This should not cause the blockComments rule to convert only
          part of the comment body and leave the rest hanging.

          The comment must have at least this many lines to trigger the bug.
      */
      """
    let output = """
      // The beginnings of the lines in this multiline comment body
      // have only spaces in them. There are no asterisks, only spaces.
      //
      // This should not cause the blockComments rule to convert only
      // part of the comment body and leave the rest hanging.
      //
      // The comment must have at least this many lines to trigger the bug.
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentImmediatelyFollowedByCode() {
    let input = """
      /**
        foo

        bar
      */
      func foo() {}
      """
    let output = """
      /// foo
      ///
      /// bar
      func foo() {}
      """
    testFormatting(for: input, output, rule: .blockComments)
  }

  @Test func blockCommentImmediatelyFollowedByCode2() {
    let input = """
      /**
       Line 1.

       Line 2.

       Line 3.
       */
      foo(bar)
      """
    let output = """
      /// Line 1.
      ///
      /// Line 2.
      ///
      /// Line 3.
      foo(bar)
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }

  @Test func blockCommentImmediatelyFollowedByCode3() {
    let input = """
      /* foo
         bar */
      func foo() {}
      """
    let output = """
      // foo
      // bar
      func foo() {}
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }

  @Test func blockCommentFollowedByBlankLine() {
    let input = """
      /**
        foo

        bar
      */

      func foo() {}
      """
    let output = """
      /// foo
      ///
      /// bar

      func foo() {}
      """
    testFormatting(for: input, output, rule: .blockComments, exclude: [.docComments])
  }
}
