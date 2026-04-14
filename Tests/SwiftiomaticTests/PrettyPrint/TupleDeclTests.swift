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
struct TupleDeclTests: PrettyPrintTesting {
  @Test func basicTuples() {
    let input =
      """
      let a = (1, 2, 3)
      let a: (Int, Int, Int) = (1, 2, 3)
      let a = (1, 2, 3, 4, 5, 6, 70, 80, 90)
      let a = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
      let a = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
      """

    let expected =
      """
      let a = (1, 2, 3)
      let a: (Int, Int, Int) = (1, 2, 3)
      let a = (
        1, 2, 3, 4, 5, 6, 70, 80, 90
      )
      let a = (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10
      )
      let a = (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
        12
      )

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 37)
  }

  @Test func labeledTuples() {
    let input =
      """
      let a = (A: var1, B: var2)
      var b: (A: Int, B: Double)
      """

    let expected =
      """
      let a = (A: var1, B: var2)
      var b: (A: Int, B: Double)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  @Test func discretionaryNewlineAfterColon() {
    let input =
      """
      let a = (
        reallyLongKeySoTheValueWillWrap:
          value,
        b: c
      )
      let a = (
        shortKey:
          value,
        b:
          c,
        label: Deeply.Nested.InnerMember,
        label2:
          Deeply.Nested.InnerMember
      )
      """

    let expected =
      """
      let a = (
        reallyLongKeySoTheValueWillWrap:
          value,
        b: c
      )
      let a = (
        shortKey:
          value,
        b:
          c,
        label: Deeply.Nested
          .InnerMember,
        label2:
          Deeply.Nested
          .InnerMember
      )

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  @Test func groupsTrailingComma() {
    let input =
      """
      let t = (
        condition ? firstOption : secondOption,
        bar()
      )
      """

    let expected =
      """
      let t = (
        condition
          ? firstOption
          : secondOption,
        bar()
      )

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }
}
