import Foundation
import SwiftParser
import SwiftSyntax

/// Orchestrates parsing and analysis of Swift source files.
///
/// Runs both suggest checks (deep AST analysis via SyntaxVisitor subclasses)
/// and lint rules (SwiftLint rule protocol implementations) through a single pass.
struct Analyzer: Sendable {
    /// Categories to analyze. Empty means all.
    let categories: Set<Category>

    /// Minimum confidence to include in results.
    let minConfidence: Confidence

    /// Minimum severity to include in results.
    let minSeverity: Severity

    /// Optional SourceKit-backed type resolver for semantic analysis.
    let typeResolver: (any TypeResolver)?

    /// Instantiated lint rules to run alongside suggest checks.
    let lintRules: [any Rule]

    /// Compiler arguments for AnalyzerRules (if any).
    let compilerArguments: [String]

    /// When true, skip suggest checks entirely (lint-only mode).
    let skipSuggest: Bool

    init(
        categories: Set<Category> = [],
        minConfidence: Confidence = .low,
        minSeverity: Severity = .low,
        typeResolver: (any TypeResolver)? = nil,
        lintRules: [any Rule] = [],
        compilerArguments: [String] = [],
        skipSuggest: Bool = false,
    ) {
        self.categories = categories
        self.minConfidence = minConfidence
        self.minSeverity = minSeverity
        self.typeResolver = typeResolver
        self.lintRules = lintRules
        self.compilerArguments = compilerArguments
        self.skipSuggest = skipSuggest
    }

    /// Analyze the given file paths and return unified diagnostics.
    func analyze(paths: [String]) async -> [Diagnostic] {
        let files = FileDiscovery.findSwiftFiles(in: paths)
        guard !files.isEmpty else { return [] }

        var diagnostics: [Diagnostic] = []

        // Run suggest checks (unless skipped)
        if !skipSuggest {
            let parsed = await parseFiles(files)
            let findings = await runSuggestChecks(on: parsed)
            diagnostics += findings.map { $0.toDiagnostic() }
        }

        // Run lint rules
        diagnostics += runLintRules(on: files)

        // Filter by confidence and severity
        diagnostics = diagnostics.filter { d in
            d.confidence >= minConfidence
                && (d.severity == .error || minSeverity <= .low)
        }

        return diagnostics.sorted()
    }

    /// Analyze and return raw suggest findings (for text output mode).
    func suggestFindings(paths: [String]) async -> [Finding] {
        let files = FileDiscovery.findSwiftFiles(in: paths)
        guard !files.isEmpty else { return [] }

        let parsed = await parseFiles(files)
        var findings = await runSuggestChecks(on: parsed)

        // Filter
        findings = findings.filter { f in
            f.confidence >= minConfidence && f.severity >= minSeverity
        }
        if !categories.isEmpty {
            findings = findings.filter { categories.contains($0.category) }
        }

        return findings.sorted()
    }

    // MARK: - File Parsing

