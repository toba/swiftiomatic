import Foundation
import ArgumentParser

struct Lint: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Lint Swift source files using SwiftLint rules",
    )

    @Argument(help: "Paths to lint (files or directories)")
    var paths: [String] = []

    @Option(name: .long, parsing: .upToNextOption, help: "Configuration files (.swiftlint.yml)")
    var config: [String] = []

    @Option(
        name: .long,
        help:
        "Reporter: xcode, json, csv, checkstyle, codeclimate, emoji, github-actions-logging, gitlabJUnit, html, junit, markdown, relative-path, sonarqube, summary",
    )
    var reporter: String?

    @Flag(name: .long, help: "Treat warnings as errors")
    var strict = false

    @Flag(name: .long, help: "Treat errors as warnings")
    var lenient = false

    @Flag(name: .long, help: "Suppress output except for violations")
    var quiet = false

    @Flag(name: .long, help: "Autocorrect violations where possible")
    var fix = false

    @Flag(name: .long, help: "Enable all rules including opt-in")
    var enableAllRules = false

    @Option(name: .long, parsing: .upToNextOption, help: "Only run the specified rules")
    var onlyRule: [String] = []

    @Flag(name: .long, help: "Disable SourceKit-based rules")
    var noSourcekit = false

    @Flag(name: .long, help: "Ignore cache")
    var noCache = false

    @Option(name: .long, help: "Write output to file")
    var output: String?

    mutating func run() async throws {
        RuleRegistry.registerAllRulesOnce()

        let effectivePaths = paths.isEmpty ? ["."] : paths

        let options = LintOrAnalyzeOptions(
            mode: .lint,
            paths: effectivePaths,
            useSTDIN: false,
            configurationFiles: config,
            strict: strict,
            lenient: lenient,
            forceExclude: false,
            useExcludingByPrefix: false,
            useScriptInputFiles: false,
            useScriptInputFileLists: false,
            benchmark: false,
            reporter: reporter,
            baseline: nil,
            writeBaseline: nil,
            workingDirectory: nil,
            quiet: quiet,
            output: output,
            progress: false,
            cachePath: nil,
            ignoreCache: noCache,
            enableAllRules: enableAllRules,
            onlyRule: onlyRule,
            autocorrect: fix,
            format: false,
            disableSourceKit: noSourcekit,
            compilerLogPath: nil,
            compileCommands: nil,
            checkForUpdates: false,
        )

        try await LintOrAnalyzeCommand.run(options)
    }
}
