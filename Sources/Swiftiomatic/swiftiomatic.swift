import ArgumentParser
import Format
import Foundation
import SourceKitService
import Suggest

@main
struct Swiftiomatic: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "AST-based Swift code analysis and formatting",
        version: "0.1.0",
        subcommands: [Scan.self, FormatCommand.self, Lint.self, ListChecks.self],
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

    @Option(name: .long, parsing: .upToNextOption, help: "Explicit compiler arguments (with --sourcekit)")
    var compilerArgs: [String] = []

    mutating func run() async throws {
        let categories: Set<Suggest.Category> = if category.isEmpty {
            []
        } else {
            Set(
                category.compactMap { name in
                    Suggest.Category.allCases.first { $0.rawValue == name }
                },
            )
        }

        // Create SourceKit resolver if requested
        var resolver: (any TypeResolver)?
        if sourcekit {
            if !compilerArgs.isEmpty {
                resolver = SourceKittenResolver(compilerArgs: compilerArgs)
            } else {
                let root = projectRoot ?? "."
                if let spmResolver = SourceKittenResolver(projectRoot: root) {
                    resolver = spmResolver
                } else {
                    FileHandle.standardError.write(
                        Data("warning: --sourcekit: failed to discover compiler args from '\(root)'; falling back to syntax-only analysis\n"
                            .utf8),
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
                try print(JSONFormatter.format(findings))
            }
        }

        if !findings.isEmpty {
            throw ExitCode(1)
        }
    }
}

// MARK: - List Checks

struct ListChecks: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-checks",
        abstract: "List available analysis categories",
    )

    func run() {
        for category in Category.allCases {
            print("§\(category.sectionNumber) \(category.rawValue) — \(category.displayName)")
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
