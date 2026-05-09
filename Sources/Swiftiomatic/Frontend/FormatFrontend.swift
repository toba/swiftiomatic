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
import SwiftSyntax
import SwiftiomaticKit
import SwiftDiagnostics

/// The frontend for formatting operations.
final class FormatFrontend: Frontend, @unchecked Sendable {
    /// Whether or not to format the Swift file in-place.
    private let inPlace: Bool

    /// Optional reporter that captures per-file format outcomes for structured output.
    let jsonReporter: JSONFormatReporter?

    init(
        configurationOptions: ConfigurationOptions,
        lintFormatOptions: LintFormatOptions,
        inPlace: Bool,
        jsonReporter: JSONFormatReporter? = nil
    ) {
        self.inPlace = inPlace
        self.jsonReporter = jsonReporter
        super.init(configurationOptions: configurationOptions, lintFormatOptions: lintFormatOptions)
    }

    override func processFile(_ fileToProcess: FileToProcess) {
        // In format mode, the diagnostics engine is reserved for fatal messages. Pass nil as the
        // finding consumer to ignore findings emitted while the syntax tree is processed because
        // they will be fixed automatically if they can be, or ignored otherwise.
        let formatter = RewriteCoordinator(
            configuration: fileToProcess.configuration,
            findingConsumer: nil
        )
        formatter.debugOptions = debugOptions

        let url = fileToProcess.url
        guard let source = fileToProcess.sourceText else {
            diagnosticsEngine.emitError(
                "Unable to format \(url.relativePath): file is not readable or does not exist."
            )
            return
        }

        let diagnosticHandler: (SwiftDiagnostics.Diagnostic, SourceLocation) -> Void = {
            diagnostic, location in
            guard !self.lintFormatOptions.ignoreUnparsableFiles else { return }
            self.diagnosticsEngine.consumeParserDiagnostic(diagnostic, location)
        }
        var stdoutStream = FileHandleTextOutputStream(FileHandle.standardOutput)

        do {
            if inPlace {
                var buffer = ""
                try formatter.format(
                    source: source,
                    assumingFileURL: url,
                    selection: fileToProcess.selection,
                    experimentalFeatures: Set(lintFormatOptions.experimentalFeatures),
                    to: &buffer,
                    parsingDiagnosticHandler: diagnosticHandler
                )

                let bufferData = buffer.data(using: .utf8)!  // Conversion to UTF-8 cannot fail
                if buffer != source {
                    try bufferData.write(to: url, options: .atomic)
                    jsonReporter?.recordChanged(
                        file: url.standardizedFileURL.path,
                        bytesBefore: source.utf8.count,
                        bytesAfter: bufferData.count
                    )
                } else {
                    jsonReporter?.recordUnchanged(file: url.standardizedFileURL.path)
                }
            } else {
                try formatter.format(
                    source: source,
                    assumingFileURL: url,
                    selection: fileToProcess.selection,
                    experimentalFeatures: Set(lintFormatOptions.experimentalFeatures),
                    to: &stdoutStream,
                    parsingDiagnosticHandler: diagnosticHandler
                )
            }
        } catch SwiftiomaticError.fileContainsInvalidSyntax {
            jsonReporter?.recordSkipped(
                file: url.standardizedFileURL.path,
                reason: "unparsable"
            )
            guard !lintFormatOptions.ignoreUnparsableFiles else {
                guard !inPlace else { return }
                stdoutStream.write(source)
                return
            }
            // Otherwise, relevant diagnostics about the problematic nodes have already been
            // emitted; we don't need to print anything else.
        } catch {
            jsonReporter?.recordSkipped(
                file: url.standardizedFileURL.path,
                reason: error.localizedDescription
            )
            diagnosticsEngine.emitError(
                "Unable to format \(url.relativePath): \(error.localizedDescription)."
            )
        }
    }
}
