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
struct IgnoreNodeTests: PrettyPrintTesting {
  @Test func ignoreCodeBlockListItems() {
    let input =
      """
            x      = 4       + 5 // This comment stays here.

            // swiftiomatic-ignore
            x   =
      4 + 5 +
       6

      // swiftiomatic-ignore
      let foo = bar( a, b,
      c)
      let baz = bar( a, b,
       c)

              /// some other unrelated comment

      // swiftiomatic-ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // swiftiomatic-ignore
      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          var a = b // comment
          // comment 2
          var c
           = d
      }

      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          // swiftiomatic-ignore
          var a = b // comment
          // comment 2
          var c
           = d
      }
      """

    let expected =
      """
      x = 4 + 5  // This comment stays here.

      // swiftiomatic-ignore
      x   =
      4 + 5 +
       6

      // swiftiomatic-ignore
      let foo = bar( a, b,
      c)
      let baz = bar(
        a, b,
        c)

      /// some other unrelated comment

      // swiftiomatic-ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // swiftiomatic-ignore
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
        // swiftiomatic-ignore
        var a = b // comment
        // comment 2
        var c = d
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreMemberDeclListItems() {
    let input =
      """
          struct Foo {
            // swiftiomatic-ignore
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            // swiftiomatic-ignore
            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      // swiftiomatic-ignore
      var c = 0 +
          1
          + (2 + 3)
      }
      """

    let expected =
      """
      struct Foo {
        // swiftiomatic-ignore
        private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

        // swiftiomatic-ignore
        var a = true    // line comment
        // aligned line comment
        var b = false  // correct trailing comment

        // swiftiomatic-ignore
        var c = 0 +
          1
          + (2 + 3)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoresNestedMembers() {
    let input =
      """
      // swiftiomatic-ignore
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
      // swiftiomatic-ignore
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

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func invalidComment() {
    let input =
      """
      // swiftiomatic-ignore: RuleName
      x        =                  1 +
      2

      /// swiftiomatic-ignore
      x      =    a+1+2+3+4

      /** swiftiomatic-ignore */
      x      =    foo -
      bar

      // I could use swiftiomatic-ignore here if I wanted my code to look bad.
      x     = foo+bar+baz
      """

    let expected =
      """
      // swiftiomatic-ignore: RuleName
      x = 1 + 2

      /// swiftiomatic-ignore
      x = a + 1 + 2 + 3 + 4

      /** swiftiomatic-ignore */
      x = foo - bar

      // I could use swiftiomatic-ignore here if I wanted my code to look bad.
      x = foo + bar + baz

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func validComment() {
    let input =
      """
      // swiftiomatic-ignore
      x=y+b+c

      /// Pragma mark: - Special Region

      // swiftiomatic-ignore
      // x is important
      x        =                  1 +
      2

      /* swiftiomatic-ignore */
      x      =    a+1+2+3+4
      """

    let expected =
      """
      // swiftiomatic-ignore
      x=y+b+c

      /// Pragma mark: - Special Region

      // swiftiomatic-ignore
      // x is important
      x        =                  1 +
      2

      /* swiftiomatic-ignore */
      x      =    a+1+2+3+4

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreInvalidAfterFirstToken() {
    let input =
      """
      public  // swiftiomatic-ignore
        struct MyStruct {
          var a:Foo=3
        }

      """

    let expected =
      """
      public  // swiftiomatic-ignore
        struct MyStruct
      {
        var a: Foo = 3
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  @Test func ignoreWholeFile() {
    let input =
      """
      // swiftiomatic-ignore-file
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
    assertPrettyPrintEqual(input: input, expected: input, linelength: 50)
  }

  @Test func ignoreWholeFileDoesNotTouchWhitespace() {
    let input =
      """
      // swiftiomatic-ignore-file
      /// foo bar
      \u{0020}
      // baz
      """
    assertPrettyPrintEqual(input: input, expected: input, linelength: 100)
  }

  @Test func ignoreWholeFileInNestedNode() {
    let input =
      """
      import Zoo
      import Aoo
      import foo

      // swiftiomatic-ignore-file
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
      // swiftiomatic-ignore-file
        var bazzle = 0 }
      """

    let expected =
      """
      import Zoo
      import Aoo
      import foo

      // swiftiomatic-ignore-file
      struct Foo {
        private var baz: Bool {
          return foo + bar  // poorly placed comment
            + false
        }

        var a = true  // line comment
        // aligned line comment
        var b = false  // correct trailing comment

        var c =
          0 + 1
          + (2 + 3)
      }

      class Bar {
        // swiftiomatic-ignore-file
        var bazzle = 0
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
