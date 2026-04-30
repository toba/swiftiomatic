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
import Testing

@Suite
struct SelectionTests: LayoutTesting {
  @Test func selectAll() {
    let input =
      """
      ⏩func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
        // do stuff
      }
      }⏪
      """

    let expected =
      """
      func foo() {
        if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
        }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func selectComment() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩// do stuff⏪
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func insertionPointBeforeComment() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩⏪// do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func spacesInline() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar ⏩ =   ⏪Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func spacesFullLine() {
    let input =
      """
      func foo() {
      ⏩if let SomeReallyLongVar  =   Some.More.Stuff(), let a = myfunc() {⏪
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
        if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func wrapInline() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = ⏩Some.More.Stuff(), let a = myfunc()⏪ {
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More
          .Stuff(),
          let a = myfunc() {
      // do stuff
      }
      }
      """

    // The line length ends on the last paren of .Stuff()
    assertLayout(input: input, expected: expected, linelength: 44)
  }

  @Test func commentsOnly() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩// do stuff
      // do more stuff⏪
      var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
          // do more stuff
      var i = 0
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func varOnly() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      // do more stuff
      ⏩⏪var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      // do more stuff
          var i = 0
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func singleLineFunc() {
    let input =
      """
      func foo()   ⏩{}⏪
      """

    let expected =
      """
      func foo() {}
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func singleLineFunc2() {
    let input =
      """
      func foo() /**/ ⏩{}⏪
      """

    let expected =
      """
      func foo() /**/ {}
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func simpleFunc() {
    let input =
      """
      func foo() /**/
        ⏩{}⏪
      """

    let expected =
      """
      func foo() /**/
      {}
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  // MARK: - multiple selection ranges
  @Test func firstCommentAndVar() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩⏪// do stuff
      // do more stuff
      ⏩⏪var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      // do more stuff
          var i = 0
      }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  // from AccessorTests (but with some Selection ranges)
  @Test func basicAccessors() {
    let input =
      """
      ⏩struct MyStruct {
        var memberValue: Int
        var someValue: Int { get { return memberValue + 2 } set(newValue) { memberValue = newValue } }
      }⏪
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            ⏩memberValue2 = newValue / 2 && andableValue⏪
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int {
          get { return memberValue + 2 }
          set(newValue) { memberValue = newValue }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            memberValue2 = newValue / 2
              && andableValue
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }
      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  // from CommentTests (but with some Selection ranges)
  @Test func containerLineComments() {
    let input =
      """
      // Array comment
      let a = [⏩4⏪56, // small comment
        789]

      // Dictionary comment
      let b = ["abc": ⏩456, // small comment
        "def": 789]⏪

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      ⏩/* Array comment */
      let a = [456, /* small comment */
        789]

       /* Dictionary comment */
      let b = ["abc": 456,        /* small comment */
        "def": 789]⏪
      """

    let expected =
      """
      // Array comment
      let a = [
        456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456,  // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [123, 456  // small comment
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
}
