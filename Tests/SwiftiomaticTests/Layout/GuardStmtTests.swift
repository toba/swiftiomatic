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
struct GuardStmtTests: LayoutTesting {
  @Test func guardStatement() {
    let input =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myFun() else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myLongFunction() else {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard
        let var1 = someFunction(),
        let var2 = myFun()
      else {
        let a = 23
        var b = "abc"
      }
      guard
        let var1 = someFunction(),
        let var2 = myLongFunction()
      else {
        let a = 23
        var b = "abc"
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func guardWithFuncCall() {
    let input =
      """
      guard let myvar = myClass.itsFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      guard let myvar1 = myClass.itsFunc(first: .someStuff, second: .moreStuff).first,
      let myvar2 = myClass.diffFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      """

    let expected =
      """
      guard
        let myvar = myClass
          .itsFunc(
            first: .someStuff,
            second: .moreStuff
          ).first
      else {
        // do stuff
      }
      guard
        let myvar1 = myClass
          .itsFunc(
            first: .someStuff,
            second: .moreStuff
          ).first,
        let myvar2 = myClass
          .diffFunc(
            first: .someStuff,
            second: .moreStuff
          ).first
      else {
        // do stuff
      }

      """

    assertLayout(input: input, expected: expected, linelength: 35)
  }

  @Test func openBraceIsGluedToElseKeyword() {
    let input =
      """
      guard let foo = something,
        let bar = somethingElse else
      {
        body()
      }
      """

    let expected =
      """
      guard
        let foo = something,
        let bar = somethingElse else {
        body()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func guardWithInlineBodyWrapsBodyNotElse() {
    let input =
      """
      guard column + text.count > maxWidth else { return WrapResult(didChange: false, advance: 1, originalIndex: 0) }
      """

    let expected =
      """
      guard column + text.count > maxWidth else {
        return WrapResult(didChange: false, advance: 1, originalIndex: 0)
      }

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func continuationLineBreaking() {
    let input =
      """
      guard let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) else {
        return nil
      }
      """

    let expected =
      """
      guard
        let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someObject = object
          as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someCastedObject = someFunc(
          foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz) else {
        return nil
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func optionalBindingConditions() {
    let input =
      """
      guard let someObject: Foo = object as? Int else {
        return nil
      }
      guard let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatBreaks, baz: Baz) = foo(a, b, c, d) else { return nil }
      """

    let expected =
      """
      guard
        let someObject: Foo = object as? Int
      else {
        return nil
      }
      guard
        let someObject:
          (
            foo: Foo,
            bar:
              SomeVeryLongTypeNameThatBreaks,
            baz: Baz
          ) = foo(a, b, c, d) else {
        return nil
      }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func parenthesizedClauses() {
    let input =
      """
      guard foo && (
          bar < 1 || bar > 1
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 1
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000 || (
            extraTerm1 + extraTerm2 + extraTerm3
          )
        ) && baz else {
        // do something
      }
      """

    let expected =
      """
      guard foo && (bar < 1 || bar > 1) && baz else {
        // do something
      }
      guard muchLongerFoo
        && (muchLongerBar < 1 || muchLongerBar > 1)
        && baz
      else {
        // do something
      }
      guard muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000)
        && baz
      else {
        // do something
      }
      guard muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000
          || (extraTerm1 + extraTerm2 + extraTerm3))
        && baz
      else {
        // do something
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func compoundClauses() {
    let input =
      """
      guard foo &&
          bar < 1 || bar
            > 1,
        let quxxe = 0
      else {
        // do something
      }
      guard
        bar < 1 && (
          baz
            > 1
          ),
        let quxxe = 0
      else {
        // blah
      }
      """

    let expected =
      """
      guard foo && bar < 1
        || bar
          > 1,
        let quxxe = 0
      else {
        // do something
      }
      guard bar < 1
        && (baz
          > 1),
        let quxxe = 0
      else {
        // blah
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func compoundExpressionBreakPrecedence() {
    let input =
      """
      guard (userRuns.count > 1 && formattedRuns.count > 1) || (userRuns.count == 1 && formattedRuns.count == 1 && userIndex == 0) else {
        return
      }
      guard foo && bar else {
        return
      }
      guard veryLongConditionName && anotherLongCondition || yetAnotherCondition else {
        return
      }
      """

    let expected =
      """
      guard (userRuns.count > 1
        && formattedRuns.count > 1)
        || (userRuns.count == 1
          && formattedRuns.count == 1
          && userIndex == 0)
      else {
        return
      }
      guard foo && bar else {
        return
      }
      guard veryLongConditionName
        && anotherLongCondition
        || yetAnotherCondition else {
        return
      }

      """

    assertLayout(input: input, expected: expected, linelength: 45)
  }

  /// When the user pre-broke `else` onto its own line but the whole guard
  /// (including ` else {`) fits on a single line, the formatter should collapse
  /// it. The discretionary newline before `else` should not pin it to its own
  /// line — only an actual condition wrap should push it down.
  @Test func collapsesElseOntoConditionLineWhenItFits() {
    let input =
      """
      guard let whitespaceEnd = data[offset...].firstIndex(where: { !$0.isWhitespace })
      else {
        return data[offset..<data.endIndex]
      }
      """

    let expected =
      """
      guard let whitespaceEnd = data[offset...].firstIndex(where: { !$0.isWhitespace }) else {
        return data[offset..<data.endIndex]
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  /// Same scenario as above but with a wider variety of conditions. When the
  /// condition fits with `else {` appended, no break should be inserted before
  /// `else` even if the user originally had one.
  @Test func discretionaryElseBreakIgnoredWhenFits() {
    let input =
      """
      guard let foo = bar()
      else {
        return
      }
      guard foo == 1
      else { return }
      """

    let expected =
      """
      guard let foo = bar() else {
        return
      }
      guard foo == 1 else { return }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  /// When `guard` conditions wrap onto continuation lines and the trailing
  /// `else { stmt }` is already a single-statement single-line body that fits
  /// on the same line as the closing condition, keep it attached rather than
  /// forcing `else` down to its own line.
  @Test func attachesInlineElseToWrappedConditions() {
    let input =
      """
      guard let signature = closure.signature,
        let captureClause = signature.capture
      else { return false }
      """

    let expected =
      """
      guard
        let signature = closure.signature,
        let captureClause = signature.capture else { return false }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }

  /// When the inline `else { stmt }` would exceed the line length on the
  /// closing condition's line, prefer wrapping the body inside the braces
  /// over breaking before `else`. Keyword breaks (before `else`) are a
  /// last-resort precedence; body wrapping fires first.
  @Test func breaksElseWhenInlineBodyExceedsLineLength() {
    let input =
      """
      guard let signature = closure.signature,
        let captureClause = signature.capture
      else { return false }
      """

    // Line length 60: "  let captureClause = signature.capture else {" fits,
    // but the full inline `... else { return false }` does not, so the body
    // wraps onto its own lines while `else {` stays glued to the condition.
    let expected =
      """
      guard
        let signature = closure.signature,
        let captureClause = signature.capture else {
        return false
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  /// Same as `attachesInlineElseToWrappedConditions` but under the
  /// `alignWrappedConditions=true, breakBeforeGuardConditions=false` configuration:
  /// the inline-attach behavior must apply regardless of how the conditions
  /// themselves are indented.
  @Test func attachesInlineElseUnderAlignedConditions() {
    var configuration = Configuration.forTesting
    configuration[AlignWrappedConditions.self] = true
    configuration[BreakBeforeGuardConditions.self] = false

    let input =
      """
      guard let signature = closure.signature,
            let captureClause = signature.capture
      else { return false }
      """

    let expected =
      """
      guard let signature = closure.signature,
            let captureClause = signature.capture else { return false }

      """

    assertLayout(input: input, expected: expected, linelength: 100, configuration: configuration)
  }

  /// Under aligned conditions, when the inline body would exceed line length,
  /// `else` must drop to base indent (column 0), not stay at the +6 alignment
  /// column inherited from the conditions group.
  @Test func breaksElseUnderAlignedConditionsWhenBodyTooLong() {
    var configuration = Configuration.forTesting
    configuration[AlignWrappedConditions.self] = true
    configuration[BreakBeforeGuardConditions.self] = false

    let input =
      """
      guard let signature = closure.signature,
            let captureClause = signature.capture
      else { return false }
      """

    let expected =
      """
      guard let signature = closure.signature,
            let captureClause = signature.capture else {
        return false
      }

      """

    assertLayout(input: input, expected: expected, linelength: 60, configuration: configuration)
  }

  /// Three aligned conditions where the inline `else { stmt }` body fits on
  /// the last condition's line. `else` must glue to the last condition rather
  /// than dropping to its own line. Regression test for `4pf-bov`.
  @Test func threeConditionsGlueElseWhenInlineBodyFits() {
    var configuration = Configuration.forTesting
    configuration[AlignWrappedConditions.self] = true
    configuration[BreakBeforeGuardConditions.self] = false

    let input =
      """
      guard let mod = decl.modifiers.accessLevelModifier,
            mod.name.tokenKind == .keyword(.internal),
            mod.detail == nil
      else { return decl }
      """

    let expected =
      """
      guard let mod = decl.modifiers.accessLevelModifier,
            mod.name.tokenKind == .keyword(.internal),
            mod.detail == nil else { return decl }

      """

    assertLayout(input: input, expected: expected, linelength: 100, configuration: configuration)
  }

  /// Multi-statement bodies are not inline candidates; `else` should still
  /// drop to its own line when conditions wrap.
  @Test func multiStatementBodyAlwaysBreaksElse() {
    let input =
      """
      guard
        let signature = closure.signature,
        let captureClause = signature.capture
      else {
        log("missing")
        return false
      }

      """

    let expected =
      """
      guard
        let signature = closure.signature,
        let captureClause = signature.capture
      else {
        log("missing")
        return false
      }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }
}
