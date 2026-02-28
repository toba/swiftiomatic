import ArgumentParser
import Foundation

struct FormatCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "format",
        abstract: "Format Swift source files"
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

    @Flag(name: .long, help: "List all available formatting rules")
    var listRules = false

    func run() throws {
        if listRules {
            printRules()
            return
        }

        let cfg = try loadConfig()
        let engine = buildEngine(config: cfg)
        let files = collectSwiftFiles(paths: paths, exclude: exclude)

        if files.isEmpty {
            print("No Swift files found")
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

    private func loadConfig() throws -> SwiftiomaticConfig {
        if let path = config {
            return try SwiftiomaticConfig.load(from: path)
        }
        let cwd = FileManager.default.currentDirectoryPath
        if let found = SwiftiomaticConfig.find(from: cwd) {
            return try SwiftiomaticConfig.load(from: found)
        }
        return .default
    }

    private func buildEngine(config: SwiftiomaticConfig) -> FormatEngine {
        let allEnabled = config.enabledRules + enable
        let allDisabled = config.disabledRules + disable

        var options = FormatOptions.default
        options.indent = config.indent
        options.maxWidth = config.maxWidth
        if let version = Version(rawValue: config.swiftVersion) {
            options.swiftVersion = version
        }

        return FormatEngine(enable: allEnabled, disable: allDisabled, options: options)
    }

    private func collectSwiftFiles(paths: [String], exclude: [String]) -> [String] {
        let fm = FileManager.default
        var files: [String] = []
        let excludeSet = Set(exclude)

        for path in paths {
            var isDir: ObjCBool = false
            let fullPath = (path as NSString).standardizingPath

            guard fm.fileExists(atPath: fullPath, isDirectory: &isDir) else {
                printError("Path not found: \(path)")
                continue
            }

            if isDir.boolValue {
                guard let enumerator = fm.enumerator(atPath: fullPath) else { continue }
                while let relativePath = enumerator.nextObject() as? String {
                    if shouldExclude(relativePath, patterns: excludeSet) {
                        enumerator.skipDescendants()
                        continue
                    }
                    if relativePath.hasSuffix(".swift") {
                        files.append((fullPath as NSString).appendingPathComponent(relativePath))
                    }
                }
            } else if fullPath.hasSuffix(".swift") {
                files.append(fullPath)
            }
        }

        return files.sorted()
    }

    private func shouldExclude(_ path: String, patterns: Set<String>) -> Bool {
        for pattern in patterns {
            if path.contains(pattern) { return true }
        }
        // Skip hidden directories and build artifacts
        let components = path.components(separatedBy: "/")
        for component in components {
            if component.hasPrefix(".") || component == "Build" || component == ".build" {
                return true
            }
        }
        return false
    }

    private func printError(_ message: String) {
        var stderr = FileHandle.standardError
        print(message, to: &stderr)
    }
}

extension FileHandle: @retroactive TextOutputStream {
    func write(_ string: String) {
        let data = Data(string.utf8)
        write(data)
    }
}
