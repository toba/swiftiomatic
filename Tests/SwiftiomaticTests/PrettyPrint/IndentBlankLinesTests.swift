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
struct IndentBlankLinesTests: PrettyPrintTesting {
  @Test func indentBlankLinesEnabled() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func indentBlankLinesDisabled() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }

        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func lineWithMoreWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func lineWithFewerWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func lineWithoutWhitespace() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }

        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func consecutiveLinesWithMoreWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      \u{0020}\u{0020}\u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func consecutiveLinesWithFewerWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}

        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func consecutiveLinesWithoutWhitespace() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }


        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func expressionsWithUnnecessaryWhitespaces() {
    let input =
      """
          class A {
        func   foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar()    -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func blockCommentWhenIndentBlankLinesDisabled() {
    let input =
      """
      struct Foo {
      \u{0020}\u{0020}/**\u{0020}\u{0020}
      \u{0020}\u{0020}foo bar baz\u{0020}\u{0020}
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      \u{0020}\u{0020}quxx\u{0020}\u{0020}
      \u{0020}\u{0020}

      \u{0020}\u{0020}*/\u{0020}\u{0020}
      \u{0020}\u{0020}func foo() {}
      }
      """

    let expected =
      """
      struct Foo {
      \u{0020}\u{0020}/**
      \u{0020}\u{0020}foo bar baz

      \u{0020}\u{0020}quxx


      \u{0020}\u{0020}*/
      \u{0020}\u{0020}func foo() {}
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  @Test func blockCommentWhenIndentBlankLinesEnabled() {
    let input =
      """
      struct Foo {
      \u{0020}\u{0020}/**\u{0020}\u{0020}
      \u{0020}\u{0020}foo bar baz\u{0020}\u{0020}
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      \u{0020}\u{0020}quxx\u{0020}\u{0020}
      \u{0020}\u{0020}

      \u{0020}\u{0020}*/\u{0020}\u{0020}
      \u{0020}\u{0020}func foo() {}
      }
      """

    let expected =
      """
      struct Foo {
      \u{0020}\u{0020}/**
      \u{0020}\u{0020}foo bar baz
      \u{0020}\u{0020}
      \u{0020}\u{0020}quxx
      \u{0020}\u{0020}
      \u{0020}\u{0020}
      \u{0020}\u{0020}*/
      \u{0020}\u{0020}func foo() {}
      }

      """
    var config = Configuration.forTesting
    config[IndentBlankLines.self] = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }
}
