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
struct AssignmentExprTests: LayoutTesting {
  @Test func basicAssignmentExprs() {
    let input =
      """
      foo = bar
      someVeryLongVariableName = anotherPrettyLongVariableName
      shortName = superLongNameForAVariable
      """
    let expected =
      """
      foo = bar
      someVeryLongVariableName =
        anotherPrettyLongVariableName
      shortName =
        superLongNameForAVariable

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func assignmentExprsWithGroupedOperators() {
    let input =
      """
      someVeryLongVariableName = anotherPrettyLongVariableName && someOtherOperand
      shortName = wxyz + aaaaaa + bbbbbb + cccccc
      longerName = wxyz + aaaaaa + bbbbbb + cccccc || zzzzzzz
      """
    let expected =
      """
      someVeryLongVariableName =
        anotherPrettyLongVariableName
        && someOtherOperand
      shortName = wxyz + aaaaaa
        + bbbbbb + cccccc
      longerName = wxyz + aaaaaa
        + bbbbbb + cccccc || zzzzzzz

      """

    assertLayout(input: input, expected: expected, linelength: 30)
  }

  @Test func assignmentOperatorFromSequenceWithFunctionCalls() {
    let input =
      """
      result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(foo, bar: bar, baz: baz)
      result += someOpFetchingFunc(foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
      result = firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
      result += firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
      """

    let expectedWithArgBinPacking =
      """
      result = firstOp + secondOp
        + someOpFetchingFunc(
          foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      result += someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
        + someOtherOperand
        + andAThirdOneForReasons
      result = firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo, bar, baz) + nextOp
        + lastOp
      result += firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo, bar, baz) + nextOp
        + lastOp

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(
      input: input,
      expected: expectedWithArgBinPacking,
      linelength: 35,
      configuration: config
    )

    let expectedWithBreakBeforeEachArg =
      """
      result = firstOp + secondOp
        + someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        )
      result = someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      )
      result += someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      )
      result = someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      ) + someOtherOperand
        + andAThirdOneForReasons
      result = firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo,
          bar,
          baz
        ) + nextOp + lastOp
      result += firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo,
          bar,
          baz
        ) + nextOp + lastOp

      """
    config[BeforeEachArgument.self] = true
    assertLayout(
      input: input,
      expected: expectedWithBreakBeforeEachArg,
      linelength: 35,
      configuration: config
    )
  }

  @Test func assignmentWithMemberAccessChain() {
    // The formatter should keep `result = result` on one line, breaking at dots.
    let input =
      """
      result = result.with(\\.leftParen, nil).with(\\.rightParen, nil).with(\\.arguments, LabeledExprListSyntax([]))
      """
    let expected =
      """
      result = result.with(\\.leftParen, nil)
        .with(\\.rightParen, nil).with(
          \\.arguments,
          LabeledExprListSyntax([]))

      """
    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func assignmentWithMemberAccessChainShortEnoughToFit() {
    let input =
      """
      result = result.with(\\.leftParen, nil)
      """
    let expected =
      """
      result = result.with(\\.leftParen, nil)

      """
    assertLayout(input: input, expected: expected, linelength: 50)
  }

  @Test func assignmentWithSimpleMemberAccessChain() {
    // The chain `.` (rank 2) wins over the function-call args break (rank 3): wrap before
    // `.split` first; the args still overflow, so they wrap inside next.
    let input =
      """
      components = path.split(separator: "/", omittingEmptySubsequences: false).map { String($0) }
      """
    let expected =
      """
      components = path
        .split(
          separator: "/",
          omittingEmptySubsequences: false
        ).map { String($0) }

      """
    assertLayout(input: input, expected: expected, linelength: 40)
  }

  @Test func assignmentWithMemberAccessLHSAndChainRHS() {
    // LHS is a short member access (`obj.property`); RHS is a long chain that overflows the
    // line. Per documented break precedence, the chain `.` (rank 2) must fire before the
    // function-call args break (rank 3) and before the `=` break (rank 4). Expect the wrap
    // before `.decodeObject` rather than inside its argument list.
    let input =
      """
      queryOutput.debug_recordChangeTag = coder.decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
      """
    let expected =
      """
      queryOutput.debug_recordChangeTag = coder
        .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue

      """
    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func assignmentWithMemberAccessLHSAndChainRHSShortLine() {
    // At a shorter line length the chain should also break before `.intValue` (rank 2 again),
    // before falling through to inner breaks.
    let input =
      """
      queryOutput.debug_recordChangeTag = coder.decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?.intValue
      """
    let expected =
      """
      queryOutput.debug_recordChangeTag = coder
        .decodeObject(of: NSNumber.self, forKey: "_recordChangeTag")?
        .intValue

      """
    assertLayout(input: input, expected: expected, linelength: 70)
  }

  @Test func assignmentWithChainAsCallArgumentFitsOnOneLine() {
    // The RHS is `.init(type: chain)` where the chain
    // `type.with(\.leadingTrivia, .space).with(\.trailingTrivia, .space)` fits within the
    // indented argument body. Regression guard: the inner second `.with(...)` must NOT
    // break its arg list one-per-line — the chain stays intact on a single line. The
    // closing `))` collapses onto the chain line per the project's chain-fits convention
    // (see `assignmentWithMemberAccessChain` ).
    let input =
      """
      replacement.typeAnnotation = .init(type: type.with(\\.leadingTrivia, .space).with(\\.trailingTrivia, .space))
      """
    let expected =
      """
      replacement.typeAnnotation = .init(
        type: type.with(\\.leadingTrivia, .space).with(\\.trailingTrivia, .space))

      """
    assertLayout(input: input, expected: expected, linelength: 100)
  }

  @Test func assignmentPatternBindingFromSequenceWithFunctionCalls() {
    let input =
      """
      let result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
      let result = firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
      """

    let expectedWithArgBinPacking =
      """
      let result = firstOp + secondOp
        + someOpFetchingFunc(
          foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
        + someOtherOperand
        + andAThirdOneForReasons
      let result = firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo, bar, baz) + nextOp
        + lastOp

      """

    var config = Configuration.forTesting
    config[BeforeEachArgument.self] = false
    assertLayout(
      input: input,
      expected: expectedWithArgBinPacking,
      linelength: 35,
      configuration: config
    )

    let expectedWithBreakBeforeEachArg =
      """
      let result = firstOp + secondOp
        + someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        )
      let result = someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      )
      let result = someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      ) + someOtherOperand
        + andAThirdOneForReasons
      let result = firstOp + secondOp
        + thirdOp
        + someOpFetchingFunc(
          foo,
          bar,
          baz
        ) + nextOp + lastOp

      """
    config[BeforeEachArgument.self] = true
    assertLayout(
      input: input,
      expected: expectedWithBreakBeforeEachArg,
      linelength: 35,
      configuration: config
    )
  }
}
