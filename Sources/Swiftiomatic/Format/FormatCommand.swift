import Foundation
import ArgumentParser

struct FormatCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "format",
        abstract: "Format Swift source files",
    )

    @Argument(help: "Paths to format (files or directories)")
    var paths: [String] = ["."]

    @Flag(name: .long, help: "Check formatting without modifying files (exit 1 if changes needed)")
    var check = false

    @Option(name: .long, help: "Path to .swiftiomatic.yaml config file")
    var config: String?

    @Option(name: .long, parsing: .upToNextOption, help: "Enable specific rules")
    var enable: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Disable specific rules")
    var disable: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Exclusion patterns")
    var exclude: [String] = []

    @Flag(name: .long, help: "Lint mode: report issues as diagnostics without modifying files")
    var lint = false

    @Option(name: .long, help: "Output format for lint mode: text or json")
    var format: OutputFormat = .text

    @Flag(name: .long, help: "List all available formatting rules")
    var listRules = false

    func run() throws {
        if listRules {
            printRules()
            return
        }

        let cfg = loadConfig()
        let engine = buildEngine(config: cfg)
        let files = FileDiscovery.findSwiftFiles(in: paths, additionalExclusions: exclude)

        if files.isEmpty {
            print("No Swift files found")
            return
        }

        if lint {
            try runLintMode(engine: engine, files: files)
            return
        }

        var hasChanges = false
        var errorCount = 0

        for file in files {
            do {
                let source = try String(contentsOfFile: file, encoding: .utf8)
                let formatted = try engine.format(source)

                if source != formatted {
                    hasChanges = true
                    if check {
                        print("\(file): needs formatting")
                    } else {
                        try formatted.write(toFile: file, atomically: true, encoding: .utf8)
                        print("\(file): formatted")
                    }
                }
            } catch {
                errorCount += 1
                printError("Error formatting \(file): \(error)")
            }
        }

        if errorCount > 0 {
            throw ExitCode(2)
        }

        if check, hasChanges {
            throw ExitCode(1)
        }
    }

    private func runLintMode(engine: FormatEngine, files: [String]) throws {
        var allDiagnostics: [Diagnostic] = []

        for file in files {
            do {
                let source = try String(contentsOfFile: file, encoding: .utf8)
                let changes = try engine.lint(source, filePath: file)
                allDiagnostics.append(contentsOf: changes.map { $0.toDiagnostic() })
            } catch {
                printError("Error linting \(file): \(error)")
            }
        }

        let sorted = allDiagnostics.sorted()
        switch format {
            case .text:
                if sorted.isEmpty {
                    print("No formatting issues found.")
                } else {
                    print(DiagnosticFormatter.formatXcode(sorted))
                    print("\nTotal: \(sorted.count) issues")
                }
            case .json:
                try print(DiagnosticFormatter.formatJSON(sorted))
        }

        if !sorted.isEmpty {
            throw ExitCode(1)
        }
    }

    // MARK: - Helpers

    private func printRules() {
        let defaultRuleNames = Set(FormatRules.default.map(\.name))
        for rule in FormatRules.all {
            let status =
                if rule.isDeprecated {
                    " (deprecated)"
                } else if defaultRuleNames.contains(rule.name) {
                    ""
                } else {
                    " (disabled)"
                }
            print("\(rule.name)\(status)")
        }
    }

    private func loadConfig() -> Configuration {
        Configuration.loadUnified(configPath: config)
    }

    private func buildEngine(config: Configuration) -> FormatEngine {
        let allEnabled = config.enabledFormatRules + enable
        let allDisabled = config.disabledFormatRules + disable

        var options = FormatOptions.default
        options.indent = config.formatIndent
        options.maxWidth = config.formatMaxWidth
        if let version = Version(rawValue: config.formatSwiftVersion) {
            options.swiftVersion = version
        }

        return FormatEngine(enable: allEnabled, disable: allDisabled, options: options)
    }

    private func printError(_ message: String) {
        var stderr = FileHandle.standardError
        print(message, to: &stderr)
    }
}
