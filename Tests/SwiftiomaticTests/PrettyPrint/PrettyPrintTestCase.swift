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
@_spi(Rules) @_spi(Testing) import Swiftiomatic
import SwiftOperators
@_spi(ExperimentalLanguageFeatures) import SwiftParser
import SwiftSyntax
import Testing
@_spi(Testing) import SwiftiomaticTestSupport

protocol PrettyPrintTesting {}

extension PrettyPrintTesting {
  /// Asserts that the input string, when pretty printed, is equal to the expected string.
  func assertPrettyPrintEqual(
    input: String,
    expected: String,
    linelength: Int,
    configuration: Configuration = Configuration.forTesting,
    whitespaceOnly: Bool = false,
    findings: [FindingSpec] = [],
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    sourceLocation: TestSourceLocation = #_sourceLocation
  ) {
    var configuration = configuration
    configuration.lineLength = linelength

    let markedInput = MarkedText(textWithMarkers: input)
    var emittedFindings = [Finding]()

    // Assert that the input, when formatted, is what we expected.
    let (formatted, context) = prettyPrintedSource(
      markedInput.textWithoutMarkers,
      configuration: configuration,
      selection: markedInput.selection,
      whitespaceOnly: whitespaceOnly,
      experimentalFeatures: experimentalFeatures,
      findingConsumer: { emittedFindings.append($0) }
    )
    assertStringsEqualWithDiff(
      formatted,
      expected,
      "Pretty-printed result was not what was expected",
      sourceLocation: sourceLocation
    )

    // FIXME: It would be nice to check findings when whitespaceOnly == false, but their locations
    // are wrong.
    if whitespaceOnly {
      assertFindings(
        expected: findings,
        markerLocations: markedInput.markers,
        emittedFindings: emittedFindings,
        context: context,
        sourceLocation: sourceLocation
      )
    }

    // Idempotency check: Running the formatter multiple times should not change the outcome.
    // Assert that running the formatter again on the previous result keeps it the same.
    // But if we have ranges, they aren't going to be valid for the formatted text.
    if case .infinite = markedInput.selection {
      let (reformatted, _) = prettyPrintedSource(
        formatted,
        configuration: configuration,
        selection: markedInput.selection,
        whitespaceOnly: whitespaceOnly,
        experimentalFeatures: experimentalFeatures,
        findingConsumer: { _ in }  // Ignore findings during the idempotence check.
      )
      assertStringsEqualWithDiff(
        reformatted,
        formatted,
        "Pretty printer is not idempotent",
        sourceLocation: sourceLocation
      )
    }
  }
}

/// Returns the given source code reformatted with the pretty printer.
private func prettyPrintedSource(
  _ source: String,
  configuration: Configuration,
  selection: Selection,
  whitespaceOnly: Bool,
  experimentalFeatures: Parser.ExperimentalFeatures = [],
  findingConsumer: @escaping (Finding) -> Void
) -> (String, Context) {
  // Ignore folding errors for unrecognized operators so that we fallback to a reasonable default.
  let sourceFileSyntax =
    OperatorTable.standardOperators.foldAll(
      Parser.parse(source: source, experimentalFeatures: experimentalFeatures)
    ) { _ in }
    .as(SourceFileSyntax.self)!
  let context = makeTestContext(
    sourceFileSyntax: sourceFileSyntax,
    configuration: configuration,
    selection: selection,
    findingConsumer: findingConsumer
  )
  let printer = PrettyPrinter(
    context: context,
    source: source,
    node: Syntax(sourceFileSyntax),
    printTokenStream: false,
    whitespaceOnly: whitespaceOnly
  )
  return (printer.prettyPrint(), context)
}
