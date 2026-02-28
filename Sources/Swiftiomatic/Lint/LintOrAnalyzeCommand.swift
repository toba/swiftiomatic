@preconcurrency import Darwin
import Foundation
import Synchronization

// sm:disable file_length

enum LintOrAnalyzeMode {
    case lint, analyze

    var imperative: String {
        switch self {
            case .lint:
                return "lint"
            case .analyze:
                return "analyze"
        }
    }

    var verb: String {
        switch self {
            case .lint:
                return "linting"
            case .analyze:
                return "analyzing"
        }
    }
}

struct LintOrAnalyzeOptions {
    let mode: LintOrAnalyzeMode
    let paths: [String]
    let useSTDIN: Bool
    let configurationFiles: [String]
    let strict: Bool
    let lenient: Bool
    let forceExclude: Bool
    let useExcludingByPrefix: Bool
    let useScriptInputFiles: Bool
    let useScriptInputFileLists: Bool
    let benchmark: Bool
    let reporter: String?
    let baseline: String?
    let writeBaseline: String?
    let workingDirectory: String?
    let quiet: Bool
    let output: String?
    let progress: Bool
    let cachePath: String?
    let ignoreCache: Bool
    let enableAllRules: Bool
    let onlyRule: [String]
    let autocorrect: Bool
    let format: Bool
    let disableSourceKit: Bool
    let compilerLogPath: String?
    let compileCommands: String?
    let checkForUpdates: Bool

    var verb: String {
        autocorrect ? "correcting" : mode.verb
    }

    var capitalizedVerb: String {
        verb.capitalized
    }
}

enum LintOrAnalyzeCommand {
    static func run(_ options: LintOrAnalyzeOptions) async throws {
        Request.disableSourceKitOverride = options.mode == .lint && options.disableSourceKit
        if let workingDirectory = options.workingDirectory {
            if !FileManager.default.changeCurrentDirectoryPath(workingDirectory) {
                throw SwiftLintError.usageError(
                    description: """
                    Could not change working directory to '\(workingDirectory)'. \
                    Make sure it exists and is accessible.
                    """,
                )
            }
        }
        try await Signposts.record(name: "LintOrAnalyzeCommand.run") {
            try await options.autocorrect ? autocorrect(options) : lintOrAnalyze(options)
        }
    }

    private static func lintOrAnalyze(_ options: LintOrAnalyzeOptions) async throws {
        let builder = LintOrAnalyzeResultBuilder(options)
        let files = try await collectViolations(builder: builder)
        if let baselineOutputPath = options.writeBaseline ?? builder.configuration.writeBaseline {
            try Baseline(violations: builder.unfilteredViolations).write(toPath: baselineOutputPath)
        }
        let numberOfSeriousViolations = try Signposts.record(
            name: "LintOrAnalyzeCommand.PostProcessViolations",
        ) {
            try postProcessViolations(files: files, builder: builder)
        }
        if options.checkForUpdates || builder.configuration.checkForUpdates {
            await UpdateChecker.checkForUpdates()
        }
        if numberOfSeriousViolations > 0 {
            exit(2)
        }
    }

    private static func collectViolations(builder: LintOrAnalyzeResultBuilder) async throws
        -> [SwiftLintFile]
    {
        let options = builder.options
        let baseline = try baseline(options, builder.configuration)
        return try await builder.configuration.visitLintableFiles(
            options: options, cache: builder.cache,
            storage: builder.storage,
        ) { linter in
            let currentViolations: [StyleViolation]
            if options.benchmark {
                let start = Date()
                let (violationsBeforeLeniency, currentRuleTimes) =
                    linter
                        .styleViolationsAndRuleTimes(using: builder.storage)
                currentViolations = applyLeniency(
                    options: options,
                    strict: builder.configuration.strict,
                    lenient: builder.configuration.lenient,
                    violations: violationsBeforeLeniency,
                )
                builder.state.withLock { state in
                    state.fileBenchmark.record(file: linter.file, from: start)
                    currentRuleTimes.forEach { state.ruleBenchmark.record(id: $0, time: $1) }
                }
            } else {
                currentViolations = applyLeniency(
                    options: options,
                    strict: builder.configuration.strict,
                    lenient: builder.configuration.lenient,
                    violations: linter.styleViolations(using: builder.storage),
                )
            }
            let filteredViolations = baseline?.filter(currentViolations) ?? currentViolations
            builder.state.withLock { state in
                state.unfilteredViolations += currentViolations
                state.violations += filteredViolations
            }

            linter.file.invalidateCache()
            builder.report(violations: filteredViolations, realtimeCondition: true)
        }
    }

