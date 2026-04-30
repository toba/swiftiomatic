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
struct BinaryOperatorExprTests: LayoutTesting {
  @Test func nonRangeFormationOperatorsAreSurroundedByBreaks() {
    let input =
      """
      x=1+8-9  ^*^  5*4/10
      """

    let expected80 =
      """
      x = 1 + 8 - 9 ^*^ 5 * 4 / 10

      """

    assertLayout(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x = 1 + 8
        - 9
        ^*^ 5
        * 4 / 10

      """

    assertLayout(input: input, expected: expected10, linelength: 10)
  }

  @Test func rangeFormationOperatorCompaction_noSpacesAroundRangeFormation() {
    let input =
      """
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)
      x = 1 ... 100
      x = 1 ..< 100
      x = (1++) ... (-100)
      """

    let expected =
      """
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)

      """

    var configuration = Configuration.forTesting
    configuration[SpacesAroundRangeFormationOperators.self] = false
    assertLayout(
      input: input,
      expected: expected,
      linelength: 80,
      configuration: configuration
    )
  }

  @Test func rangeFormationOperatorCompaction_spacesAroundRangeFormation() {
    let input =
      """
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)
      x = 1 ... 100
      x = 1 ..< 100
      x = (1++) ... (-100)
      """

    let expected =
      """
      x = 1 ... 100
      x = 1 ..< 100
      x = (1++) ... (-100)
      x = 1 ... 100
      x = 1 ..< 100
      x = (1++) ... (-100)

      """

    var configuration = Configuration.forTesting
    configuration[SpacesAroundRangeFormationOperators.self] = true
    assertLayout(
      input: input,
      expected: expected,
      linelength: 80,
      configuration: configuration
    )
  }

  @Test func rangeFormationOperatorsAreNotCompactedWhenFollowingAPostfixOperator() {
    let input =
      """
      x = 1++ ... 100
      x = 1-- ..< 100
      x = 1++   ...   100
      x = 1--   ..<   100
      """

    let expected80 =
      """
      x = 1++ ... 100
      x = 1-- ..< 100
      x = 1++ ... 100
      x = 1-- ..< 100

      """

    assertLayout(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x = 1++
        ... 100
      x = 1--
        ..< 100
      x = 1++
        ... 100
      x = 1--
        ..< 100

      """

    assertLayout(input: input, expected: expected10, linelength: 10)
  }

  @Test func rangeFormationOperatorsAreNotCompactedWhenPrecedingAPrefixOperator() {
    let input =
      """
      x = 1 ... -100
      x = 1 ..< -100
      x = 1   ...   √100
      x = 1   ..<   √100
      """

    let expected80 =
      """
      x = 1 ... -100
      x = 1 ..< -100
      x = 1 ... √100
      x = 1 ..< √100

      """

    assertLayout(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x = 1
        ... -100
      x = 1
        ..< -100
      x = 1
        ... √100
      x = 1
        ..< √100

      """

    assertLayout(input: input, expected: expected10, linelength: 10)
  }

  @Test func rangeFormationOperatorsAreNotCompactedWhenUnaryOperatorsAreOnEachSide() {
    let input =
      """
      x = 1++ ... -100
      x = 1-- ..< -100
      x = 1++   ...   √100
      x = 1--   ..<   √100
      """

    let expected80 =
      """
      x = 1++ ... -100
      x = 1-- ..< -100
      x = 1++ ... √100
      x = 1-- ..< √100

      """

    assertLayout(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x = 1++
        ... -100
      x = 1--
        ..< -100
      x = 1++
        ... √100
      x = 1--
        ..< √100

      """

    assertLayout(input: input, expected: expected10, linelength: 10)
  }

  @Test func rangeFormationOperatorsAreNotCompactedWhenPrecedingPrefixDot() {
    let input =
      """
      x = .first   ...   .last
      x = .first   ..<   .last
      x = .first   ...   .last
      x = .first   ..<   .last
      """

    let expected80 =
      """
      x = .first ... .last
      x = .first ..< .last
      x = .first ... .last
      x = .first ..< .last

      """

    assertLayout(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x = .first
        ... .last
      x = .first
        ..< .last
      x = .first
        ... .last
      x = .first
        ..< .last

      """

    assertLayout(input: input, expected: expected10, linelength: 10)
  }

  @Test func assignmentPrefersBreakingAtOperatorOverEquals() {
    // Prefer breaking at ?? over breaking at = when the first operand fits with the LHS.
    let input =
      """
      words = try container.decodeIfPresent([String].self, forKey: .words) ?? AcronymsConfiguration().words
      """

    // "words = try container.decodeIfPresent([String].self, forKey: .words)" is 69 chars.
    // At line lengths where this fits, the = stays glued and ?? break fires.
    let expected =
      """
      words = try container.decodeIfPresent([String].self, forKey: .words)
        ?? AcronymsConfiguration().words

      """

    assertLayout(input: input, expected: expected, linelength: 75)
    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func assignmentPrefersBreakingAtPlusOverEquals() {
    let input =
      """
      result = firstLongValue + secondLongValue + thirdLongValue
      """

    // "result = firstLongValue + secondLongValue" is 41 chars; fits in 45.
    // The + thirdLongValue part forces a break before the last +.
    let expected45 =
      """
      result = firstLongValue + secondLongValue
        + thirdLongValue

      """

    assertLayout(input: input, expected: expected45, linelength: 45)
  }

  @Test func comparisonOperatorYieldsToFunctionCallArgumentBreaks() {
    // The comparison-operator break ( `!=` , `==` , etc.) should be lower precedence
    // than function-call argument breaks: prefer to wrap the call's arguments before
    // dangling the operator on its own line.
    let input =
      """
      hasASCIIArt = asciiArtLength(of: cleaned, leadingSpaces: leadingWhitespace) != 0
      """

    let expected =
      """
      hasASCIIArt = asciiArtLength(
        of: cleaned, leadingSpaces: leadingWhitespace) != 0

      """

    assertLayout(input: input, expected: expected, linelength: 70)
  }

  @Test func comparisonOperatorYieldsToFunctionCallInCondition() {
    // Known gap: in `if` conditions, the comparison break still fires before the
    // function-call argument break. Tracked separately; this test pins current behavior.
    let input =
      """
      if foo(bar: someValue, qux: anotherLongValue) == expected { body() }
      """

    let expected =
      """
      if foo(
        bar: someValue, qux: anotherLongValue)
        == expected
      {
        body()
      }

      """

    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func comparisonOperatorYieldsToBothSideCalls() {
    let input =
      """
      let eq = f(aValue, bValue, cValue) == g(dValue, eValue, fValue)
      """

    let expected =
      """
      let eq = f(
        aValue, bValue, cValue) == g(dValue, eValue, fValue)

      """

    assertLayout(input: input, expected: expected, linelength: 60)
  }

  @Test func assignmentFallsBackToEqualsBreakWhenNeeded() {
    // When even the first operand of the RHS doesn't fit with the LHS, break at = too.
    let input =
      """
      veryLongPropertyName = aVeryLongExpressionName + anotherLongExpressionName
      """

    let expected35 =
      """
      veryLongPropertyName =
        aVeryLongExpressionName
        + anotherLongExpressionName

      """

    assertLayout(input: input, expected: expected35, linelength: 35)
  }
}
