import Foundation
import Yams

/// The configuration struct. User-defined in the `.swiftiomatic.yaml` file.
struct Configuration {
    // MARK: - Properties: Static

    /// The default Configuration resulting from an empty configuration file.
    static var `default`: Self {
        // This is realized via a getter to account for differences of the current working directory
        Self()
    }

    /// The default file name to look for user-defined configurations.
    static let defaultFileName = ".swiftiomatic.yaml"

    // MARK: Public Instance

    /// The paths that should be included when linting
    private(set) var includedPaths: [String]

    /// The paths that should be excluded when linting
    private(set) var excludedPaths: [String]

    /// The style to use when indenting Swift source code.
    let indentation: IndentationStyle

    /// The threshold for the number of warnings to tolerate before treating the lint as having failed.
    let warningThreshold: Int?

    /// The location of the persisted cache to use with this configuration.
    let cachePath: String?

    /// Allow or disallow SwiftLint to exit successfully when passed only ignored or unlintable files.
    let allowZeroLintableFiles: Bool

    /// Treat warnings as errors.
    let strict: Bool

    /// Treat errors as warnings.
    let lenient: Bool

    /// The path to read a baseline from.
    let baseline: String?

    /// The path to write a baseline to.
    let writeBaseline: String?

    /// Check for updates.
    let checkForUpdates: Bool

    // MARK: Unified Config (format / suggest / lint-override)

    /// Lint rules explicitly enabled (for opt-in rules).
    var enabledLintRules: [String] = []

    /// Lint rules explicitly disabled.
    var disabledLintRules: [String] = []

    /// Per-rule configuration overrides (keyed by rule identifier).
    nonisolated(unsafe) var lintRuleConfigs: [String: Any] = [:]

    /// Format rules explicitly enabled.
    var enabledFormatRules: [String] = []

    /// Format rules explicitly disabled.
    var disabledFormatRules: [String] = []

    /// Format indent string.
    var formatIndent: String = "    "

    /// Format max line width.
    var formatMaxWidth: Int = 120

    /// Format Swift version string.
    var formatSwiftVersion: String = "6.2"

    /// Minimum confidence level for suggest checks.
    var suggestMinConfidence: String = "low"

    // MARK: Public Computed

    /// All rules enabled in this configuration
    var rules: [any Rule] {
        rulesWrapper.resultingRules
    }

    /// The root directory is the directory that included & excluded paths relate to.
    /// By default, the root directory is the current working directory.
    var rootDirectory: String

    /// The rules mode used for this configuration.
    var rulesMode: RulesMode {
        rulesWrapper.mode
    }

    // MARK: Internal Instance

    private(set) var rulesWrapper: RulesWrapper

    // MARK: - Initializers: Internal

    /// Initialize with all properties
    init(
        rulesWrapper: RulesWrapper,
        rootDirectory: String,
        includedPaths: [String],
        excludedPaths: [String],
        indentation: IndentationStyle,
        warningThreshold: Int?,
        cachePath: String?,
        allowZeroLintableFiles: Bool,
        strict: Bool,
        lenient: Bool,
        baseline: String?,
        writeBaseline: String?,
        checkForUpdates: Bool,
    ) {
        self.rulesWrapper = rulesWrapper
        self.rootDirectory = rootDirectory
        self.includedPaths = includedPaths
        self.excludedPaths = excludedPaths
        self.indentation = indentation
        self.warningThreshold = warningThreshold
        self.cachePath = cachePath
        self.allowZeroLintableFiles = allowZeroLintableFiles
        self.strict = strict
        self.lenient = lenient
        self.baseline = baseline
        self.writeBaseline = writeBaseline
        self.checkForUpdates = checkForUpdates
    }

    /// Creates a Configuration by copying an existing configuration.
    ///
    /// - parameter copying:    The existing configuration to copy.
    init(copying configuration: Self) {
        rulesWrapper = configuration.rulesWrapper
        rootDirectory = configuration.rootDirectory
        includedPaths = configuration.includedPaths
        excludedPaths = configuration.excludedPaths
        indentation = configuration.indentation
        warningThreshold = configuration.warningThreshold
        cachePath = configuration.cachePath
        allowZeroLintableFiles = configuration.allowZeroLintableFiles
        strict = configuration.strict
        lenient = configuration.lenient
        baseline = configuration.baseline
        writeBaseline = configuration.writeBaseline
        checkForUpdates = configuration.checkForUpdates
        enabledLintRules = configuration.enabledLintRules
        disabledLintRules = configuration.disabledLintRules
        lintRuleConfigs = configuration.lintRuleConfigs
        enabledFormatRules = configuration.enabledFormatRules
        disabledFormatRules = configuration.disabledFormatRules
        formatIndent = configuration.formatIndent
        formatMaxWidth = configuration.formatMaxWidth
        formatSwiftVersion = configuration.formatSwiftVersion
        suggestMinConfidence = configuration.suggestMinConfidence
    }