    private static func postProcessViolations(
        files: [SwiftLintFile],
        builder: LintOrAnalyzeResultBuilder,
    ) throws -> Int {
        let options = builder.options
        let configuration = builder.configuration
        let violations = builder.violations
        if isWarningThresholdBroken(configuration: configuration, violations: violations),
           !options.lenient
        {
            let threshold = createThresholdViolation(threshold: configuration.warningThreshold!)
            builder.state.withLock { $0.violations.append(threshold) }
            builder.report(violations: [threshold], realtimeCondition: true)
        }
        let allViolations = builder.violations
        builder.report(violations: allViolations, realtimeCondition: false)
        let numberOfSeriousViolations = allViolations.count(where: { $0.severity == .error })
        if !options.quiet {
            printStatus(
                violations: allViolations, files: files, serious: numberOfSeriousViolations,
                verb: options.verb,
            )
        }
        if options.benchmark {
            builder.state.withLock { state in
                state.fileBenchmark.save()
                state.ruleBenchmark.save()
            }
            if !options.quiet, let memoryUsage = memoryUsage() {
                queuedPrintError(memoryUsage)
            }
        }
        try builder.cache?.save()
        return numberOfSeriousViolations
    }

    private static func baseline(_ options: LintOrAnalyzeOptions, _ configuration: Configuration)
        throws -> Baseline?
    {
        if let baselinePath = options.baseline ?? configuration.baseline {
            do {
                return try Baseline(fromPath: baselinePath)
            } catch {
                Issue.baselineNotReadable(path: baselinePath).print()
                if (error as? CocoaError)?.code != CocoaError.fileReadNoSuchFile
                    || options.writeBaseline != options.baseline
                {
                    throw error
                }
            }
        }
        return nil
    }

    private static func printStatus(
        violations: [StyleViolation], files: [SwiftLintFile], serious: Int, verb: String,
    ) {
        let pluralSuffix = { (collection: [Any]) -> String in
            collection.count != 1 ? "s" : ""
        }
        queuedPrintError(
            "Done \(verb)! Found \(violations.count) violation\(pluralSuffix(violations)), "
                + "\(serious) serious in \(files.count) file\(pluralSuffix(files)).",
        )
    }

    private static func isWarningThresholdBroken(
        configuration: Configuration,
        violations: [StyleViolation],
    ) -> Bool {
        guard let warningThreshold = configuration.warningThreshold else { return false }
        let numberOfWarningViolations = violations.count(where: { $0.severity == .warning })
        return numberOfWarningViolations >= warningThreshold
    }

    private static func createThresholdViolation(threshold: Int) -> StyleViolation {
        let description = RuleDescription(
            identifier: "warning_threshold",
            name: "Warning Threshold",
            description: "Number of warnings thrown is above the threshold",
            kind: .lint,
        )
        return StyleViolation(
            ruleDescription: description,
            severity: .error,
            location: Location(file: "", line: 0, character: 0),
            reason: "Number of warnings exceeded threshold of \(threshold).",
        )
    }

    private static func applyLeniency(
        options: LintOrAnalyzeOptions,
        strict: Bool,
        lenient: Bool,
        violations: [StyleViolation],
    ) -> [StyleViolation] {
        let leniency = options.leniency(strict: strict, lenient: lenient)

        switch leniency {
            case (false, false):
                return violations

            case (false, true):
                return violations.map {
                    if $0.severity == .error {
                        return $0.with(severity: .warning)
                    }
                    return $0
                }

            case (true, false):
                return violations.map {
                    if $0.severity == .warning {
                        return $0.with(severity: .error)
                    }
                    return $0
                }

            case (true, true):
                queuedFatalError(
                    "Invalid command line or config options: 'strict' and 'lenient' are mutually exclusive.",
                )
        }
    }

