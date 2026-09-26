//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftiomaticKit
import Synchronization
import SwiftDiagnostics
import TobaConcurrency

/// Unifies the handling of findings from the linter, parsing errors from the syntax parser, and
/// generic errors from the frontend so that they are emitted in a uniform fashion.
final class DiagnosticsEngine: Sendable {
    /// The handler functions that will be called to process diagnostics that are emitted.
    private let handlers: [@Sendable (Diagnostic) -> Void]

    /// Mutable state protected by a mutex for thread-safe access during concurrent processing.
    private struct State {
        var hasErrors = false
        var hasWarnings = false
    }
    private let state = Mutex(State())

    /// A Boolean value indicating whether any errors were emitted by the diagnostics engine.
    var hasErrors: Bool { state(get: \.hasErrors) }

    /// A Boolean value indicating whether any warnings were emitted by the diagnostics engine.
    var hasWarnings: Bool { state(get: \.hasWarnings) }

    /// Whether to upgrade all warnings to errors.
    private let treatWarningsAsErrors: Bool

    /// The changed 1-based line ranges. When not empty, each diagnostic with a location, other than
    /// a rule note, gets an `introduced` or `existing` change status.
    private let changedLines: [ClosedRange<Int>]

    /// The source of the changed lines of each file. When it is set, each diagnostic with a
    /// location, other than a rule note, gets an `introduced` or `existing` change status.
    private let changedSince: GitChangedLines?

    /// Whether to drop each finding whose change status is `existing`, together with its notes.
    private let onlyChanged: Bool

    /// Creates a new diagnostics engine with the given diagnostic handlers.
    ///
    /// - Parameter diagnosticsHandlers: An array of functions, each of which takes a `Diagnostic`
    ///   as its sole argument and returns `Void` . The functions are called whenever a diagnostic
    ///   is received by the engine.
    init(
        diagnosticsHandlers: [@Sendable (Diagnostic) -> Void],
        treatWarningsAsErrors: Bool = false,
        changedLines: [ClosedRange<Int>] = [],
        changedSince: GitChangedLines? = nil,
        onlyChanged: Bool = false
    ) {
        handlers = diagnosticsHandlers
        self.treatWarningsAsErrors = treatWarningsAsErrors
        self.changedLines = changedLines
        self.changedSince = changedSince
        self.onlyChanged = onlyChanged
    }

    /// Returns the change status of a diagnostic, or nil when no changed lines apply to it.
    ///
    /// When git cannot find the changed lines of a file, the function emits one error for that
    /// file. The findings of that file then get the `existing` status.
    private func changeStatus(of diagnostic: Diagnostic) -> ChangeStatus? {
        guard !diagnostic.isRuleNote, let location = diagnostic.location else { return nil }

        if let changedSince {
            let lines: [ClosedRange<Int>]
            switch changedSince.changedLines(forFile: location.file) {
                case .success(let ranges): lines = ranges
                case .failure(let failure):
                    reportOnce(failure)
                    lines = []
            }
            return ChangeStatus(line: location.line, changedLines: lines)
        }
        guard !changedLines.isEmpty else { return nil }
        return ChangeStatus(line: location.line, changedLines: changedLines)
    }

    /// The files whose git failure the engine already reported.
    private let reportedFailures = Mutex<Set<String>>([])

    private func reportOnce(_ failure: GitChangedLines.Failure) {
        guard reportedFailures.withLock({ $0.insert(failure.file).inserted }) else { return }
        emitError(failure.description)
    }

    /// Emits the diagnostic by passing it to the registered handlers, and tracks whether it was an
    /// error or warning diagnostic.
    private func emit(_ diagnostic: Diagnostic) {
        var diagnostic = diagnostic
        if treatWarningsAsErrors, diagnostic.severity == .warning { diagnostic.severity = .error }

        diagnostic.changeStatus = changeStatus(of: diagnostic)
        if onlyChanged, diagnostic.changeStatus == .existing { return }

        switch diagnostic.severity {
            case .error: state.withLock { $0.hasErrors = true }
            case .warning: state.withLock { $0.hasWarnings = true }
            default: break
        }

        for handler in handlers { handler(diagnostic) }
    }

