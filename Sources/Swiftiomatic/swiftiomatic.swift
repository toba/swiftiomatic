import Foundation
import ArgumentParser

@main
struct SwiftiomaticCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AST-based Swift code analysis and formatting",
        version: "0.2.0",
        subcommands: [Analyze.self, FormatCommand.self, ListRules.self],
        defaultSubcommand: Analyze.self,
    )
}

// MARK: - Analyze

struct Analyze: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Analyze Swift source files (suggest checks + lint rules)",
        aliases: ["scan", "lint"],
    )

    @Argument(help: "Paths to analyze (files or directories)")
    var paths: [String] = ["."]

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Option(name: .long, help: "Path to .swiftiomatic.yaml config file")
    var config: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Limit to specific suggest categories")
    var category: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Additional exclusion patterns")
    var exclude: [String] = []

    @Option(name: .long, help: "Minimum confidence: high, medium, or low")
    var minConfidence: Confidence = .low

    @Option(name: .long, help: "Minimum severity: high, medium, or low")
    var minSeverity: Severity = .low

    @Flag(name: .long, help: "Summary counts only")
    var quiet = false

    @Flag(name: .long, help: "Enable SourceKit for semantic type resolution")
    var sourcekit = false

    @Option(name: .long, help: "SPM project root for compiler arg discovery (with --sourcekit)")
    var projectRoot: String?

    @Option(
        name: .long, parsing: .upToNextOption,
        help: "Explicit compiler arguments (with --sourcekit)",
    )
    var compilerArgs: [String] = []

    @Flag(name: .long, help: "Autocorrect violations where possible")
    var fix = false

    @Flag(name: .long, help: "Also run format-lint checks")
    var includeFormat = false

    @Option(name: .long, parsing: .upToNextOption, help: "Only run the specified rules")
    var onlyRule: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Disable specific rules")
    var disableRule: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Enable specific opt-in rules")
    var enableRule: [String] = []

    @Flag(name: .long, help: "Skip suggest checks, only run lint rules")
    var lintOnly = false

    @Flag(name: .long, help: "Skip lint rules, only run suggest checks")
    var suggestOnly = false

    mutating func run() async throws {
        let cfg = loadConfig()

        // Build suggest categories
        let categories: Set<Category> =
            if category.isEmpty {
                []
            } else {
                Set(
                    category.compactMap { name in
                        Category.allCases.first { $0.rawValue == name }
                    },
                )
            }

        // Create SourceKit resolver if requested
        var resolver: (any TypeResolver)?
        if sourcekit {
            if !compilerArgs.isEmpty {
                resolver = SourceKitResolver(compilerArgs: compilerArgs)
            } else {
                let root = projectRoot ?? "."
                if let spmResolver = SourceKitResolver(projectRoot: root) {
                    resolver = spmResolver
                } else {
                    FileHandle.standardError.write(
                        Data(
                            "warning: --sourcekit: failed to discover compiler args from '\(root)'; falling back to syntax-only analysis\n"
                                .utf8,
                        ),
                    )
                }
            }
        }

        // Load lint rules (unless suggest-only)
        let lintRules: [any Rule]
        if suggestOnly {
            lintRules = []
        } else {
            let mergedDisabled = Set(disableRule + cfg.disabledRules)
            let mergedEnabled: Set<String>? = enableRule.isEmpty && cfg.enabledLintRules.isEmpty
                ? nil
                : Set(enableRule + cfg.enabledLintRules)
            lintRules = RuleLoader.loadRules(
                enabled: mergedEnabled,
                disabled: mergedDisabled,
                onlyRules: Set(onlyRule),
                ruleConfigs: cfg.lintRuleConfigs,
            )
        }

        let analyzer = Analyzer(
            categories: categories,
            minConfidence: minConfidence,
            minSeverity: minSeverity,
            typeResolver: resolver,
            lintRules: lintRules,
            compilerArguments: compilerArgs,
            skipSuggest: lintOnly,
        )

        // Fix mode
        if fix {
            try runFix(analyzer: analyzer, cfg: cfg)
            return
        }

        // Analysis
        var diagnostics = await analyzer.analyze(paths: paths)

        // Optionally merge format-lint diagnostics
        if includeFormat {
            diagnostics += runFormatLint(cfg: cfg)
            diagnostics.sort()
        }

        // Apply dedup — remove lint rules superseded by format rules when format is active
        if includeFormat {
            diagnostics = RuleDeduplication.deduplicate(diagnostics)
        }

        // Output
        if quiet {
            let grouped = Dictionary(grouping: diagnostics) { $0.category }
            for (category, items) in grouped.sorted(by: { $0.key < $1.key }) {
                print("\(category): \(items.count)")
            }
            print("Total: \(diagnostics.count)")
        } else {
            switch format {
                case .text:
                    // For text mode with suggest findings, use the rich TextFormatter
                    if !lintOnly {
                        let findings = await analyzer.suggestFindings(paths: paths)
                        if !findings.isEmpty {
                            print(TextFormatter.format(findings))
                        }
                    }
                    // Lint diagnostics in Xcode-compatible format
                    let lintDiags = diagnostics.filter { $0.engine == .lint || $0.engine == .format }
                    if !lintDiags.isEmpty {
                        print(DiagnosticFormatter.formatXcode(lintDiags))
                        print("\nLint: \(lintDiags.count) issues")
                    }
                    if diagnostics.isEmpty {
                        print("No issues found.")
                    }
                case .json:
                    try print(DiagnosticFormatter.formatJSON(diagnostics))
            }
        }

        if !diagnostics.isEmpty {
            throw ExitCode(1)
        }
    }

    // MARK: - Fix Mode

    private func runFix(analyzer: Analyzer, cfg: SwiftiomaticConfig) throws {
        let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)
        guard !files.isEmpty else {
            print("No Swift files found")
            return
        }

        var totalCorrections = 0

        // 1. Format engine writes formatted files (token-level fixes)
        let formatEngine = buildFormatEngine(config: cfg)
        for file in files {
            do {
                let source = try String(contentsOfFile: file, encoding: .utf8)
                let formatted = try formatEngine.format(source)
                if source != formatted {
                    try formatted.write(toFile: file, atomically: true, encoding: .utf8)
                    totalCorrections += 1
                }
            } catch {
                FileHandle.standardError.write(Data("Error formatting \(file): \(error)\n".utf8))
            }
        }

        // 2. Lint correctable rules run their correct() methods
        let storage = RuleStorage()
        let correctableRules = analyzer.lintRules.compactMap { $0 as? any CorrectableRule }
        let collectingRules = analyzer.lintRules.filter { $0 is any AnyCollectingRule }
        let lintFiles = files.compactMap { SwiftLintFile(path: $0) }

        // Collect phase for collecting rules
        for file in lintFiles {
            for rule in collectingRules {
                rule.collectInfo(
                    for: file, into: storage, compilerArguments: analyzer.compilerArguments,
                )
            }
        }

        // Correct phase
        for file in lintFiles {
            for rule in correctableRules {
                let corrections = rule.correct(
                    file: file, using: storage, compilerArguments: analyzer.compilerArguments,
                )
                totalCorrections += corrections
            }
        }

        print("Applied \(totalCorrections) corrections")
    }

    // MARK: - Format-Lint Integration

    private func runFormatLint(cfg: SwiftiomaticConfig) -> [Diagnostic] {
        let engine = buildFormatEngine(config: cfg)
        let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)
        var diagnostics: [Diagnostic] = []

        for file in files {
            do {
                let source = try String(contentsOfFile: file, encoding: .utf8)
                let changes = try engine.lint(source, filePath: file)
                diagnostics += changes.map { $0.toDiagnostic() }
            } catch {
                // Skip files that can't be parsed by the format engine
            }
        }

        return diagnostics
    }

    private func buildFormatEngine(config: SwiftiomaticConfig) -> FormatEngine {
        var options = FormatOptions.default
        options.indent = config.indent
        options.maxWidth = config.maxWidth
        if let version = Version(rawValue: config.swiftVersion) {
            options.swiftVersion = version
        }
        return FormatEngine(
            enable: config.enabledFormatRules,
            disable: config.disabledFormatRules,
            options: options,
        )
    }

    // MARK: - Config

    private func loadConfig() -> SwiftiomaticConfig {
        if let path = config {
            return (try? SwiftiomaticConfig.load(from: path)) ?? .default
        }
        let cwd = FileManager.default.currentDirectoryPath
        if let found = SwiftiomaticConfig.find(from: cwd) {
            return (try? SwiftiomaticConfig.load(from: found)) ?? .default
        }
        return .default
    }
}