    private static func autocorrect(_ options: LintOrAnalyzeOptions) async throws {
        let storage = RuleStorage()
        let configuration = Configuration(options: options)
        let correctionsBuilder = CorrectionsBuilder()
        let files =
            try await configuration
                .visitLintableFiles(options: options, cache: nil, storage: storage) { linter in
                    if options.format {
                        switch configuration.indentation {
                            case .tabs:
                                linter.format(useTabs: true, indentWidth: 4)
                            case let .spaces(count):
                                linter.format(useTabs: false, indentWidth: count)
                        }
                    }

                    let corrections = linter.correct(using: storage)
                    if !corrections.isEmpty, !options.quiet {
                        if options.useSTDIN {
                            queuedPrint(linter.file.contents)
                        } else {
                            let corrections = corrections.map {
                                Correction(
                                    ruleName: $0.0,
                                    filePath: linter.file.path,
                                    numberOfCorrections: $0.1,
                                )
                            }
                            if options.progress {
                                await correctionsBuilder.append(corrections)
                            } else {
                                let correctionLogs = corrections.map(\.consoleDescription)
                                queuedPrint(correctionLogs.joined(separator: "\n"))
                            }
                        }
                    }
                }

        if !options.quiet {
            if options.progress {
                let corrections = await correctionsBuilder.corrections
                if !corrections.isEmpty {
                    let correctionLogs = corrections.map(\.consoleDescription)
                    options.writeToOutput(correctionLogs.joined(separator: "\n"))
                }
            }

            let pluralSuffix = { (collection: [Any]) -> String in
                collection.count != 1 ? "s" : ""
            }
            queuedPrintError("Done correcting \(files.count) file\(pluralSuffix(files))!")
        }
    }
}

private final class LintOrAnalyzeResultBuilder {
    struct MutableState {
        var fileBenchmark = Benchmark(name: "files")
        var ruleBenchmark = Benchmark(name: "rules")
        /// All detected violations, unfiltered by the baseline, if any.
        var unfilteredViolations = [StyleViolation]()
        /// The violations to be reported, possibly filtered by a baseline, plus any threshold violations.
        var violations = [StyleViolation]()
    }

    let state = Mutex(MutableState())
    let storage = RuleStorage()
    let configuration: Configuration
    let cache: LinterCache?
    let options: LintOrAnalyzeOptions

    var unfilteredViolations: [StyleViolation] {
        get { state.withLock { $0.unfilteredViolations } }
    }

    var violations: [StyleViolation] {
        get { state.withLock { $0.violations } }
    }

    init(_ options: LintOrAnalyzeOptions) {
        let config = Signposts.record(name: "LintOrAnalyzeCommand.ParseConfiguration") {
            Configuration(options: options)
        }
        configuration = config
        if options.ignoreCache || ProcessInfo.processInfo.isLikelyXcodeCloudEnvironment {
            cache = nil
        } else {
            cache = LinterCache(configuration: config)
        }
        self.options = options

        if let outFile = options.output {
            do {
                try Data().write(to: URL(fileURLWithPath: outFile))
            } catch {
                Issue.fileNotWritable(path: outFile).print()
            }
        }
    }

    /// Report violations using Xcode-compatible format (file:line:char: severity: message).
    func report(violations: [StyleViolation], realtimeCondition: Bool) {
        // Xcode reporter is realtime — output violations as they're found
        if (!options.progress || options.output != nil) == realtimeCondition {
            let report = violations.map(\.description).joined(separator: "\n")
            if !report.isEmpty {
                options.writeToOutput(report)
            }
        }
    }
}

extension LintOrAnalyzeOptions {
    fileprivate func writeToOutput(_ string: String) {
        guard let outFile = output else {
            queuedPrint(string)
            return
        }

        do {
            let outFileURL = URL(fileURLWithPath: outFile)
            let fileUpdater = try FileHandle(forUpdating: outFileURL)
            fileUpdater.seekToEndOfFile()
            fileUpdater.write(Data((string + "\n").utf8))
            fileUpdater.closeFile()
        } catch {
            Issue.fileNotWritable(path: outFile).print()
        }
    }

    typealias Leniency = (strict: Bool, lenient: Bool)

    /// Config file settings can be overridden by either `--strict` or `--lenient` command line options.
    func leniency(strict configurationStrict: Bool,
                  lenient configurationLenient: Bool) -> Leniency
    {
        let strict = strict || (configurationStrict && !lenient)
        let lenient = lenient || (configurationLenient && !self.strict)
        return Leniency(strict: strict, lenient: lenient)
    }
}

private actor CorrectionsBuilder {
    private(set) var corrections: [Correction] = []

    func append(_ corrections: [Correction]) {
        self.corrections.append(contentsOf: corrections)
    }
}

private func memoryUsage() -> String? {
    var info = mach_task_basic_info()
    let basicInfoCount = MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
    var count = mach_msg_type_number_t(basicInfoCount)

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: basicInfoCount) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if kerr == KERN_SUCCESS {
        let bytes = Measurement<UnitInformationStorage>(
            value: Double(info.resident_size),
            unit: .bytes,
        )
        let formatted = ByteCountFormatter().string(from: bytes)
        return "Memory used: \(formatted)"
    }
    let errorMessage = String(cString: mach_error_string(kerr), encoding: .ascii)
    return "Error with task_info(): \(errorMessage ?? "unknown")"
}
