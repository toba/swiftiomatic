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
struct SwitchStmtTests: LayoutTesting {
  @Test func basicSwitch() {
    let input =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3 + value4 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3
        + value4
      {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func switchCases() {
    let input =
      """
      switch someCharacter {
      case value1 + value2 + value3 + value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case value1 + value2 + value3
        + value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func switchEmptyCases() {
    let input =
      """
      switch a {
      case b:
      default:
        print("Not b")
      }

      switch a {
      case b:
        // Comment but no statements
      default:
        print("Not b")
      }
      """

    let expected =
      """
      switch a {
      case b:
      default:
        print("Not b")
      }

      switch a {
      case b:
        // Comment but no statements
      default:
        print("Not b")
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func switchCompoundCases() {
    let input =
      """
      switch someChar {
      case "a": print("a")
      case "b", "c": print("bc")
      case "d", "e", "f", "g", "h": print("defgh")
      case someVeryLongVarName, someOtherLongVarName: foo(a: [1, 2, 3, 4, 5])
      default: print("default")
      }
      """

    let expected =
      """
      switch someChar {
      case "a": print("a")
      case "b", "c":
        print("bc")
      case "d",
        "e",
        "f",
        "g",
        "h":
        print("defgh")
      case someVeryLongVarName,
        someOtherLongVarName:
        foo(a: [
          1, 2, 3, 4, 5,
        ])
      default:
        print("default")
      }

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func nestedSwitch() {
    let input =
      """
      myloop: while a != b {
        switch a + b {
        case firstValue: break myloop
        case secondVale:
          let c = 123
          var d = 456
        default: a += b
        }
      }
      """

    let expected =
      """
      myloop: while a != b {
        switch a + b {
        case firstValue: break myloop
        case secondVale:
          let c = 123
          var d = 456
        default: a += b
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func switchValueBinding() {
    let input =
      """
      switch someValue {
      case let thisval:
        let c = 123
        var d = 456 + thisval
      }
      switch somePoint {
      case (let x, 0): print(x)
      case (0, let y): print(y)
      case let (x, y): print(x + y)
      }
      switch anotherPoint {
      case (let distance, 0), (0, let distance): print(distance)
      case (let distance, 0), (0, let distance), (let distance, 10): print(distance)
      default: print("A message")
      }
      switch pointy {
      case let (x, y) where x == y: print("Equal")
      case let (x, y) where x == -y: print("Opposite sign")
      case let (reallyLongName, anotherLongName) where reallyLongName == -anotherLongName: print("Opposite sign")
      case let (x, y): print("Arbitrary value")
      }
      """

    let expected =
      """
      switch someValue {
      case let thisval:
        let c = 123
        var d = 456 + thisval
      }
      switch somePoint {
      case (let x, 0): print(x)
      case (0, let y): print(y)
      case let (x, y): print(x + y)
      }
      switch anotherPoint {
      case (let distance, 0), (0, let distance):
        print(distance)
      case (let distance, 0),
        (0, let distance),
        (let distance, 10):
        print(distance)
      default: print("A message")
      }
      switch pointy {
      case let (x, y) where x == y: print("Equal")
      case let (x, y) where x == -y:
        print("Opposite sign")
      case let (reallyLongName, anotherLongName)
        where reallyLongName == -anotherLongName:
        print("Opposite sign")
      case let (x, y): print("Arbitrary value")
      }

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  @Test func switchCaseWhereClauseIndentsPastCase() {
    let input =
      """
      switch pair {
      case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _)) where breakAllowsCommentMerge(breakKind) && (c2.kind == .docLine || c2.kind == .line):
        merge()
      }
      """

    let expected =
      """
      switch pair {
      case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
        where breakAllowsCommentMerge(breakKind)
        && (c2.kind == .docLine || c2.kind == .line):
        merge()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func switchExpression1() {
    let input =
      """
      func foo() -> Int {
        switch value1 + value2 + value3 + value4 {
        case "a":
          0
        case "b":
          1
        default:
          2
        }
      }
      """

    let expected =
      """
      func foo() -> Int {
        switch value1 + value2 + value3
          + value4
        {
        case "a":
          0
        case "b":
          1
        default:
          2
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func switchExpression2() {
    let input =
      """
      func foo() -> Int {
        let x = switch value1 + value2 + value3 + value4 {
        case "a":
          0
        case "b":
          1
        default:
          2
        }
        return x
      }
      """

    let expected =
      """
      func foo() -> Int {
        let x =
          switch value1 + value2 + value3 + value4 {
          case "a":
            0
          case "b":
            1
          default:
            2
          }
        return x
      }

      """

    assertLayout(input: input, expected: expected, linelength: 46)

    let expected43 =
      """
      func foo() -> Int {
        let x =
          switch value1 + value2 + value3
            + value4
          {
          case "a":
            0
          case "b":
            1
          default:
            2
          }
        return x
      }

      """

    assertLayout(input: input, expected: expected43, linelength: 43)
  }

  @Test func unknownDefault() {
    let input =
      """
      switch foo {
      @unknown default: bar()
      }
      """

    let expected =
      """
      switch foo {
      @unknown default:
        bar()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func newlinesDisambiguatingWhereClauses() {
    let input =
      """
      switch foo {
      case 1, 2, 3:
        break
      case 4 where bar(), 5, 6:
        break
      case 7, 8, 9 where bar():
        break
      case 10 where bar(), 11 where bar(), 12 where bar():
        break
      case 13, 14 where bar(), 15, 16 where bar():
        break
      }
      """

    let expected =
      """
      switch foo {
      case 1, 2, 3:
        break
      case 4 where bar(), 5, 6:
        break
      case 7,
        8,
        9 where bar():
        break
      case 10 where bar(), 11 where bar(), 12 where bar():
        break
      case 13,
        14 where bar(),
        15,
        16 where bar():
        break
      }

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func switchSequenceExprCases() {
    let input =
      """
      switch foo {
      case bar && baz
        + quxxe:
        break
      case baz where bar && (quxxe
        + 10000):
        break
      }
      """

    let expected =
      """
      switch foo {
      case bar
        && baz
          + quxxe:
        break
      case baz
        where bar
        && (quxxe
          + 10000):
        break
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func labeledSwitchStmt() {
    let input =
      """
      label:switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      someVeryExtremelyLongLabel: switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      """

    let expected =
      """
      label: switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      someVeryExtremelyLongLabel: switch foo
      {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func conditionalCases() {
    let input =
      """
      switch foo {
      #if CONDITION_A
      case bar:
        callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
      case baz2:
        callForBaz()
      #endif
      }
      """

    let expected =
      """
      switch foo {
      #if CONDITION_A
        case bar:
          callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
        case baz2:
          callForBaz()
      #endif
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func conditionalCasesIndenting() {
    let input =
      """
      switch foo {
      #if CONDITION_A
      case bar:
        callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
      case baz2:
        callForBaz()
      #endif
      }
      """

    let expected =
      """
      switch foo {
        #if CONDITION_A
          case bar:
            callForBar()
        #endif
        case baz:
          callForBaz()
      }
      switch foo2 {
        case bar2:
          callForBar()
        #if CONDITION_B
          case baz2:
            callForBaz()
        #endif
      }

      """

    var configuration = Configuration.forTesting
    configuration[SwitchCaseIndentation.self].style = .indented
    assertLayout(
      input: input,
      expected: expected,
      linelength: 40,
      configuration: configuration
    )
  }

  // fo7-8mu: when AlignWrappedConditions is enabled, wrapped switch case patterns
  // should align under the first pattern (after `case `), not indent as continuation.
  @Test func switchCaseMultiPatternAligns() {
    let input =
      """
      switch piece {
      case let .lineComment(t), let .blockComment(t), let .docBlockComment(t):
        text = t
      default: continue
      }
      """

    let expected =
      """
      switch piece {
      case let .lineComment(t),
           let .blockComment(t),
           let .docBlockComment(t):
        text = t
      default: continue
      }

      """

    var configuration = Configuration.forTesting
    configuration[AlignWrappedConditions.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: configuration)
  }

  // vw7-qtf: when patterns wrap across lines, a single-statement case body should
  // remain inline after the colon (matching the inline-block behavior for
  // single-pattern cases like `default: continue`).
  @Test func switchCaseMultiPatternInlinesBody() {
    let input =
      """
      switch piece {
      case let .lineComment(t), let .blockComment(t), let .docBlockComment(t): text = t
      default: continue
      }
      """

    let expected =
      """
      switch piece {
      case let .lineComment(t),
           let .blockComment(t),
           let .docBlockComment(t): text = t
      default: continue
      }

      """

    var configuration = Configuration.forTesting
    configuration[AlignWrappedConditions.self] = true
    assertLayout(input: input, expected: expected, linelength: 50, configuration: configuration)
  }
}
