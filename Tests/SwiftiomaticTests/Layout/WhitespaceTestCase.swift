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

@testable import SwiftiomaticKit
import SwiftParser
import SwiftSyntax
import Testing
import SwiftiomaticTestSupport

protocol WhitespaceTesting {}

extension WhitespaceTesting {
  /// Perform whitespace linting by comparing the input text from the user with the expected
  /// formatted text.
  func assertWhitespaceLint(
    input: String,
    expected: String,
    linelength: Int? = nil,
    findings: [FindingSpec],
    sourceLocation: TestSourceLocation = #_sourceLocation
  ) {
    let markedText = MarkedText(textWithMarkers: input)

    let sourceFileSyntax = Parser.parse(source: markedText.textWithoutMarkers)
    var configuration = Configuration.forTesting
    if let linelength = linelength {
      configuration[LineLength.self] = linelength
    }

    var emittedFindings = [Finding]()

    let context = makeTestContext(
      sourceFileSyntax: sourceFileSyntax,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { emittedFindings.append($0) }
    )
    let linter = WhitespaceLinter(
      user: markedText.textWithoutMarkers,
      formatted: expected,
      context: context
    )
    linter.lint()

    assertFindings(
      expected: findings,
      markerLocations: markedText.markers,
      emittedFindings: emittedFindings,
      context: context,
      sourceLocation: sourceLocation
    )
  }
}
