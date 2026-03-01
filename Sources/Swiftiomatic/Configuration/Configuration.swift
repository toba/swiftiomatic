import Yams
import Foundation

/// The configuration struct. User-defined in the `.swiftiomatic.yaml` file.
package struct Configuration {
    // MARK: - Properties: Static

    /// The default Configuration resulting from an empty configuration file.
    package static var `default`: Self {
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

    /// The location of the persisted cache to use with this configuration.
    let cachePath: String?

    // MARK: Unified Config (format / suggest / lint-override)

    /// Lint rules explicitly enabled (for opt-in rules).
    package var enabledLintRules: [String] = []

    /// Lint rules explicitly disabled.
    package var disabledLintRules: [String] = []

    /// Per-rule configuration overrides (keyed by rule identifier).
    package var lintRuleConfigs: [String: ConfigValue] = [:]

    /// Format rules explicitly enabled.
    package var enabledFormatRules: [String] = []

    /// Format rules explicitly disabled.
    package var disabledFormatRules: [String] = []

    /// Format indent string.
    package var formatIndent: String = "    "

    /// Format max line width.
    package var formatMaxWidth: Int = 120

    /// Format Swift version string.
    package var formatSwiftVersion: String = "6.2"

    /// Minimum confidence level for suggest checks.
    var suggestMinConfidence: String = "low"

    // MARK: Public Computed

    /// All rules enabled in this configuration
    var rules: [any Rule] {
        ruleSelection.resultingRules
    }

    /// The root directory is the directory that included & excluded paths relate to.
    /// By default, the root directory is the current working directory.
    var rootDirectory: String

    /// The rules mode used for this configuration.
    var rulesMode: RulesMode {
        ruleSelection.mode
    }

    // MARK: Internal Instance

    private(set) var ruleSelection: RuleSelection

    // MARK: - Initializers: Internal

    /// Initialize with all properties
    init(
        ruleSelection: RuleSelection,
        rootDirectory: String,
        includedPaths: [String],
        excludedPaths: [String],
        indentation: IndentationStyle,
        cachePath: String?,
    ) {
        self.ruleSelection = ruleSelection
        self.rootDirectory = rootDirectory
        self.includedPaths = includedPaths
        self.excludedPaths = excludedPaths
        self.indentation = indentation
        self.cachePath = cachePath
    }

    /// Creates a Configuration by copying an existing configuration.
    ///
    /// - parameter copying:    The existing configuration to copy.
    init(copying configuration: Self) {
        self = configuration
    }

    /// Creates a `Configuration` by specifying its properties directly,
    /// except that rules are still to be synthesized from rulesMode, ruleList & allRulesWrapped.
    ///
    /// - parameter rulesMode:              The `RulesMode` for this configuration.
    /// - parameter allRulesWrapped:        The rules with their own configurations already applied.
    /// - parameter ruleList:               The list of all rules. Used for alias resolving and as a fallback
    ///                                     if `allRulesWrapped` is nil.
    /// - parameter rootDirectory:          The root directory for path resolution. Defaults to cwd.
    /// - parameter includedPaths:          Included paths to lint.
    /// - parameter excludedPaths:          Excluded paths to not lint.
    /// - parameter indentation:            The style to use when indenting Swift source code.
    /// - parameter cachePath:              The location of the persisted cache to use with this configuration.
    init(
        rulesMode: RulesMode = .defaultConfiguration(disabled: [], optIn: []),
        allRulesWrapped: [ConfiguredRule]? = nil,
        ruleList: RuleList = RuleRegistry.shared.list,
        rootDirectory: String? = nil,
        includedPaths: [String] = [],
        excludedPaths: [String] = [],
        indentation: IndentationStyle = .default,
        cachePath: String? = nil,
    ) {
        self.init(
            ruleSelection: RuleSelection(
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
            cachePath: cachePath,
        )
    }

    // MARK: Public

    /// Creates a `Configuration` from a single configuration file.
    ///
    /// - parameter configurationFile:          The path on disk to a configuration file. If empty,
    ///                                         the default `.swiftiomatic.yaml` will be used.
    /// - parameter enableAllRules:             Enable all available rules.
    /// - parameter cachePath:                  The location of the persisted cache to use with this configuration.
    /// - parameter useDefaultConfigOnFailure:  If this value is specified, it will override the normal behavior.
    ///                                         This is only intended for tests checking whether invalid configs fail.
    init(
        configurationFile: String = "",
        enableAllRules: Bool = false,
        onlyRule: [String] = [],
        cachePath: String? = nil,
        useDefaultConfigOnFailure: Bool? =
            nil, // sm:disable:this discouraged_optional_boolean
    ) {
        let hasCustomConfigurationFile = configurationFile.isNotEmpty
        let filePath = hasCustomConfigurationFile ? configurationFile : Self.defaultFileName

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

        do {
            let absolutePath = filePath.absolutePathRepresentation(
                rootDirectory: currentWorkingDirectory,
            )

            guard !absolutePath.isEmpty,
                  FileManager.default.fileExists(atPath: absolutePath)
            else {
                throw Issue.initialFileNotFound(path: absolutePath)
            }

            let contents = try String(contentsOfFile: absolutePath, encoding: .utf8)
            let dict = try YamlParser.parse(contents)

            var configuration = try Configuration(
                dict: dict,
                enableAllRules: enableAllRules,
                onlyRule: onlyRule,
                cachePath: cachePath,
            )
            configuration.rootDirectory = currentWorkingDirectory
            self.init(copying: configuration)
        } catch {
            if case Issue.initialFileNotFound = error, !hasCustomConfigurationFile {
                self.init(rulesMode: rulesMode, cachePath: cachePath)
                return
            }
            if useDefaultConfigOnFailure ?? !hasCustomConfigurationFile {
                queuedPrintError(
                    "\(Issue.wrap(error: error).localizedDescription) – Falling back to default configuration",
                )
                self.init(rulesMode: rulesMode, cachePath: cachePath)
            } else {
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

    /// Loads a YAML file at the given path and returns the top-level dictionary.
    private static func loadYAML(from path: String) throws -> [String: Any] {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard
            let yaml = try Yams
            .load(yaml: String(data: data, encoding: .utf8) ?? "") as? [String: Any]
        else {
            return [:]
        }
        return yaml
    }

    /// Load a unified configuration from a `.swiftiomatic.yaml` file.
    /// Parses format, suggest, and lint-override sections.
    package static func loadUnified(from path: String) throws -> Configuration {
        let yaml = try loadYAML(from: path)
        guard !yaml.isEmpty else { return .default }

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
                config.lintRuleConfigs = ruleConfig.compactMapValues(ConfigValue.init)
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
    package static func loadUnified(configPath: String? = nil) -> Configuration {
        if let path = configPath {
            return (try? loadUnified(from: path)) ?? .default
        }
        let cwd = FileManager.default.currentDirectoryPath
        if let found = findConfig(from: cwd) {
            return (try? loadUnified(from: found)) ?? .default
        }
        return .default
    }
}

// MARK: - Sendable

extension Configuration: Sendable {}

// MARK: - Hashable

extension Configuration: Hashable {
    package func hash(into hasher: inout Hasher) {
        hasher.combine(includedPaths)
        hasher.combine(excludedPaths)
        hasher.combine(indentation)
        hasher.combine(cachePath)
        hasher.combine(rules.map { type(of: $0).identifier })
        hasher.combine(rootDirectory)
    }

    package static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.includedPaths == rhs.includedPaths && lhs.excludedPaths == rhs.excludedPaths
            && lhs.indentation == rhs.indentation
            && lhs.cachePath == rhs.cachePath && lhs.rules == rhs.rules
            && lhs.rootDirectory == rhs.rootDirectory
            && lhs.rulesMode == rhs.rulesMode
    }
}

// MARK: - CustomStringConvertible

extension Configuration: CustomStringConvertible {
    package var description: String {
        "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included Paths: \(includedPaths)\n"
            + "- Excluded Paths: \(excludedPaths)\n"
            + "- Root Directory: \(rootDirectory as Optional)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).identifier })"
    }
}