    /// Emits a generic error message.
    ///
    /// - Parameters:
    ///   - message: The message associated with the error.
    ///   - location: The location in the source code associated with the error, or nil if there is
    ///     no location associated with the error.
    func emitError(_ message: String, location: SourceLocation? = nil) {
        emit(
            Diagnostic(
                severity: .error,
                location: location.map(Diagnostic.Location.init),
                message: message
            ))
    }

    /// Emits a generic warning message.
    ///
    /// - Parameters:
    ///   - message: The message associated with the error.
    ///   - location: The location in the source code associated with the error, or nil if there is
    ///     no location associated with the error.
    func emitWarning(_ message: String, location: SourceLocation? = nil) {
        emit(
            Diagnostic(
                severity: .warning,
                location: location.map(Diagnostic.Location.init),
                message: message
            ))
    }

    /// Emits a finding from the linter and any of its associated notes as diagnostics.
    ///
    /// - Parameter finding: The finding that should be emitted.
    func consumeFinding(_ finding: Finding) {
        let notes = finding.notes.map { note in
            Diagnostic(
                severity: .note,
                location: note.location.map(Diagnostic.Location.init),
                message: "\(note.message)",
                origin: .ruleNote("\(finding.category)"),
                role: note.role
            )
        }
        emit(diagnosticMessage(for: finding), notes: notes)
    }

    /// Replays a previously cached finding (and its notes) through the same emit path
    /// `consumeFinding` uses, so cached and freshly-linted runs produce byte-identical output and
    /// identical exit-code accounting.
    func consumeCachedEntry(_ cached: LintCache.Entry) {
        let severity: Diagnostic.Severity =
            switch cached.severity {
                case .error: .error
                case .warn, .no: .warning
            }
        let notes = cached.notes.map { note in
            Diagnostic(
                severity: .note,
                location: note.location.map { Diagnostic.Location($0.asFindingLocation) },
                message: note.message,
                origin: .ruleNote(cached.category),
                role: note.role ?? .related
            )
        }
        emit(
            Diagnostic(
                severity: severity,
                location: cached.location.map { Diagnostic.Location($0.asFindingLocation) },
                category: cached.category,
                message: cached.message
            ),
            notes: notes
        )
    }

    /// Emits a finding with its notes attached, then emits each note on its own for the handlers
    /// that print notes as separate lines.
    private func emit(_ finding: Diagnostic, notes: [Diagnostic]) {
        var finding = finding
        finding.notes = notes
        // The notes of a dropped finding go with it.
        if onlyChanged, changeStatus(of: finding) == .existing { return }
        emit(finding)
        for note in notes { emit(note) }
    }

    /// Emits a diagnostic from the syntax parser and any of its associated notes.
    ///
    /// - Parameter diagnostic: The syntax parser diagnostic that should be emitted.
    func consumeParserDiagnostic(
        _ diagnostic: SwiftDiagnostics.Diagnostic,
        _ location: SourceLocation
    ) { emit(diagnosticMessage(for: diagnostic.diagMessage, at: location)) }

    /// Converts a diagnostic message from the syntax parser into a diagnostic message that can be
    /// used by the `TSCBasic` diagnostics engine and returns it.
    private func diagnosticMessage(
        for message: SwiftDiagnostics.DiagnosticMessage,
        at location: SourceLocation
    ) -> Diagnostic {
        let severity: Diagnostic.Severity

        switch message.severity {
            case .error: severity = .error
            case .warning: severity = .warning
            case .note: severity = .note
            case .remark: severity = .note  // should we model this?
        }
        return .init(
            severity: severity,
            location: Diagnostic.Location(location),
            category: nil,
            message: message.message,
            origin: .parser
        )
    }

    /// Converts a lint finding into a diagnostic message that can be used by the `TSCBasic`
    /// diagnostics engine and returns it.
    private func diagnosticMessage(for finding: Finding) -> Diagnostic {
        let severity: Diagnostic.Severity =
            switch finding.severity {
                case .error: .error
                case .warn, .no: .warning
            }
        return .init(
            severity: severity,
            location: finding.location.map(Diagnostic.Location.init),
            category: "\(finding.category)",
            message: "\(finding.message.text)"
        )
    }
}