    /// Creates a `Configuration` by specifying its properties directly,
    /// except that rules are still to be synthesized from rulesMode, ruleList & allRulesWrapped
    /// and a check against the pinnedVersion is performed if given.
    ///
    /// - parameter rulesMode:              The `RulesMode` for this configuration.
    /// - parameter allRulesWrapped:        The rules with their own configurations already applied.
    /// - parameter ruleList:               The list of all rules. Used for alias resolving and as a fallback
    ///                                     if `allRulesWrapped` is nil.
    /// - parameter rootDirectory:          The root directory for path resolution. Defaults to cwd.
    /// - parameter includedPaths:          Included paths to lint.
    /// - parameter excludedPaths:          Excluded paths to not lint.
    /// - parameter indentation:            The style to use when indenting Swift source code.
    /// - parameter warningThreshold:       The threshold for the number of warnings to tolerate before treating the
    ///                                     lint as having failed.
    /// - parameter cachePath:              The location of the persisted cache to use with this configuration.
    /// - parameter pinnedVersion:          The SwiftLint version defined in this configuration.
    /// - parameter allowZeroLintableFiles: Allow SwiftLint to exit successfully when passed ignored or unlintable
    ///                                     files.
    /// - parameter strict:                 Treat warnings as errors.
    /// - parameter lenient:                Treat errors as warnings.
    /// - parameter baseline:               The path to read a baseline from.
    /// - parameter writeBaseline:          The path to write a baseline to.
    /// - parameter checkForUpdates:        Check for updates to SwiftLint.
    init(
        rulesMode: RulesMode = .defaultConfiguration(disabled: [], optIn: []),
        allRulesWrapped: [ConfigurationRuleWrapper]? = nil,
        ruleList: RuleList = RuleRegistry.shared.list,
        rootDirectory: String? = nil,
        includedPaths: [String] = [],
        excludedPaths: [String] = [],
        indentation: IndentationStyle = .default,
        warningThreshold: Int? = nil,
        cachePath: String? = nil,
        pinnedVersion: String? = nil,
        allowZeroLintableFiles: Bool = false,
        strict: Bool = false,
        lenient: Bool = false,
        baseline: String? = nil,
        writeBaseline: String? = nil,
        checkForUpdates: Bool = false,
    ) {
        if let pinnedVersion, pinnedVersion != LintVersion.current.value {
            queuedPrintError(
                "warning: Currently running SwiftLint \(LintVersion.current.value) but "
                    + "configuration specified version \(pinnedVersion).",
            )
            exit(2)
        }

        self.init(
            rulesWrapper: RulesWrapper(
                mode: rulesMode,
                allRulesWrapped: allRulesWrapped ?? (try? ruleList.allRulesWrapped()) ?? [],
                aliasResolver: { ruleList.identifier(for: $0) ?? $0 },
            ),
            rootDirectory: rootDirectory
                ?? FileManager.default.currentDirectoryPath.bridge()
                    .absolutePathStandardized(),
            includedPaths: includedPaths,
            excludedPaths: excludedPaths,
            indentation: indentation,
            warningThreshold: warningThreshold,
            cachePath: cachePath,
            allowZeroLintableFiles: allowZeroLintableFiles,
            strict: strict,
            lenient: lenient,
            baseline: baseline,
            writeBaseline: writeBaseline,
            checkForUpdates: checkForUpdates,
        )
    }

    // MARK: Public

