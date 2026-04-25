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
@_spi(ExperimentalLanguageFeatures) import SwiftParser
import SwiftSyntax
import SwiftOperators
import SwiftiomaticTestSupport

@testable import SwiftiomaticKit

protocol LayoutTesting {}

extension LayoutTesting {
    /// Asserts that the input string, when pretty printed, is equal to the expected string.
    func assertLayout(
        input: String,
        expected: String,
        linelength: Int,
        configuration: Configuration = .forTesting,
        whitespaceOnly: Bool = false,
        findings: [FindingSpec] = [],
        experimentalFeatures: Parser.ExperimentalFeatures = [],
        sourceLocation: TestSourceLocation = #_sourceLocation
    ) {
        var configuration = configuration
        configuration[LineLength.self] = linelength

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
    let sourceFileSyntax = OperatorTable.standardOperators.foldAll(
        Parser.parse(source: source, experimentalFeatures: experimentalFeatures)
    ) { _ in }
    .as(SourceFileSyntax.self)!
    let context = makeTestContext(
        sourceFileSyntax: sourceFileSyntax,
        configuration: configuration,
        selection: selection,
        findingConsumer: findingConsumer
    )
    // Apply layout-affecting format rules whose decisions live outside the pretty printer
    // (currently just WrapTernary, which inserts discretionary newlines for ternaries that would
    // overflow the line length). Other rules are intentionally skipped here so layout tests
    // remain focused on PP behavior.
    let transformedSyntax: Syntax
    if context.shouldFormat(WrapTernary.self, node: Syntax(sourceFileSyntax)) {
        transformedSyntax = WrapTernary(context: context).rewrite(Syntax(sourceFileSyntax))
    } else {
        transformedSyntax = Syntax(sourceFileSyntax)
    }
    let printer = LayoutCoordinator(
        context: context,
        source: source,
        node: transformedSyntax,
        printTokenStream: false,
        whitespaceOnly: whitespaceOnly
    )
    return (printer.prettyPrint(), context)
}
