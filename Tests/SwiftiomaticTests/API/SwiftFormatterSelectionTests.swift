//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Swiftiomatic
import SwiftOperators
import SwiftParser
import SwiftSyntax
import Testing
import _SwiftiomaticTestSupport

@Suite
struct SwiftiomaticFormatterSelectionTests {
  @Test func singleLineFormatting() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
          let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
      let y = 2
          let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2]))
  }

  @Test func multipleLinesFormatting() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
          let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
        let y = 2
          let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...3]))
  }

  @Test func disjointLineRanges() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
      let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
      let y = 2
        let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2, 4...4]))
  }

  @Test func partiallyWrappedFunctionSignature() throws {
    let source = """
      func someFunction(
        param1: Int,
      param2: String,
        param3: Double
      ) {}

      """

    let expected = """
      func someFunction(
        param1: Int,
        param2: String,
        param3: Double
      ) {}

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  @Test func complexExpressionIndentation() throws {
    let source = """
      let x = someFunction(
      a,
      b,
      c
      )

      """

    let expected = """
      let x = someFunction(
      a,
        b,
      c
      )

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  @Test func multipleSpacesInsideLine() throws {
    let source = """
      let x = 1
      let y = 1   +   2
      let z = 1

      """

    let expected = """
      let x = 1
      let y = 1 + 2
      let z = 1

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2]))
  }

  @Test func adjacentLongLineNotWrapped() throws {
    let source = """
      let a = 1
      let veryLongVariableNameThatExceedsTheLineLengthLimitAndShouldBeWrappedIfSelected = 42

      """

    let expected = """
      let a = 1
      let veryLongVariableNameThatExceedsTheLineLengthLimitAndShouldBeWrappedIfSelected = 42

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [1...1]))
  }

  @Test func degenerateSignatureIndentation() throws {
    let source = """
      func messyFunction(
        p1: Int,
      p2: String,
          p3: Double
      ) {}

      """

    let expected = """
      func messyFunction(
        p1: Int,
        p2: String,
          p3: Double
      ) {}

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  @Test func outOfBoundsLineRange() throws {
    let source = """
      let x = 1
      let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [10...20]))
  }

  @Test func partialOutOfBoundsLineRange() throws {
    let source = """
      let x = 1
        let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...100]))
  }

  @Test func zeroLineRange() throws {
    let source = """
      let x = 1
      let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [0...0]))
  }

  private func assertFormatting(
    _ source: String,
    expected: String,
    selection: Selection,
    sourceLocation: Testing.SourceLocation = #_sourceLocation
  ) throws {
    var configuration = Configuration.forTesting
    configuration.lineLength = 60

    let formatter = SwiftiomaticFormatter(configuration: configuration)
    var output = ""
    let tree = Parser.parse(source: source)
    let foldedTree = try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    try formatter.format(
      syntax: foldedTree,
      source: source,
      operatorTable: .standardOperators,
      assumingFileURL: nil,
      selection: selection,
      to: &output
    )
    #expect(output == expected, sourceLocation: sourceLocation)
  }
}
