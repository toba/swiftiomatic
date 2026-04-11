import Foundation
import Swiftiomatic
import ArgumentParser

struct MigrateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "migrate",
        abstract: "Migrate SwiftLint/SwiftFormat configuration and inline comments to Swiftiomatic",
    )

    @Option(
        name: .long, parsing: .upToNextOption,
        help: "Paths to .swiftlint.yml or .swiftformat config files (auto-detected if omitted)",
    )
    var config: [String] = []

    @Option(name: [.customShort("o"), .long], help: "Output path for .swiftiomatic.yaml")
    var output: String = ".swiftiomatic.yaml"

    @Option(
        name: .long, parsing: .upToNextOption,
        help: "Paths to scan for inline comment migration (files or directories)",
    )
    var comments: [String] = []

    @Flag(name: .long, help: "Show what would change without modifying files")
    var dryRun = false

    @Option(name: .long, help: "Output format: text or json")
    var format: OutputFormat = .text

    func run() throws {
        var configFiles = config
        let hasExplicitConfig = !configFiles.isEmpty
        let hasCommentPaths = !comments.isEmpty

        // Auto-detect config files if none specified
        if !hasExplicitConfig {
            let fm = FileManager.default
            let cwd = fm.currentDirectoryPath

            for name in [".swiftlint.yml", ".swiftlint.yaml", ".swiftformat"] {
                let path = (cwd as NSString).appendingPathComponent(name)
                if fm.fileExists(atPath: path) {
                    configFiles.append(path)
                }
            }
        }

        if configFiles.isEmpty && !hasCommentPaths {
            printError(
                "No config files found and no --comments paths specified.\n"
                    + "Place a .swiftlint.yml or .swiftformat in the current directory, or use --config.",
            )
            throw ExitCode(1)
        }

        // Migrate config files
        var configResult: MigrationResult?

        if !configFiles.isEmpty {
            configResult = try migrateConfigs(configFiles)
        }

        // Migrate inline comments
        var commentResult: InlineCommentMigrationResult?

        if hasCommentPaths {
            commentResult = InlineCommentMigrator.migrate(paths: comments, dryRun: dryRun)
        }

        // Write config output
        if let result = configResult, !dryRun {
            try result.configuration.writeYAML(to: output)
        }

        // Report
        switch format {
            case .text:
                printTextReport(configResult: configResult, commentResult: commentResult)
            case .json:
                try printJSONReport(configResult: configResult, commentResult: commentResult)
            case .xcode:
                printTextReport(configResult: configResult, commentResult: commentResult)
        }
    }

    // MARK: - Config Migration

    private func migrateConfigs(_ paths: [String]) throws -> MigrationResult {
        var swiftlintResult: MigrationResult?
        var swiftformatResult: MigrationResult?

        for path in paths {
            let name = (path as NSString).lastPathComponent.lowercased()

            if name.hasPrefix(".swiftlint") {
                let parsed = try SwiftLintConfigParser.parse(at: path)
                swiftlintResult = ConfigMigrator.migrate(swiftlint: parsed)
                if !dryRun {
                    print("Parsed: \(path)")
                }
            } else if name == ".swiftformat" {
                let parsed = try SwiftFormatConfigParser.parse(at: path)
                swiftformatResult = ConfigMigrator.migrate(swiftformat: parsed)
                if !dryRun {
                    print("Parsed: \(path)")
                }
            } else {
                printError("Unknown config format: \(path)")
            }
        }

        // Merge if both exist
        if let sl = swiftlintResult, let sf = swiftformatResult {
            return ConfigMigrator.merge(swiftlint: sl, swiftformat: sf)
        }

        return swiftlintResult ?? swiftformatResult ?? MigrationResult(
            configuration: .default,
            warnings: [],
            mappedRuleCount: 0,
            unmappedRuleCount: 0,
        )
    }

    // MARK: - Reporting

    private func printTextReport(
        configResult: MigrationResult?,
        commentResult: InlineCommentMigrationResult?,
    ) {
        if let result = configResult {
            if dryRun {
                print("Config migration (dry run):")
            } else {
                print("\nWrote: \(output)")
            }
            print("  Rules mapped: \(result.mappedRuleCount)")
            if result.unmappedRuleCount > 0 {
                print("  Rules unmapped: \(result.unmappedRuleCount)")
            }

            for warning in result.warnings {
                print("  [\(warning.source)] \(warning.identifier): \(warning.message)")
            }
        }

        if let result = commentResult {
            print(
                dryRun
                    ? "\nInline comment migration (dry run):" : "\nInline comments migrated:",
            )
            print("  Files modified: \(result.filesModified)")
            print("  Comments changed: \(result.changes.count)")

            if dryRun {
                for change in result.changes {
                    print("  \(change.file):\(change.line)")
                    print("    - \(change.before)")
                    print("    + \(change.after)")
                }
            }

            for warning in result.warnings {
                print("  [\(warning.source)] \(warning.identifier): \(warning.message)")
            }
        }
    }

    private func printJSONReport(
        configResult: MigrationResult?,
        commentResult: InlineCommentMigrationResult?,
    ) throws {
        var report: [String: Any] = [:]

        if let result = configResult {
            report["config"] = [
                "output": dryRun ? nil : output,
                "mappedRules": result.mappedRuleCount,
                "unmappedRules": result.unmappedRuleCount,
                "warnings": result.warnings.map { [
                    "source": $0.source,
                    "identifier": $0.identifier,
                    "message": $0.message,
                ] },
            ] as [String: Any?]
        }

        if let result = commentResult {
            report["comments"] = [
                "filesModified": result.filesModified,
                "changesCount": result.changes.count,
                "changes": result.changes.map { [
                    "file": $0.file,
                    "line": $0.line,
                    "before": $0.before,
                    "after": $0.after,
                ] },
                "warnings": result.warnings.map { [
                    "source": $0.source,
                    "identifier": $0.identifier,
                    "message": $0.message,
                ] },
            ] as [String: Any]
        }

        let data = try JSONSerialization.data(
            withJSONObject: report,
            options: [.prettyPrinted, .sortedKeys],
        )
        if let json = String(data: data, encoding: .utf8) {
            print(json)
        }
    }

    private func printError(_ message: String) {
        var stderr = FileHandle.standardError
        print(message, to: &stderr)
    }
}
