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

import Foundation
@testable import SwiftiomaticKit
import SwiftOperators
@_spi(ExperimentalLanguageFeatures) import SwiftParser
import SwiftSyntax
import Testing
import SwiftiomaticTestSupport

protocol RuleTesting {}

extension RuleTesting {
  /// Performs a lint using the provided linter rule on the provided input and asserts that the
  /// emitted findings are correct.
  func assertLint<LintRule: SyntaxRule & SyntaxVisitor>(
    _ type: LintRule.Type,
    _ markedSource: String,
    findings: [FindingSpec] = [],
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    sourceLocation: TestSourceLocation = #_sourceLocation
  ) {
    let markedText = MarkedText(textWithMarkers: markedSource)
    let unmarkedSource = markedText.textWithoutMarkers
    let tree = Parser.parse(source: unmarkedSource, experimentalFeatures: experimentalFeatures)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    // Force the rule to be enabled while we test it.
    let enabledRule = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(type)] ?? "\(type)"
    let configuration = Configuration.forTesting(enabledRule: enabledRule)
    let context = makeTestContext(
      sourceFileSyntax: sourceFileSyntax,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { _ in }
    )

    var emittedPipelineFindings = [Finding]()
    let pipeline = LintCoordinator(
      configuration: configuration,
      findingConsumer: { emittedPipelineFindings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: unmarkedSource,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )

    // Check that pipeline produces the expected findings
    assertFindings(
      expected: findings,
      markerLocations: markedText.markers,
      emittedFindings: emittedPipelineFindings,
      context: context,
      sourceLocation: sourceLocation
    )
  }

  /// Asserts that the result of applying a formatter to the provided input code yields the output.
  func assertFormatting(
    _ formatType: (some SyntaxRule & SyntaxRewriter).Type,
    input: String,
    expected: String,
    findings: [FindingSpec] = [],
    configuration: Configuration? = nil,
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    sourceLocation: TestSourceLocation = #_sourceLocation
  ) {
    let markedInput = MarkedText(textWithMarkers: input)
    let originalSource: String = markedInput.textWithoutMarkers
    let tree = Parser.parse(source: originalSource, experimentalFeatures: experimentalFeatures)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emittedFindings = [Finding]()

    // Force the rule to be enabled while we test it.
    let enabledRule = ConfigurationRegistry.ruleNameCache[ObjectIdentifier(formatType)] ?? "\(formatType)"
    let configuration = configuration ?? Configuration.forTesting(enabledRule: enabledRule)

    let context = makeTestContext(
      sourceFileSyntax: sourceFileSyntax,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { emittedFindings.append($0) }
    )

    let formatter = formatType.init(context: context)
    let actual = formatter.visit(sourceFileSyntax)
    assertStringsEqualWithDiff("\(actual)", expected, sourceLocation: sourceLocation)

    assertFindings(
      expected: findings,
      markerLocations: markedInput.markers,
      emittedFindings: emittedFindings,
      context: context,
      sourceLocation: sourceLocation
    )

    // Verify that the pretty printer can consume the transformed tree (e.g., it does not contain
    // any unfolded `SequenceExpr`s). Then do a whitespace-insensitive comparison of the two trees
    // to verify that the format rule didn't transform the tree in such a way that it caused the
    // pretty-printer to drop important information (the most likely case is a format rule
    // misplacing trivia in a way that the pretty-printer isn't able to handle).
    let prettyPrintedSource = LayoutCoordinator(
      context: context,
      source: originalSource,
      node: Syntax(actual),
      printTokenStream: false,
      whitespaceOnly: false
    ).prettyPrint()
    let prettyPrintedTree = Parser.parse(
      source: prettyPrintedSource, experimentalFeatures: experimentalFeatures
    )
    #expect(
      whitespaceInsensitiveText(of: actual) == whitespaceInsensitiveText(of: prettyPrintedTree),
      "After pretty-printing and removing fluid whitespace, the files did not match",
      sourceLocation: sourceLocation
    )

    var emittedPipelineFindings = [Finding]()
    let pipeline = RewriteCoordinator(
      configuration: configuration,
      findingConsumer: { emittedPipelineFindings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    var pipelineActual = ""
    try! pipeline.format(
      syntax: sourceFileSyntax,
      source: originalSource,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: nil,
      selection: .infinite,
      to: &pipelineActual
    )
    assertStringsEqualWithDiff(pipelineActual, expected)
    assertFindings(
      expected: findings,
      markerLocations: markedInput.markers,
      emittedFindings: emittedPipelineFindings,
      context: context,
      sourceLocation: sourceLocation
    )
  }
}

/// Returns a string containing a whitespace-insensitive representation of the given source file.
private func whitespaceInsensitiveText(of file: SourceFileSyntax) -> String {
  var result = ""
  for token in file.tokens(viewMode: .sourceAccurate) {
    appendNonspaceTrivia(token.leadingTrivia, to: &result)
    result.append(token.text)
    appendNonspaceTrivia(token.trailingTrivia, to: &result)
  }
  return result
}

/// Appends any non-whitespace trivia pieces from the given trivia collection to the output string.
private func appendNonspaceTrivia(_ trivia: Trivia, to string: inout String) {
  for piece in trivia {
    switch piece {
    case .carriageReturnLineFeeds, .carriageReturns, .formfeeds, .newlines, .spaces, .tabs:
      break
    case .lineComment(let comment), .docLineComment(let comment):
      if let lastNonWhitespaceIndex = comment.lastIndex(where: { !$0.isWhitespace }) {
        string.append(contentsOf: comment[...lastNonWhitespaceIndex])
      } else {
        string.append(comment)
      }
    default:
      piece.write(to: &string)
    }
  }
}
