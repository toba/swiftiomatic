import Foundation
import SwiftParser
import SwiftSyntax

/// Orchestrates analysis of Swift source files through a single Rule-based pipeline.
///
/// All analysis — suggest, lint, and async enrichment — flows through `Rule.validate()`.
/// Rules conforming to `AsyncEnrichableRule` get a second pass with SourceKit resolution.
struct Analyzer: Sendable {
    /// Categories to analyze. Empty means all.
    let categories: Set<Category>

    /// Minimum confidence to include in results.
    let minConfidence: Confidence

    /// Minimum severity to include in results.
    let minSeverity: Severity

    /// Optional SourceKit-backed type resolver for semantic analysis.
    let typeResolver: (any TypeResolver)?

    /// Instantiated lint rules to run.
    let lintRules: [any Rule]

    /// Compiler arguments for AnalyzerRules (if any).
    let compilerArguments: [String]

    init(
        categories: Set<Category> = [],
        minConfidence: Confidence = .low,
        minSeverity: Severity = .low,
        typeResolver: (any TypeResolver)? = nil,
        lintRules: [any Rule] = [],
        compilerArguments: [String] = [],
    ) {
        self.categories = categories
        self.minConfidence = minConfidence
        self.minSeverity = minSeverity
        self.typeResolver = typeResolver
        self.lintRules = lintRules
        self.compilerArguments = compilerArguments
    }

    /// Analyze the given file paths and return unified diagnostics.
    func analyze(paths: [String]) async -> [Diagnostic] {
        let files = FileDiscovery.findSwiftFiles(in: paths)
        guard !files.isEmpty else { return [] }

        var diagnostics = runLintRules(on: files)

        // Async enrichment for rules that support it
        if let resolver = typeResolver, resolver.isAvailable {
            let enrichableRules = lintRules.compactMap { $0 as? any AsyncEnrichableRule }
            if !enrichableRules.isEmpty {
                let lintFiles = files.compactMap { SwiftLintFile(path: $0) }
                for file in lintFiles {
                    for rule in enrichableRules {
                        let extra = await rule.enrichAsync(file: file, typeResolver: resolver)
                        diagnostics += extra.map { $0.toDiagnostic() }
                    }
                }
            }
        }

        // Filter by confidence and severity
        diagnostics = diagnostics.filter { d in
            d.confidence >= minConfidence
                && (d.severity == .error || minSeverity <= .low)
        }

        return diagnostics.sorted()
    }

    // MARK: - Lint Rules

    private func runLintRules(on files: [String]) -> [Diagnostic] {
        guard !lintRules.isEmpty else { return [] }

        let storage = RuleStorage()

        // Separate collecting rules (need two-pass) from single-pass rules
        let collectingRules = lintRules.filter { $0 is any AnyCollectingRule }
        let singlePassRules = lintRules.filter { !($0 is any AnyCollectingRule) }

        // Build SwiftLintFiles
        let lintFiles = files.compactMap { SwiftLintFile(path: $0) }

        // Pass 1: collect cross-file info for CollectingRules
        for file in lintFiles {
            for rule in collectingRules {
                rule.collectInfo(for: file, into: storage, compilerArguments: compilerArguments)
            }
        }

        // Pass 2: validate all rules
        var diagnostics: [Diagnostic] = []
        for file in lintFiles {
            for rule in singlePassRules {
                let violations = rule.validate(file: file)
                diagnostics += violations.map { $0.toDiagnostic() }
            }
            for rule in collectingRules {
                let violations = rule.validate(
                    file: file,
                    using: storage,
                    compilerArguments: compilerArguments,
                )
                diagnostics += violations.map { $0.toDiagnostic() }
            }
        }

        return diagnostics
    }
}
