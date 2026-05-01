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
struct RepeatStmtTests: LayoutTesting {
  @Test func basicRepeatTests_noBreakBeforeWhile() {
    let input =
      """
      repeat {}
      while x
      repeat { f() }
      while x
      repeat { foo() }
      while longcondition
      repeat { f() }
      while long.condition
      repeat { f() } while long.condition
      repeat { f() } while long.condition.that.ison.many.lines
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition && condition2
      """

    let expected =
      """
      repeat {} while x
      repeat { f() } while x
      repeat {
        foo()
      } while longcondition
      repeat {
        f()
      } while long.condition
      repeat {
        f()
      } while long.condition
      repeat {
        f()
      } while long.condition
        .that.ison.many.lines
      repeat {
        let a = 123
        var b = "abc"
      } while condition
      repeat {
        let a = 123
        var b = "abc"
      } while condition
        && condition2

      """

    assertLayout(input: input, expected: expected, linelength: 25)
  }

  @Test func basicRepeatTests_breakBeforeWhile() {
    let input =
      """
      repeat {} while x
      repeat { f() } while x
      repeat { foo() } while longcondition
      repeat { f() }
      while long.condition
      repeat { f() } while long.condition
      repeat { f() } while long.condition.that.ison.many.lines
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition && condition2
      """

    let expected =
      """
      repeat {} while x
      repeat { f() } while x
      repeat { foo() }
      while longcondition
      repeat { f() }
      while long.condition
      repeat { f() }
      while long.condition
      repeat { f() }
      while long.condition.that
        .ison.many.lines
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
        && condition2

      """

    var config = Configuration.forTesting
    config[PlaceElseCatchOnNewLine.self] = true
    assertLayout(input: input, expected: expected, linelength: 25, configuration: config)
  }

  @Test func nestedRepeat() {
    // Avoid regressions in the case where a nested `repeat` block was getting shifted all the way
    // left.
    let input = """
      func foo() {
        repeat {
          bar()
          baz()
        } while condition
      }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 45)
  }

  @Test func labeledRepeat() {
    let input = """
      someLabel:repeat {
        bar()
        baz()
      } while condition
      somePrettyLongLabelThatTakesUpManyColumns: repeat {
        bar()
        baz()
      } while condition
      """

    let expected = """
      someLabel: repeat {
        bar()
        baz()
      } while condition
      somePrettyLongLabelThatTakesUpManyColumns: repeat
      {
        bar()
        baz()
      } while condition

      """
    assertLayout(input: input, expected: expected, linelength: 45)
  }
}