    private func parseFiles(_ files: [String]) async -> [(file: String, tree: SourceFileSyntax)] {
        await withTaskGroup(of: (String, SourceFileSyntax)?.self) { group in
            for file in files {
                group.addTask {
                    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
                        return nil
                    }
                    let tree = Parser.parse(source: source)
                    return (file, tree)
                }
            }

            var results: [(file: String, tree: SourceFileSyntax)] = []
            for await result in group {
                if let result {
                    results.append(result)
                }
            }
            return results
        }
    }

    // MARK: - Suggest Checks

    private func runSuggestChecks(
        on parsed: [(file: String, tree: SourceFileSyntax)],
    ) async -> [Finding] {
        var findings: [Finding] = []

        // Single-file checks
        for (file, tree) in parsed {
            let checks = makeChecks(for: file)
            for check in checks {
                check.walk(tree)

                // Resolve deferred SourceKit queries if the check has any
                if let baseCheck = check as? BaseCheck,
                   !baseCheck.pendingTypeQueries.isEmpty || typeResolver != nil
                {
                    await baseCheck.resolveTypeQueries()
                }

                findings.append(contentsOf: check.findings)
            }
        }

        // Cross-file checks (dead symbols, structural duplication)
        findings.append(contentsOf: await runCrossFileChecks(on: parsed))

        // Filter by category if specified
        if !categories.isEmpty {
            findings = findings.filter { categories.contains($0.category) }
        }

        return findings
    }

    /// Run cross-file checks that need data from all files.
    private func runCrossFileChecks(
        on parsed: [(file: String, tree: SourceFileSyntax)],
    ) async -> [Finding] {
        let activeCategories = categories.isEmpty ? Set(Category.allCases) : categories
        var findings: [Finding] = []

        if activeCategories.contains(.agentReview) {
            // Pre-index files via SourceKit for USR-based matching if available
            var fileIndexes: [String: FileIndex] = [:]
            if let resolver = typeResolver, resolver.isAvailable {
                for (file, _) in parsed {
                    if let index = await resolver.indexFile(file) {
                        fileIndexes[file] = index
                    }
                }
            }

            // Dead symbols: pass 1 collects declarations, pass 2 finds references
            let symbolTable = SymbolTable()
            for (file, tree) in parsed {
                let collector = DeclarationCollector(
                    filePath: file,
                    symbolTable: symbolTable,
                    fileIndex: fileIndexes[file],
                )
                collector.walk(tree)
            }
            for (file, tree) in parsed {
                let checker = DeadSymbolsCheck(
                    filePath: file,
                    symbolTable: symbolTable,
                    fileIndex: fileIndexes[file],
                )
                checker.walk(tree)
            }
            // Use any file's checker to generate findings (they all share the symbol table)
            if let firstFile = parsed.first {
                let checker = DeadSymbolsCheck(filePath: firstFile.file, symbolTable: symbolTable)
                findings.append(contentsOf: checker.generateFindings())
            }

            // Structural duplication: collect fingerprints from all files, then compare
            var allFingerprints: [(name: String, file: String, line: Int, fingerprint: String)] = []
            for (file, tree) in parsed {
                let dupeCheck = StructuralDuplicationCheck(filePath: file)
                dupeCheck.walk(tree)
                allFingerprints.append(contentsOf: dupeCheck.collectedFunctions)
            }
            if !allFingerprints.isEmpty {
                let dupeCheck = StructuralDuplicationCheck(filePath: "")
                findings.append(
                    contentsOf: dupeCheck.generateDuplicationFindings(
                        allCollected: allFingerprints,
                    ),
                )
            }
        }

        return findings
    }

    /// Create check instances for a file, filtered by selected categories.
    private func makeChecks(for file: String) -> [any Check] {
        var checks: [any Check] = []

        let activeCategories = categories.isEmpty ? Set(Category.allCases) : categories

        if activeCategories.contains(.typedThrows) {
            checks.append(TypedThrowsCheck(filePath: file, typeResolver: typeResolver))
        }
        if activeCategories.contains(.concurrencyModernization) {
            checks.append(ConcurrencyModernizationCheck(filePath: file, typeResolver: typeResolver))
        }
        if activeCategories.contains(.performanceAntiPatterns) {
            checks.append(PerformanceAntiPatternsCheck(filePath: file))
        }
        if activeCategories.contains(.namingHeuristics) {
            checks.append(NamingHeuristicsCheck(filePath: file, typeResolver: typeResolver))
        }
        if activeCategories.contains(.observationPitfalls) {
            checks.append(ObservationPitfallsCheck(filePath: file))
        }
        if activeCategories.contains(.agentReview) {
            checks.append(AgentReviewCheck(filePath: file))
            checks.append(FireAndForgetTaskCheck(filePath: file))
            checks.append(SwiftUILayoutCheck(filePath: file))
        }
        if activeCategories.contains(.anyElimination) {
            checks.append(AnyEliminationCheck(filePath: file, typeResolver: typeResolver))
        }
        if activeCategories.contains(.swift62Modernization) {
            checks.append(Swift62ModernizationCheck(filePath: file))
        }

        return checks
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