// MARK: - List Rules

struct ListRules: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-rules",
        abstract: "List available rules across all engines",
        aliases: ["list-checks"],
    )

    @Option(name: .long, help: "Filter by engine: suggest, lint, or format")
    var engine: RuleEngine?

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    func run() {
        let entries: [RuleCatalog.Entry]
        if let engine {
            entries = RuleCatalog.rules(for: engine)
        } else {
            entries = RuleCatalog.allRules()
        }

        switch format {
            case .text:
                for entry in entries {
                    var flags: [String] = []
                    if entry.isDeprecated { flags.append("deprecated") }
                    if !entry.isEnabled { flags.append("disabled") }
                    if entry.canAutoFix { flags.append("autofix") }
                    if entry.isCrossFile { flags.append("cross-file") }
                    if entry.requiresSourceKit { flags.append("sourcekit") }
                    let suffix = flags.isEmpty ? "" : " (\(flags.joined(separator: ", ")))"
                    print("[\(entry.engine.rawValue)] \(entry.id) — \(entry.name)\(suffix)")
                }
                print("\nTotal: \(entries.count) rules")
            case .json:
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                if let data = try? encoder.encode(entries),
                   let json = String(data: data, encoding: .utf8)
                {
                    print(json)
                }
        }
    }
}

// MARK: - Types

enum OutputFormat: String, ExpressibleByArgument {
    case text
    case json
}

extension Confidence: ExpressibleByArgument {}
extension Severity: ExpressibleByArgument {}
extension RuleEngine: ExpressibleByArgument {}
