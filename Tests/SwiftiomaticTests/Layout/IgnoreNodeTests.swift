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

import Testing
@Suite
struct IgnoreNodeTests: LayoutTesting {
  @Test func ignoreCodeBlockListItems() {
    let input =
      """
            x      = 4       + 5 // This comment stays here.

            // sm:ignore
            x   =
      4 + 5 +
       6

      // sm:ignore
      let foo = bar( a, b,
      c)
      let baz = bar( a, b,
       c)

              /// some other unrelated comment

      // sm:ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // sm:ignore
      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          var a = b // comment
          // comment 2
          var c
           = d
      }

      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          // sm:ignore
          var a = b // comment
          // comment 2
          var c
           = d
      }
      """

    let expected =
      """
      x = 4 + 5  // This comment stays here.

      // sm:ignore
      x   =
      4 + 5 +
       6

      // sm:ignore
      let foo = bar( a, b,
      c)
      let baz = bar(
        a, b,
        c)

      /// some other unrelated comment

      // sm:ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // sm:ignore
      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          var a = b // comment
          // comment 2
          var c
           = d
      }

      if someExtremelyLongCondition
        && anotherVeryLongCondition
        && thisOneOverflowsTheLineLength
          + foo + bar + baz
      {
        // sm:ignore
        var a = b // comment
        // comment 2
        var c = d
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreMemberDeclListItems() {
    let input =
      """
          struct Foo {
            // sm:ignore
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            // sm:ignore
            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      // sm:ignore
      var c = 0 +
          1
          + (2 + 3)
      }
      """

    let expected =
      """
      struct Foo {
        // sm:ignore
        private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

        // sm:ignore
        var a = true    // line comment
        // aligned line comment
        var b = false  // correct trailing comment

        // sm:ignore
        var c = 0 +
          1
          + (2 + 3)
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoresNestedMembers() {
    let input =
      """
      // sm:ignore
          struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }
      """

    let expected =
      """
      // sm:ignore
      struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func invalidComment() {
    let input =
      """
      // sm:ignore: RuleName
      x        =                  1 +
      2

      /// sm:ignore
      x      =    a+1+2+3+4

      /** sm:ignore */
      x      =    foo -
      bar

      // I could use sm:ignore here if I wanted my code to look bad.
      x     = foo+bar+baz
      """

    let expected =
      """
      // sm:ignore: RuleName
      x = 1 + 2

      /// sm:ignore
      x = a + 1 + 2 + 3 + 4

      /** sm:ignore */
      x = foo - bar

      // I could use sm:ignore here if I wanted my code to look bad.
      x = foo + bar + baz

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func validComment() {
    let input =
      """
      // sm:ignore
      x=y+b+c

      /// Pragma mark: - Special Region

      // sm:ignore
      // x is important
      x        =                  1 +
      2

      /* sm:ignore */
      x      =    a+1+2+3+4
      """

    let expected =
      """
      // sm:ignore
      x=y+b+c

      /// Pragma mark: - Special Region

      // sm:ignore
      // x is important
      x        =                  1 +
      2

      /* sm:ignore */
      x      =    a+1+2+3+4

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreInvalidAfterFirstToken() {
    let input =
      """
      public  // sm:ignore
        struct MyStruct {
          var a:Foo=3
        }

      """

    let expected =
      """
      public  // sm:ignore
        struct MyStruct
      {
        var a: Foo = 3
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreWholeFile() {
    let input =
      """
      // sm:ignore-file
      import Zoo
      import Aoo
      import foo

          struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }

            class Bar
      {
        var bazzle = 0 }
      """
    assertLayout(input: input, expected: input, linelength: 50)
  }

  @Test func ignoreWholeFileDoesNotTouchWhitespace() {
    let input =
      """
      // sm:ignore-file
      /// foo bar
      \u{0020}
      // baz
      """
    assertLayout(input: input, expected: input, linelength: 100)
  }

  @Test func ignoreWholeFileInNestedNode() {
    let input =
      """
      import Zoo
      import Aoo
      import foo

      // sm:ignore-file
          struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }

            class Bar
      {
      // sm:ignore-file
        var bazzle = 0 }
      """

    let expected =
      """
      import Zoo
      import Aoo
      import foo

      // sm:ignore-file
      struct Foo {
        private var baz: Bool {
          return foo + bar  // poorly placed comment
            + false
        }

        var a = true  // line comment
        // aligned line comment
        var b = false  // correct trailing comment

        var c = 0 + 1
          + (2 + 3)
      }

      class Bar {
        // sm:ignore-file
        var bazzle = 0
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }
}
