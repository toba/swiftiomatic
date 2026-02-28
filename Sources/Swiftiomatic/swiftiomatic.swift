import Foundation
import ArgumentParser

@main
struct SwiftiomaticCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AST-based Swift code analysis and formatting",
        version: "0.1.0",
        subcommands: [Scan.self, FormatCommand.self, Lint.self, ListRules.self],
        defaultSubcommand: Scan.self,
    )
}

// MARK: - Scan

struct Scan: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run analysis checks on Swift source files",
    )

    @Argument(help: "Paths to scan (files or directories)")
    var paths: [String] = ["."]

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    @Option(name: .long, parsing: .upToNextOption, help: "Limit to specific categories")
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

    mutating func run() async throws {
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

        let analyzer = Analyzer(
            categories: categories,
            minConfidence: minConfidence,
            minSeverity: minSeverity,
            typeResolver: resolver,
        )

        let findings = await analyzer.analyze(paths: paths)

        if quiet {
            let grouped = Dictionary(grouping: findings) { $0.category }
            for cat in Category.allCases {
                let count = grouped[cat]?.count ?? 0
                if count > 0 {
                    print("§\(cat.sectionNumber) \(cat.displayName): \(count)")
                }
            }
            print("Total: \(findings.count)")
        } else {
            switch format {
                case .text:
                    print(TextFormatter.format(findings))
                case .json:
                    let diagnostics = findings.map { $0.toDiagnostic() }
                    try print(DiagnosticFormatter.formatJSON(diagnostics))
            }
        }

        if !findings.isEmpty {
            throw ExitCode(1)
        }
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
