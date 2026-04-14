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

import Swiftiomatic
import Testing

@Suite
struct BinaryOperatorExprTests: PrettyPrintTesting {
  @Test func nonRangeFormationOperatorsAreSurroundedByBreaks() {
    let input =
      """
      x=1+8-9  ^*^  5*4/10
      """

    let expected80 =
      """
      x = 1 + 8 - 9 ^*^ 5 * 4 / 10

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1 + 8
        - 9
        ^*^ 5
        * 4 / 10

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
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
    configuration.spacesAroundRangeFormationOperators = false
    assertPrettyPrintEqual(
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
    configuration.spacesAroundRangeFormationOperators = true
    assertPrettyPrintEqual(
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

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1++
        ... 100
      x =
        1--
        ..< 100
      x =
        1++
        ... 100
      x =
        1--
        ..< 100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
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

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1
        ... -100
      x =
        1
        ..< -100
      x =
        1
        ... √100
      x =
        1
        ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
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

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1++
        ... -100
      x =
        1--
        ..< -100
      x =
        1++
        ... √100
      x =
        1--
        ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
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

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        .first
        ... .last
      x =
        .first
        ..< .last
      x =
        .first
        ... .last
      x =
        .first
        ..< .last

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }
}
