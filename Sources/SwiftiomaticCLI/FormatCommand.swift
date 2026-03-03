import Foundation
import Swiftiomatic
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

    @Option(name: .long, parsing: .upToNextOption, help: "Exclusion patterns")
    var exclude: [String] = []

    @Flag(name: .long, help: "Lint mode: report issues as diagnostics without modifying files")
    var lint = false

    @Option(name: .long, help: "Output format for lint mode: text or json")
    var format: OutputFormat = .text

    func run() throws {
        let cfg = loadConfig()
        let engine = cfg.makeFormatEngine()
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

        // 1. swift-format pretty-printer
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

        // 2. Correctable lint rules
        let lintCorrections = applyCorrectableLintRules(cfg: cfg, files: files, checkOnly: check)
        if lintCorrections > 0 {
            hasChanges = true
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
                let findings = try engine.lint(source, filePath: file)
                allDiagnostics.append(contentsOf: findings.map { $0.toDiagnostic() })
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
            case .xcode:
                if !sorted.isEmpty {
                    print(DiagnosticFormatter.formatXcode(sorted))
                }
        }

        if !sorted.isEmpty {
            throw ExitCode(1)
        }
    }

    // MARK: - Correctable Lint Rules

    /// Load correctable lint rules and apply (or check) corrections on the given files.
    /// Returns the total number of corrections applied (or detected in check mode).
    private func applyCorrectableLintRules(cfg: Configuration, files: [String], checkOnly: Bool) -> Int {
        let allRules = RuleResolver.loadRules(
            enabled: cfg.enabledLintRules.isEmpty ? nil : Set(cfg.enabledLintRules),
            disabled: Set(cfg.disabledLintRules),
            ruleConfigs: cfg.lintRuleConfigs,
        )
        let correctableRules = allRules.compactMap { $0 as? any CorrectableRule }
        guard !correctableRules.isEmpty else { return 0 }

        let collectingRules = allRules.filter { $0 is any CollectingRuleMarker }
        let lintFiles = files.compactMap { SwiftSource(path: $0) }

        let storage = RuleStorage()

        // Collect phase for collecting rules
        for file in lintFiles {
            for rule in collectingRules {
                rule.collectInfo(for: file, into: storage, compilerArguments: [])
            }
        }

        // Correct phase
        var totalCorrections = 0
        for (path, file) in zip(files, lintFiles) {
            let original = checkOnly ? (try? String(contentsOfFile: path, encoding: .utf8)) : nil
            var fileCorrections = 0

            for rule in correctableRules {
                fileCorrections += rule.correct(file: file, using: storage, compilerArguments: [])
            }

            if fileCorrections > 0 {
                totalCorrections += fileCorrections
                if checkOnly {
                    // Restore original contents — check mode should not modify files
                    try? original?.write(toFile: path, atomically: true, encoding: .utf8)
                    print("\(path): needs lint corrections")
                } else {
                    print("\(path): lint corrections applied")
                }
            }
        }

        return totalCorrections
    }

    // MARK: - Helpers

    private func loadConfig() -> Configuration {
        Configuration.loadUnified(configPath: config)
    }

    private func printError(_ message: String) {
        var stderr = FileHandle.standardError
        print(message, to: &stderr)
    }
}