    /// Creates a `Configuration` with convenience parameters.
    ///
    /// - parameter configurationFiles:         The path on disk to one or multiple configuration files. If this array
    ///                                         is empty, the default `.swiftiomatic.yaml` file will be used.
    /// - parameter enableAllRules:             Enable all available rules.
    /// - parameter cachePath:                  The location of the persisted cache to use whith this configuration.
    /// - parameter useDefaultConfigOnFailure:  If this value is specified, it will override the normal behavior.
    ///                                         This is only intended for tests checking whether invalid configs fail.
    init(
        configurationFiles: [String], // No default value here to avoid ambiguous Configuration() initializer
        enableAllRules: Bool = false,
        onlyRule: [String] = [],
        cachePath: String? = nil,
        useDefaultConfigOnFailure: Bool? =
            nil, // sm:disable:this discouraged_optional_boolean
    ) {
        // Use default config file name if none specified
        let hasCustomConfigurationFiles: Bool = configurationFiles.isNotEmpty
        let configurationFiles =
            configurationFiles.isEmpty ? [Self.defaultFileName] : configurationFiles

        let currentWorkingDirectory = FileManager.default.currentDirectoryPath.bridge()
            .absolutePathStandardized()
        let rulesMode: RulesMode =
            if enableAllRules {
                .allCommandLine
            } else if onlyRule.isNotEmpty {
                .onlyCommandLine(Set(onlyRule))
            } else {
                .defaultConfiguration(disabled: [], optIn: [])
            }

        // Try building configuration from config files
        do {
            let resultingConfiguration = try Self.resultingConfiguration(
                configFiles: configurationFiles,
                rootDirectory: currentWorkingDirectory,
                enableAllRules: enableAllRules,
                onlyRule: onlyRule,
                cachePath: cachePath,
            )

            self.init(copying: resultingConfiguration)
        } catch {
            if case Issue.initialFileNotFound = error, !hasCustomConfigurationFiles {
                // The initial configuration file wasn't found, but the user didn't explicitly specify one
                // Don't handle as error. Instead, silently fall back to default.
                self.init(rulesMode: rulesMode, cachePath: cachePath)
                return
            }
            if useDefaultConfigOnFailure ?? !hasCustomConfigurationFiles {
                // No files were explicitly specified, so maybe the user doesn't want a config at all -> warn
                queuedPrintError(
                    "\(Issue.wrap(error: error).localizedDescription) – Falling back to default configuration",
                )
                self.init(rulesMode: rulesMode, cachePath: cachePath)
            } else {
                // Files that were explicitly specified could not be loaded -> fail
                queuedPrintError(Issue.wrap(error: error).asError.localizedDescription)
                queuedFatalError("Could not read configuration")
            }
        }
    }

    // MARK: - Unified Config Loading

    /// Find config file by walking up from the given directory.
    static func findConfig(from directory: String) -> String? {
        let fm = FileManager.default
        var url = URL(filePath: directory, directoryHint: .isDirectory)
        while true {
            let candidate = url.appending(path: defaultFileName)
                .path(percentEncoded: false)
            if fm.fileExists(atPath: candidate) {
                return candidate
            }
            let parent = url.deletingLastPathComponent()
            if parent.path(percentEncoded: false) == url.path(percentEncoded: false) { break }
            url = parent
        }
        return nil
    }

    /// Load a unified configuration from a `.swiftiomatic.yaml` file.
    /// Parses format, suggest, and lint-override sections.
    static func loadUnified(from path: String) throws -> Configuration {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard
            let yaml = try Yams
                .load(yaml: String(data: data, encoding: .utf8) ?? "") as? [String: Any]
        else {
            return .default
        }

        var config = Configuration()

        // Rules section (lint rule overrides)
        if let rules = yaml["rules"] as? [String: Any] {
            if let enabled = rules["enabled"] as? [String] {
                config.enabledLintRules = enabled
            }
            if let disabled = rules["disabled"] as? [String] {
                config.disabledLintRules = disabled
            }
            if let ruleConfig = rules["config"] as? [String: Any] {
                config.lintRuleConfigs = ruleConfig
            }
        }

        // Suggest section
        if let suggest = yaml["suggest"] as? [String: Any] {
            if let confidence = suggest["min_confidence"] as? String {
                config.suggestMinConfidence = confidence
            }
        }

        // Format section
        if let format = yaml["format"] as? [String: Any] {
            if let rules = format["rules"] as? [String: Any] {
                if let enable = rules["enable"] as? [String] {
                    config.enabledFormatRules = enable
                }
                if let disable = rules["disable"] as? [String] {
                    config.disabledFormatRules = disable
                }
            }

            if let options = format["options"] as? [String: Any] {
                if let indent = options["indent"] as? String {
                    config.formatIndent = indent
                }
                if let maxWidth = options["maxwidth"] as? Int {
                    config.formatMaxWidth = maxWidth
                }
                if let version = options["swiftversion"] as? String {
                    config.formatSwiftVersion = version
                }
            }
        }

        // Legacy: top-level "exclude" adds to disabled rules list
        if let exclude = yaml["exclude"] as? [String] {
            config.disabledLintRules += exclude
        }

        return config
    }

    /// Load unified configuration, searching from the given config path or by walking up from cwd.
    static func loadUnified(configPath: String? = nil) -> Configuration {
        if let path = configPath {
            return (try? loadUnified(from: path)) ?? .default
        }
        let cwd = FileManager.default.currentDirectoryPath
        if let found = findConfig(from: cwd) {
            return (try? loadUnified(from: found)) ?? .default
        }
        return .default
    }

    // MARK: - Methods: Merging

