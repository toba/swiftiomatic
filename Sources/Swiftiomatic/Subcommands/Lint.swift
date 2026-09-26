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
import ArgumentParser
import SwiftiomaticKit

/// Output format for diagnostics emitted by `lint` and `format` subcommands.
///
/// `sarif` and `agent` are valid only for `lint`.
enum Reporter: String, ExpressibleByArgument, CaseIterable, Sendable { case text, json, sarif, agent }

extension SwiftiomaticCommand {
    /// Emits style diagnostics for one or more files containing Swift code.
    struct Lint: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Diagnose style issues in Swift source code",
            discussion: "When no files are specified, it expects the source from standard input."
        )

        @OptionGroup()
        var configurationOptions: ConfigurationOptions

        @OptionGroup()
        var lintOptions: LintFormatOptions

        @Flag(
            name: .shortAndLong,
            help: "Treat all findings as errors instead of warnings."
        )
        var strict = false

        @Flag(
            name: .long,
            help: """
                Disable the on-disk lint cache. By default, lint findings are cached under the \
                enclosing package's .build/sm-lint-cache/ keyed by file content hash and \
                configuration fingerprint, so unchanged files skip re-linting on the next run.
                """
        )
        var noCache = false

        @Option(
            name: .long,
            help: """
                Output format for diagnostics. `text` (default) writes human-readable diagnostics to \
                stderr. `json` suppresses the text output and writes a JSON array of findings to \
                stdout. `sarif` suppresses the text output and writes a SARIF 2.1.0 log to stdout. \
                `agent` suppresses the text output and writes compact JSON to stdout, with one entry \
                per rule per file and role-tagged evidence.
                """
        )
        var reporter: Reporter = .text

        @Option(
            name: .long,
            help: """
                A "start:end" pair of 1-based line numbers that the change touched. Every finding is \
                labeled `introduced` when its line is in a range and `existing` otherwise. Repeat \
                the option for more ranges. Only valid for a single file.
                """
        )
        var changedLines: [ClosedRange<Int>] = []

        func validate() throws {
            if !changedLines.isEmpty, lintOptions.paths.count > 1 {
                throw ValidationError("'--changed-lines' is only valid when linting a single file")
            }
        }

        func run() throws {
            // the cache root follows the first real input, so a run started outside the package
            // still writes to that package's .build rather than to the working directory
            let startPath = lintOptions.paths.first { $0 != "-" }
            let cache: LintCache? = (noCache || LintCache.disabledByEnvironment)
                ? nil
                : LintCache(startingAt: startPath)

            let jsonReporter: JSONLintReporter? = (reporter == .json) ? JSONLintReporter() : nil
            let sarifReporter: SARIFLintReporter? =
                (reporter == .sarif) ? SARIFLintReporter(toolVersion: smVersion) : nil
            let agentReporter: AgentLintReporter? = (reporter == .agent) ? AgentLintReporter() : nil

            var extraHandlers: [@Sendable (Diagnostic) -> Void] = []

            if let jsonReporter {
                extraHandlers.append { diagnostic in
                    jsonReporter.record(JSONLintReporter.Entry(
                        file: diagnostic.location?.file, line: diagnostic.location?.line,
                        column: diagnostic.location?.column, severity: diagnostic.severity.rawValue,
                        rule: diagnostic.category, message: diagnostic.message))
                }
            }
            if let sarifReporter {
                extraHandlers.append { diagnostic in
                    // The finding carries its notes as related locations.
                    guard !diagnostic.isRuleNote else { return }
                    let level: SARIFLintReporter.Level =
                        switch diagnostic.severity {
                            case .error: .error
                            case .warning: .warning
                            case .note: .note
                        }
                    sarifReporter.record(SARIFLintReporter.Entry(
                        file: diagnostic.location?.file, line: diagnostic.location?.line,
                        column: diagnostic.location?.column, level: level,
                        ruleID: diagnostic.ruleID, message: diagnostic.message,
                        evidence: diagnostic.evidence, status: diagnostic.changeStatus))
                }
            }
            if let agentReporter {
                extraHandlers.append { diagnostic in
                    // The finding carries its notes as evidence.
                    guard !diagnostic.isRuleNote else { return }
                    agentReporter.record(AgentLintReporter.Entry(
                        file: diagnostic.location?.file, line: diagnostic.location?.line,
                        column: diagnostic.location?.column,
                        severity: diagnostic.severity.rawValue, ruleID: diagnostic.ruleID,
                        message: diagnostic.message, status: diagnostic.changeStatus,
                        evidence: diagnostic.evidence))
                }
            }

            let frontend = LintFrontend(
                configurationOptions: configurationOptions,
                lintFormatOptions: lintOptions,
                treatWarningsAsErrors: strict,
                cache: cache,
                additionalDiagnosticHandlers: extraHandlers,
                suppressDefaultDiagnosticPrinter: reporter != .text,
                changedLines: changedLines
            )
            frontend.run()
            jsonReporter?.flush()
            sarifReporter?.flush()
            agentReporter?.flush()

            if frontend.diagnosticsEngine.hasErrors { throw ExitCode.failure }
        }
    }
}

private extension Diagnostic {
    /// The rule ID that the structured reporters show. A parser or tool diagnostic has a fixed ID.
    var ruleID: String {
        switch origin {
            case .rule: category ?? SARIFLintReporter.toolRuleID
            case .ruleNote(let rule): rule
            case .parser: SARIFLintReporter.parserRuleID
            case .tool: SARIFLintReporter.toolRuleID
        }
    }

    /// The attached notes as role-tagged evidence.
    var evidence: [LintEvidence] {
        notes.map { note in
            LintEvidence(
                role: note.role ?? .related, file: note.location?.file,
                line: note.location?.line, column: note.location?.column, message: note.message)
        }
    }
}
