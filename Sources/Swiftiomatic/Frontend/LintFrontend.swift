//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
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

/// The frontend for linting operations.
final class LintFrontend: Frontend, @unchecked Sendable {
    /// Optional content-addressed cache of previously emitted findings. `nil` disables caching.
    private let cache: LintCache?

    init(
        configurationOptions: ConfigurationOptions,
        lintFormatOptions: LintFormatOptions,
        treatWarningsAsErrors: Bool = false,
        cache: LintCache?
    ) {
        self.cache = cache
        super.init(
            configurationOptions: configurationOptions,
            lintFormatOptions: lintFormatOptions,
            treatWarningsAsErrors: treatWarningsAsErrors
        )
    }

    override func processFile(_ fileToProcess: FileToProcess) {
        let url = fileToProcess.url
        guard let source = fileToProcess.sourceText else {
            diagnosticsEngine.emitError(
                "Unable to lint \(url.relativePath): file is not readable or does not exist."
            )
            return
        }

        // Selection-based lint, stdin, and ignoreUnparsableFiles all bypass the cache: cache values
        // are whole-file findings and replaying them under a partial selection or a
        // parser-suppressed run would surface diagnostics outside the requested scope.
        let cacheEligible = cache != nil
            && LintCache.isCacheEligible(
                url: url,
                lines: lintFormatOptions.lines,
                offsets: lintFormatOptions.offsets,
                ignoreUnparsableFiles: lintFormatOptions.ignoreUnparsableFiles
            )

        if cacheEligible, let cache {
            let absolutePath = url.standardizedFileURL.path
            let contentHash = LintCache.contentHash(of: source)
            let fingerprint = cache.fingerprint(for: fileToProcess.configuration)

            if let record = cache.lookup(
                absolutePath: absolutePath,
                contentHash: contentHash,
                fingerprint: fingerprint
            ) {
                for entry in record.entries { diagnosticsEngine.consumeCachedEntry(entry) }
                return
            }

            // Miss: lint, capture findings as we forward them, and persist on success.
            let capturer = CapturingFindingConsumer(forward: diagnosticsEngine.consumeFinding)
            var parserDiagnosticEmitted = false

            let linter = LintCoordinator(
                configuration: fileToProcess.configuration,
                findingConsumer: capturer.consume
            )
            linter.debugOptions = debugOptions

            do {
                try linter.lint(
                    source: source,
                    assumingFileURL: url,
                    experimentalFeatures: Set(lintFormatOptions.experimentalFeatures)
                ) { diagnostic, location in
                    parserDiagnosticEmitted = true
                    self.diagnosticsEngine.consumeParserDiagnostic(diagnostic, location)
                }
            } catch SwiftiomaticError.fileContainsInvalidSyntax {
                parserDiagnosticEmitted = true
            } catch {
                diagnosticsEngine.emitError(
                    "Unable to lint \(url.relativePath): \(error.localizedDescription)."
                )
                return
            }

            // A file the parser couldn't fully parse may have skipped rules entirely. Don't poison
            // the cache with a record that would silently suppress findings on the next run.
            if !parserDiagnosticEmitted {
                cache.store(
                    absolutePath: absolutePath,
                    contentHash: contentHash,
                    fingerprint: fingerprint,
                    record: capturer.record()
                )
            }
            return
        }

        // Cache disabled or ineligible: fall through to the original lint path.
        let linter = LintCoordinator(
            configuration: fileToProcess.configuration,
            findingConsumer: diagnosticsEngine.consumeFinding
        )
        linter.debugOptions = debugOptions

        do {
            try linter.lint(
                source: source,
                assumingFileURL: url,
                experimentalFeatures: Set(lintFormatOptions.experimentalFeatures)
            ) { diagnostic, location in
                guard !self.lintFormatOptions.ignoreUnparsableFiles else { return }
                self.diagnosticsEngine.consumeParserDiagnostic(diagnostic, location)
            }
        } catch SwiftiomaticError.fileContainsInvalidSyntax {
            guard !lintFormatOptions.ignoreUnparsableFiles else { return }
            // Otherwise, relevant diagnostics about the problematic nodes have already been
            // emitted; we don't need to print anything else.
        } catch {
            diagnosticsEngine.emitError(
                "Unable to lint \(url.relativePath): \(error.localizedDescription).")
        }
    }
}

/// Wraps a finding consumer to record every forwarded finding in cache-ready form.
///
/// Single-thread use only. One instance is created per file inside `processFile` and is invoked
/// synchronously from `LintCoordinator.lint(...)` on the same worker thread that constructed it.
/// `entries` is intentionally not synchronized; if a future change hands this consumer to a
/// concurrent worker, the mutable state needs a `Mutex` and the type needs a `Sendable`
/// conformance.
private final class CapturingFindingConsumer {
    private let forward: (Finding) -> Void
    private var entries: [LintCache.Entry] = []

    init(forward: @escaping (Finding) -> Void) { self.forward = forward }

    func consume(_ finding: Finding) {
        let entry = LintCache.Entry(
            category: "\(finding.category)",
            severity: finding.severity,
            message: finding.message.text,
            location: finding.location.map(LintCache.Location.init),
            notes: finding.notes.map { note in
                LintCache.Note(
                    message: note.message.text,
                    location: note.location.map(LintCache.Location.init)
                )
            }
        )
        entries.append(entry)
        forward(finding)
    }

    func record() -> LintCache.Record { LintCache.Record(entries: entries) }
}