    /// Merges this configuration with a child configuration, producing a new configuration
    /// whose rules combine both parent and child rule settings.
    func merged(withChild child: Configuration, rootDirectory: String) -> Configuration {
        Configuration(
            rulesWrapper: rulesWrapper.merged(with: child.rulesWrapper),
            rootDirectory: rootDirectory,
            includedPaths: child.includedPaths.isEmpty ? includedPaths : child.includedPaths,
            excludedPaths: child.excludedPaths.isEmpty ? excludedPaths : child.excludedPaths,
            indentation: child.indentation,
            warningThreshold: child.warningThreshold ?? warningThreshold,
            cachePath: child.cachePath ?? cachePath,
            allowZeroLintableFiles: child.allowZeroLintableFiles,
            strict: child.strict,
            lenient: child.lenient,
            baseline: child.baseline ?? baseline,
            writeBaseline: child.writeBaseline ?? writeBaseline,
            checkForUpdates: child.checkForUpdates,
        )
    }

    // MARK: - Methods: Private Static

    /// Parses the given config file paths and returns the resulting configuration.
    /// When multiple files are provided, later files override earlier ones (no merging).
    private static func resultingConfiguration(
        configFiles: [String],
        rootDirectory: String,
        enableAllRules: Bool,
        onlyRule: [String],
        cachePath: String?,
    ) throws -> Configuration {
        let configData: [(configurationDict: [String: Any], rootDirectory: String)] =
            try configFiles.map { filePath in
                let absolutePath = filePath
                    .absolutePathRepresentation(rootDirectory: rootDirectory)

                guard !absolutePath.isEmpty,
                      FileManager.default.fileExists(atPath: absolutePath)
                else {
                    let isInitial = configFiles.first == filePath
                    throw isInitial
                        ? Issue.initialFileNotFound(path: absolutePath)
                        : Issue.fileNotFound(path: absolutePath)
                }

                let contents = try String(contentsOfFile: absolutePath, encoding: .utf8)
                let dict = try YamlParser.parse(contents)

                let fileRoot = absolutePath.bridge().deletingLastPathComponent
                return (configurationDict: dict, rootDirectory: fileRoot)
            }

        // Use the last config file (later files win)
        let data = configData.last ?? (configurationDict: [:], rootDirectory: "")

        var configuration = try Configuration(
            dict: data.configurationDict,
            enableAllRules: enableAllRules,
            onlyRule: onlyRule,
            cachePath: cachePath,
        )
        configuration.rootDirectory = rootDirectory
        configuration.makeIncludedAndExcludedPaths(
            relativeTo: rootDirectory,
            previousBasePath: data.rootDirectory,
        )

        return configuration
    }

    // MARK: - Methods: Internal

    mutating func makeIncludedAndExcludedPaths(
        relativeTo newBasePath: String, previousBasePath: String,
    ) {
        includedPaths = includedPaths.map {
            $0.absolutePathRepresentation(rootDirectory: previousBasePath).path(
                relativeTo: newBasePath,
            )
        }

        excludedPaths = excludedPaths.map {
            $0.absolutePathRepresentation(rootDirectory: previousBasePath).path(
                relativeTo: newBasePath,
            )
        }
    }
}

// MARK: - Sendable

extension Configuration: @unchecked Sendable {}

// MARK: - Hashable

extension Configuration: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(includedPaths)
        hasher.combine(excludedPaths)
        hasher.combine(indentation)
        hasher.combine(warningThreshold)
        hasher.combine(allowZeroLintableFiles)
        hasher.combine(strict)
        hasher.combine(lenient)
        hasher.combine(baseline)
        hasher.combine(writeBaseline)
        hasher.combine(checkForUpdates)
        hasher.combine(cachePath)
        hasher.combine(rules.map { type(of: $0).identifier })
        hasher.combine(rootDirectory)
    }

    static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.includedPaths == rhs.includedPaths && lhs.excludedPaths == rhs.excludedPaths
            && lhs.indentation == rhs.indentation && lhs.warningThreshold == rhs.warningThreshold
            && lhs.cachePath == rhs.cachePath && lhs.rules == rhs.rules
            && lhs.rootDirectory == rhs.rootDirectory
            && lhs.allowZeroLintableFiles == rhs.allowZeroLintableFiles && lhs.strict == rhs.strict
            && lhs.lenient == rhs.lenient && lhs.baseline == rhs.baseline
            && lhs.writeBaseline == rhs.writeBaseline && lhs.checkForUpdates == rhs.checkForUpdates
            && lhs.rulesMode == rhs.rulesMode
    }
}

// MARK: - CustomStringConvertible

extension Configuration: CustomStringConvertible {
    var description: String {
        "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included Paths: \(includedPaths)\n"
            + "- Excluded Paths: \(excludedPaths)\n"
            + "- Warning Threshold: \(warningThreshold as Optional)\n"
            + "- Root Directory: \(rootDirectory as Optional)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).identifier })"
    }
}
