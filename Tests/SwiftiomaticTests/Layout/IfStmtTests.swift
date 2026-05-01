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
struct IfStmtTests: LayoutTesting {
  @Test func ifStatement() {
    let input =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456 {
        let a = 23
        var b = "abc"
      }

      if a123456789 > b123456 {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456
      {
        let a = 23
        var b = "abc"
      }

      if a123456789
        > b123456
      {
        let a = 23
        var b = "abc"
      }

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func ifElseStatement_noBreakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }

      """

    assertLayout(input: input, expected: expected, linelength: 23)
  }

  @Test func ifElseStatement_breakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4
      {
        var b = 123
        var c = 456
      }

      """

    var config = Configuration.forTesting
    config[PlaceElseCatchOnNewLine.self] = true
    assertLayout(input: input, expected: expected, linelength: 20, configuration: config)
  }

  @Test func ifExpression1() {
    let input =
      """
      func foo() -> Int {
        if var1 < var2 {
          23
        }
        else if d < e {
          24
        }
        else {
          0
        }
      }
      """

    let expected =
      """
      func foo() -> Int {
        if var1 < var2 {
          23
        } else if d < e {
          24
        } else {
          0
        }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 23)
  }

  @Test func ifExpression2() {
    let input =
      """
      func foo() -> Int {
        let x = if var1 < var2 {
          23
        }
        else if d < e {
          24
        }
        else {
          0
        }
        return x
      }
      """

    let expected =
      """
      func foo() -> Int {
        let x =
          if var1 < var2 {
            23
          } else if d < e {
            24
          } else {
            0
          }
        return x
      }

      """

    assertLayout(input: input, expected: expected, linelength: 26)
  }

  @Test func ifExpression3() {
    let input =
      """
      let x = if a { b } else { c }
      xyzab = if a { b } else { c }
      """
    assertLayout(input: input, expected: input + "\n", linelength: 80)

    let expected28 =
      """
      let x =
        if a { b } else { c }
      xyzab =
        if a { b } else { c }

      """
    assertLayout(input: input, expected: expected28, linelength: 28)

    let expected22 =
      """
      let x =
        if a { b } else {
          c
        }
      xyzab =
        if a { b } else {
          c
        }

      """
    assertLayout(input: input, expected: expected22, linelength: 22)
  }

  @Test func matchingPatternConditions() {
    let input =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName = reallyLongVariableName {
        let a = 123
        var b = "abc"
      }
      """

    let expected =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName =
        reallyLongVariableName
      {
        let a = 123
        var b = "abc"
      }

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  // q3p-snb: a short `if let` chain with a member-access call on the RHS used to be split
  // across lines (with `{` pushed to its own line) by the full pipeline, even though the whole
  // condition + brace fit on one line. Layout-only test passes; the full pipeline regresses.
  @Test func shortIfLetWithMemberAccessCallStaysOnOneLine() {
    let input =
      """
      func decode(_ hex: String) {
        var set = Set<Unicode.Scalar>()
        if let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) {
          set.insert(scalar)
        }
      }

      """

    assertFullPipeline(input: input, expected: input, linelength: 100)
  }

  @Test func ifLetStatements() {
    let input =
      """
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments) {
        // do stuff
      }
      """

    let expected =
      """
      if let SomeReallyLongVar = Some.More
        .Stuff(),
        let a = myfunc()
      {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments)
      {
        // do stuff
      }

      """

    // The line length ends on the last paren of .Stuff()
    assertLayout(input: input, expected: expected, linelength: 44)
  }

  @Test func continuationLineBreakIndentation() {
    let input =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int {
        return nil
      }
      if let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) {
        return nil
      }
      """

    let expected =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int
      {
        return nil
      }
      if let someObject = object
        as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let someCastedObject = someFunc(
        foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz)
      {
        return nil
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func hangingOpenBreakIsTreatedLikeContinuation() {
    let input =
      """
      if let foo = someFunction(someArgumentLabel: someValue) {
        // do stuff
      }
      """

    let expected =
      """
      if let foo = someFunction(
        someArgumentLabel: someValue)
      {
        // do stuff
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func conditionExpressionOperatorGrouping() throws {
    let input =
      """
      if someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4 {
        // do something
      }
      if someVeryLongFirstCondition || aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines || anotherPrettyLongCondition || thatBinPacks {
        // do something else
      }
      """

    let expected =
      """
      if someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4
      {
        // do something
      }
      if someVeryLongFirstCondition
        || aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines
        || anotherPrettyLongCondition || thatBinPacks
      {
        // do something else
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func conditionExpressionOperatorGroupingMixedWithParentheses() throws {
    let input =
      """
      if (someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4) {
        // do something
      }
      if (someVeryLongFirstCondition || (aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines) || anotherPrettyLongCondition || thatBinPacks) {
        // do something else
      }
      """

    let expected =
      """
      if (someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4)
      {
        // do something
      }
      if (someVeryLongFirstCondition
        || (aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines)
        || anotherPrettyLongCondition || thatBinPacks)
      {
        // do something else
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func optionalBindingConditions() {
    let input =
      """
      if let someObject: Foo = object as? Int {
        return nil
      }
      if let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatDefinitelyBreaks, baz: Baz) = foo(a, b, c, d) { return nil }
      """

    let expected =
      """
      if let someObject: Foo = object as? Int
      {
        return nil
      }
      if let someObject:
        (
          foo: Foo,
          bar: SomeVeryLongTypeNameThatDefinitelyBreaks,
          baz: Baz
        ) = foo(a, b, c, d) { return nil }

      """

    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func parenthesizedClauses() {
    let input =
      """
      if foo && (
          bar < 1 || bar > 1
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 1
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000 || (
            extraTerm1 + extraTerm2 + extraTerm3
          )
        ) && baz {
        // do something
      }
      """

    let expected =
      """
      if foo && (bar < 1 || bar > 1) && baz {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1 || muchLongerBar > 1)
        && baz
      {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000)
        && baz
      {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000
          || (extraTerm1 + extraTerm2 + extraTerm3))
        && baz
      {
        // do something
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func compoundClauses() {
    let input =
      """
      if foo &&
          bar < 1 || bar
            > 1,
        let quxxe = 0
      {
        // do something
      }
      if bar < 1 && (
        baz
          > 1
        ),
      let quxxe = 0
      {
        // blah
      }
      """

    let expected =
      """
      if foo && bar < 1
        || bar
          > 1,
        let quxxe = 0
      {
        // do something
      }
      if bar < 1
        && (baz
          > 1),
        let quxxe = 0
      {
        // blah
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func labeledIfStmt() {
    let input =
      """
      someLabel:if foo && bar {
        // do something
      }
      anotherVeryLongLabelThatTakesUpTooManyCharacters: if foo && bar {
        // do something else
      }
      """

    let expected =
      """
      someLabel: if foo && bar {
        // do something
      }
      anotherVeryLongLabelThatTakesUpTooManyCharacters: if foo
        && bar
      {
        // do something else
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func multipleIfStmts() {
    let input =
      """
      func foo() {
        if foo && bar { baz() } else if bar { baz() } else if foo { baz() } else { blargh() }
        if foo && bar && quxxe { baz() } else if bar { baz() } else if foo { baz() } else if quxxe { baz() } else { blargh() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz { foo() } else { bar() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz && someOtherCondition { foo() } else { bar() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz && someOtherCondition { foo() }
      }
      """

    let expected =
      """
      func foo() {
        if foo && bar { baz() } else if bar { baz() } else if foo { baz() } else { blargh() }
        if foo && bar && quxxe {
          baz()
        } else if bar {
          baz()
        } else if foo {
          baz()
        } else if quxxe {
          baz()
        } else {
          blargh()
        }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz {
          foo()
        } else {
          bar()
        }
        if let foo = getmyfoo(),
          let bar = getmybar(),
          foo.baz && bar.baz && someOtherCondition
        {
          foo()
        } else {
          bar()
        }
        if let foo = getmyfoo(),
          let bar = getmybar(),
          foo.baz && bar.baz && someOtherCondition { foo() }
      }

      """

    assertLayout(input: input, expected: expected, linelength: 87)
  }

  /// When an `if` with multi-line conditions has a single-statement body, the body should stay
  /// inline on the closing condition's line — mirroring guard's `attachesInlineElseToWrappedConditions`.
  @Test func attachesInlineBodyToWrappedConditions() {
    let input =
      """
      if let existing = try? String(contentsOf: url, encoding: .utf8),
        existing == content { return }
      """

    let expected =
      """
      if let existing = try? String(contentsOf: url, encoding: .utf8),
        existing == content { return }

      """

    assertLayout(input: input, expected: expected, linelength: 100)
  }
}
