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
import Synchronization
import SwiftSyntax
import SwiftiomaticKit
import SwiftDiagnostics

/// The frontend for linting operations.
final class LintFrontend: Frontend, @unchecked Sendable {
    /// Optional content-addressed cache of previously emitted findings. `nil` disables caching.
    private let cache: LintCache?

    /// Whether the lint reads the other files of the project through a `ProjectIndex` .
    private let usesProjectIndex: Bool

    /// The project index of each scope root, built by the first file under the root. The workers
    /// of a parallel run wait for that one build.
    private let projectIndexes = Mutex<[String: ProjectIndex]>([:])

    init(
        configurationOptions: ConfigurationOptions,
        lintFormatOptions: LintFormatOptions,
        treatWarningsAsErrors: Bool = false,
        cache: LintCache?,
        usesProjectIndex: Bool = true,
        additionalDiagnosticHandlers: [@Sendable (Diagnostic) -> Void] = [],
        suppressDefaultDiagnosticPrinter: Bool = false,
        changedLines: [ClosedRange<Int>] = [],
        changedSince: GitChangedLines? = nil,
        onlyChanged: Bool = false
    ) {
        self.cache = cache
        self.usesProjectIndex = usesProjectIndex
        super.init(
            configurationOptions: configurationOptions,
            lintFormatOptions: lintFormatOptions,
            treatWarningsAsErrors: treatWarningsAsErrors,
            additionalDiagnosticHandlers: additionalDiagnosticHandlers,
            suppressDefaultDiagnosticPrinter: suppressDefaultDiagnosticPrinter,
            changedLines: changedLines,
            changedSince: changedSince,
            onlyChanged: onlyChanged
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

        let projectIndex = projectIndex(for: fileToProcess, source: source)

        if cacheEligible, let cache {
            let absolutePath = url.standardizedFileURL.path
            let contentHash = LintCache.contentHash(of: source)
            let fingerprint = cache.fingerprint(
                for: fileToProcess.configuration,
                key: fileToProcess.configurationKey
            )

            // A record whose findings read other files is valid while those files are unchanged
            if let record = cache.lookup(
                absolutePath: absolutePath,
                contentHash: contentHash,
                fingerprint: fingerprint
            ), record.dependencies.isEmpty || record.dependencyDigest == projectIndex?.digest(
                of: record.dependencies, from: ProjectIndex.key(for: url.path))
            {
                for entry in record.entries {
                    diagnosticsEngine.consumeCachedEntry(entry, lintedFile: url.relativePath)
                }
                return
            }

            // Miss: lint, capture findings as we forward them, and persist on success.
            let capturer = CapturingFindingConsumer(
                lintedFile: url.relativePath,
                forward: diagnosticsEngine.consumeFinding
            )
            var parserDiagnosticEmitted = false

            let linter = LintCoordinator(
                configuration: fileToProcess.configuration,
                findingConsumer: capturer.consume
            )
            linter.debugOptions = debugOptions
            linter.projectIndex = projectIndex

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
                var record = capturer.record()
                let keys = linter.projectKeys.sorted()

                if let projectIndex, !keys.isEmpty {
                    record.dependencies = keys
                    record.dependencyDigest = projectIndex.digest(
                        of: keys, from: ProjectIndex.key(for: url.path))
                }
                cache.store(
                    absolutePath: absolutePath,
                    contentHash: contentHash,
                    fingerprint: fingerprint,
                    record: record
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
        linter.projectIndex = projectIndex

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

extension LintFrontend {
    /// The index of the project that holds the file, or `nil` when no project holds it
    ///
    /// Files on disk share one index for each scope root. Text from standard input replaces the
    /// file at its assumed path, so it gets an index of its own. Text from standard input without
    /// `--assume-filename` has no path and no project.
    private func projectIndex(for file: FileToProcess, source: String) -> ProjectIndex? {
        guard usesProjectIndex, file.url.path != "<stdin>",
              let root = ProjectIndex.scopeRoot(startingAt: file.url.path) else { return nil }
        let excludes = excludePatterns(forProjectRoot: root)

        if file.isStandardInput {
            return ProjectIndex.build(
                root: root, excludes: excludes, overrides: [file.url.path: source],
                cacheDirectory: cache?.root)
        }
        return projectIndexes.withLock { indexes in
            if let index = indexes[root.path] { return index }
            let index = ProjectIndex.build(
                root: root, excludes: excludes, cacheDirectory: cache?.root)
            indexes[root.path] = index
            return index
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
    /// The displayed path of the linted file. It matches the file of the findings in that file.
    private let lintedFile: String
    private let forward: (Finding) -> Void
    private var entries: [LintCache.Entry] = []

    init(lintedFile: String, forward: @escaping (Finding) -> Void) {
        self.lintedFile = lintedFile
        self.forward = forward
    }

    func consume(_ finding: Finding) {
        let entry = LintCache.Entry(
            category: "\(finding.category)",
            severity: finding.severity,
            message: finding.message.text,
            location: finding.location.map { LintCache.Location($0, lintedFile: lintedFile) },
            notes: finding.notes.map { note in
                LintCache.Note(
                    message: note.message.text,
                    location: note.location.map { LintCache.Location($0, lintedFile: lintedFile) },
                    role: note.role
                )
            }
        )
        entries.append(entry)
        forward(finding)
    }

    func record() -> LintCache.Record { LintCache.Record(entries: entries) }
}
