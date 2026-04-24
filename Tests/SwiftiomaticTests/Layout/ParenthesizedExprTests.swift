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
struct ParenthesizedExprTests: LayoutTesting {
  @Test func sequenceExprParens() {
    let input =
      """
      x = (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (
          firstTerm + secondTerm + thirdTerm
        ) -
        (
          firstTerm + secondTerm + thirdTerm
        )
      x = zerothTerm + (
        firstTerm + secondTerm + (
            nestedFirstTerm + nestedSecondTerm + (
              doubleNestedFirstTerm + doubleNestedSecondTerm
            )
        )
      ) + thirdTerm
      x = zerothTerm + (
      firstTerm + secondTerm && thirdTerm + (
          nestedFirstTerm || nestedSecondTerm + (
            doubleNestedFirstTerm + doubleNestedSecondTerm
          )
        )
      )
      """

    let expected =
      """
      x =
        (firstTerm + secondTerm
          + thirdTerm)
      x =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
        * (firstTerm + secondTerm
          + thirdTerm)
      x = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
      x = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
        * (firstTerm + secondTerm
          + thirdTerm)
      x = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x = zerothTerm
        + (firstTerm + secondTerm
          + (nestedFirstTerm
            + nestedSecondTerm
            + (doubleNestedFirstTerm
              + doubleNestedSecondTerm)))
        + thirdTerm
      x = zerothTerm
        + (firstTerm + secondTerm
          && thirdTerm
            + (nestedFirstTerm
              || nestedSecondTerm
                + (doubleNestedFirstTerm
                  + doubleNestedSecondTerm)))

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func initializerClauseParens() {
    let input =
      """
      let x = (firstTerm + secondTerm + thirdTerm)
      let y = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      let x = zerothTerm + (firstTerm + secondTerm + thirdTerm)
      let y = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      """

    let expected =
      """
      let x =
        (firstTerm + secondTerm
          + thirdTerm)
      let y =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      let x = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
      let y = zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func nestedParentheses() {
    let input =
      """
      theFirstTerm + secondTerm * (nestedThing - (moreNesting + anotherTerm)) / andThatsAll
      theFirstTerm + secondTerm * (nestedThing - (moreNesting + anotherTerm) + yetAnother) / andThatsAll
      """

    let expected =
      """
      theFirstTerm
        + secondTerm
        * (nestedThing
          - (moreNesting
            + anotherTerm))
        / andThatsAll
      theFirstTerm
        + secondTerm
        * (nestedThing
          - (moreNesting
            + anotherTerm)
          + yetAnother)
        / andThatsAll

      """

    assertLayout(input: input, expected: expected, linelength: 23)
  }

  @Test func expressionStartsWithParentheses() {
    let input =
      """
      (firstTerm + secondTerm + thirdTerm)(firstArg, secondArg, thirdArg)
      """

    let expected =
      """
      (firstTerm
        + secondTerm
        + thirdTerm)(
          firstArg,
          secondArg,
          thirdArg)

      """

    assertLayout(input: input, expected: expected, linelength: 20)
  }

  @Test func complexConditionalWithParens() {
    let input =
      """
      if (someNumericValue > NumericConstants.someConstant || (otherValue.n) > NumericConstants.otherValueToCheck) && (otherValue.n) > -NumericConstants.otherValueToCheck {
        openMenu()
      }
      """

    let expected =
      """
      if (someNumericValue > NumericConstants.someConstant
        || (otherValue.n) > NumericConstants.otherValueToCheck)
        && (otherValue.n) > -NumericConstants.otherValueToCheck
      {
        openMenu()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 80)
  }

  @Test func tupleSequenceExprs() {
    let input =
      """
      let x = (
        (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) && (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
      )
      let x = (
        (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) && (
          foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg)
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg
        )
        )
      )
      let x = (
        foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg
        ) && (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
      )
      """

    let expected =
      """
      let x =
        ((
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
          && (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          ))
      let x =
        ((
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
          && (foo(
            firstFuncCallArg, second: secondFuncCallArg,
            third: thirdFuncCallArg,
            fourth: fourthFuncCallArg))
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
            == (foo(
              firstFuncCallArg,
              second: secondFuncCallArg,
              third: thirdFuncCallArg,
              fourth: fourthFuncCallArg
            )))
      let x =
        (foo(
          firstFuncCallArg, second: secondFuncCallArg,
          third: thirdFuncCallArg,
          fourth: fourthFuncCallArg
        )
          && (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          ))

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }
}
