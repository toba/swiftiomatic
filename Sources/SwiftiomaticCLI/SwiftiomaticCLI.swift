import Foundation
public import ArgumentParser
import Swiftiomatic

@main
struct SwiftiomaticCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AST-based Swift code analysis and formatting",
        version: "0.2.0",
        subcommands: [
            Analyze.self, FormatCommand.self, ListRules.self, GenerateDocs.self,
            MigrateCommand.self,
        ],
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

    @Option(name: .long, parsing: .upToNextOption, help: "Additional exclusion patterns")
    var exclude: [String] = []

    @Option(name: .long, help: "Minimum confidence: high, medium, or low")
    var minConfidence: Confidence = .low

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

    mutating func run() async throws {
        // Must register rules before any Configuration access (which uses RuleRegistry.shared.list
        // as a default parameter and would cache an empty list).
        RuleRegistry.registerAllRulesOnce()

        let configResolver = ConfigurationResolver(configPath: config)
        // Load a base config for top-level rule/analyzer setup
        let cfg = Configuration.loadUnified(configPath: config)

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

        // Load lint rules from base config (CLI overrides apply globally)
        let mergedDisabled = Set(disableRule + cfg.disabledLintRules)
        let mergedEnabled: Set<String>? = enableRule.isEmpty && cfg.enabledLintRules.isEmpty
            ? nil
            : Set(enableRule + cfg.enabledLintRules)
        let lintRules = RuleResolver.loadRules(
            enabled: mergedEnabled,
            disabled: mergedDisabled,
            onlyRules: Set(onlyRule),
            ruleConfigs: cfg.lintRuleConfigs,
        )

        let analyzer = Analyzer(
            minConfidence: minConfidence,
            typeResolver: resolver,
            lintRules: lintRules,
            compilerArguments: compilerArgs,
        )

        // Fix mode
        if fix {
            try runFix(analyzer: analyzer, configResolver: configResolver)
            return
        }

        // Analysis
        var diagnostics = await analyzer.analyze(paths: paths)

        // Optionally merge format-lint diagnostics
        if includeFormat {
            diagnostics += runFormatLint(configResolver: configResolver)
            diagnostics.sort()
        }

        // Apply dedup — remove lint rules superseded by format rules when format is active
        if includeFormat {
            diagnostics = DiagnosticDeduplicator.deduplicate(diagnostics)
        }

        // Output
        if quiet {
            let grouped = Dictionary(grouping: diagnostics) { $0.source }
            for source in DiagnosticSource.allCases {
                if let items = grouped[source], !items.isEmpty {
                    print("\(source.rawValue): \(items.count)")
                }
            }
            print("Total: \(diagnostics.count)")
        } else {
            switch format {
                case .text:
                    print(TextFormatter.format(diagnostics))
                case .json:
                    try print(DiagnosticFormatter.formatJSON(diagnostics))
                case .xcode:
                    print(DiagnosticFormatter.formatXcode(diagnostics))
            }
        }

        if !diagnostics.isEmpty {
            throw ExitCode(1)
        }
    }

    // MARK: - Fix Mode

    private func runFix(analyzer: Analyzer, configResolver: ConfigurationResolver) throws {
        let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)
        guard !files.isEmpty else {
            print("No Swift files found")
            return
        }

        var totalCorrections = 0

        // 1. Format engine writes formatted files (per-directory config)
        // Group files by resolved config directory for efficient engine reuse
        let grouped = Dictionary(grouping: files) { file in
            configResolver.configuration(for: file)
        }

        for (fileCfg, groupFiles) in grouped {
            let formatEngine = fileCfg.makeFormatEngine()
            for file in groupFiles {
                do {
                    let source = try String(contentsOfFile: file, encoding: .utf8)
                    let formatted = try formatEngine.format(source)
                    if source != formatted {
                        try formatted.write(toFile: file, atomically: true, encoding: .utf8)
                        totalCorrections += 1
                    }
                } catch {
                    FileHandle.standardError.write(
                        Data("Error formatting \(file): \(error)\n".utf8),
                    )
                }
            }
        }

        // 2. Lint correctable rules run their correct() methods
        let storage = RuleStorage()
        let correctableRules = analyzer.lintRules.filter { type(of: $0).isCorrectable }
        let collectingRules = analyzer.lintRules.filter { type(of: $0).isCrossFile }
        let lintFiles = files.compactMap { SwiftSource(path: $0) }

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

    private func runFormatLint(configResolver: ConfigurationResolver) -> [Diagnostic] {
        let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)
        var diagnostics: [Diagnostic] = []

        for file in files {
            do {
                let fileCfg = configResolver.configuration(for: file)
                let engine = fileCfg.makeFormatEngine()
                let source = try String(contentsOfFile: file, encoding: .utf8)
                let findings = try engine.lint(source, filePath: file)
                diagnostics += findings.map { $0.toDiagnostic() }
            } catch {
                // Skip files that can't be parsed by the format engine
            }
        }

        return diagnostics
    }
}

// MARK: - List Rules

struct ListRules: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-rules",
        abstract: "List available rules across all engines",
        aliases: ["list-checks"],
    )

    @Option(name: .long, help: "Filter by source: suggest, lint, or format")
    var source: DiagnosticSource?

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    func run() {
        var entries = RuleCatalog.allEntries()
        if let source {
            let scope: Scope = switch source {
                case .lint: .lint
                case .format: .format
                case .suggest: .suggest
            }
            entries = entries.filter { $0.scope == scope }
        }

        switch format {
            case .text:
                for entry in entries {
                    var flags: [String] = []
                    if entry.isDeprecated { flags.append("deprecated") }
                    if entry.isOptIn { flags.append("opt-in") }
                    if entry.isCorrectable { flags.append("autofix") }
                    if entry.isCrossFile { flags.append("cross-file") }
                    if entry.requiresSourceKit { flags.append("sourcekit") }
                    let suffix = flags.isEmpty ? "" : " (\(flags.joined(separator: ", ")))"
                    print("[\(entry.scope.rawValue)] \(entry.id) — \(entry.name)\(suffix)")
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
            case .xcode:
                for entry in entries {
                    print("[\(entry.scope.rawValue)] \(entry.id) — \(entry.name)")
                }
        }
    }
}

// MARK: - Generate Docs

struct GenerateDocs: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate-docs",
        abstract: "Generate rule documentation as Markdown files",
    )

    @Argument(help: "Output directory for generated documentation")
    var outputDir: String

    func run() throws {
        RuleRegistry.registerAllRulesOnce()
        let url = URL(filePath: outputDir)
        try RuleRegistry.shared.generateDocs(to: url)

        let count = RuleRegistry.shared.ruleCount
        print("Generated documentation for \(count) rules in \(outputDir)/")
    }
}

// MARK: - Types

enum OutputFormat: String, ExpressibleByArgument {
    case text
    case json
    case xcode
}

extension Confidence: ExpressibleByArgument {}
extension DiagnosticSource: ExpressibleByArgument {}
