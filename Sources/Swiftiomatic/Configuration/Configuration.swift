import Yams
import Foundation

/// The configuration struct, user-defined in the `.swiftiomatic.yaml` file
public struct Configuration {
    // MARK: - Properties: Static

    /// The default ``Configuration`` resulting from an empty configuration file
    public static var `default`: Self {
        // This is realized via a getter to account for differences of the current working directory
        Self()
    }

    /// The default file name to look for user-defined configurations
    static let defaultFileName = ".swiftiomatic.yaml"

    // MARK: Public Instance

    /// The paths that should be included when linting
    private(set) var includedPaths: [String]

    /// The paths that should be excluded when linting
    private(set) var excludedPaths: [String]

    /// The style to use when indenting Swift source code
    let indentation: IndentationStyle

    /// The location of the persisted cache to use with this configuration
    let cachePath: String?

    // MARK: Unified Config (format / suggest / lint-override)

    /// Lint rules explicitly enabled (for opt-in rules)
    public var enabledLintRules: [String] = []

    /// Lint rules explicitly disabled
    public var disabledLintRules: [String] = []

    /// Per-rule configuration overrides keyed by rule identifier
    public var lintRuleConfigs: [String: ConfigValue] = [:]

    /// Format rules explicitly enabled
    public var enabledFormatRules: [String] = []

    /// Format rules explicitly disabled
    public var disabledFormatRules: [String] = []

    /// Format indent string
    public var formatIndent: String = "    "

    /// Format max line width
    public var formatMaxWidth: Int = 120

    /// Format Swift version
    package var formatSwiftVersion: Version = "6.2"

    /// Minimum confidence level for suggest checks
    public var suggestMinConfidence: Confidence = .low

    // MARK: Public Computed

    /// All rules enabled in this configuration, derived from the ``RuleSelection``
    var rules: [any Rule] {
        ruleSelection.resultingRules
    }

    /// The root directory that included and excluded paths relate to, defaults to the current working directory
    var rootDirectory: String

    /// The ``RulesMode`` used for this configuration
    var rulesMode: RulesMode {
        ruleSelection.mode
    }

    // MARK: Internal Instance

    private(set) var ruleSelection: RuleSelection

    // MARK: - Initializers: Internal

    /// Create a ``Configuration`` with all properties specified directly
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

    /// Create a ``Configuration`` by copying an existing configuration
    ///
    /// - Parameters:
    ///   - configuration: The existing configuration to copy.
    init(copying configuration: Self) {
        self = configuration
    }

    /// Create a ``Configuration`` where rules are synthesized from mode, list, and wrapped rules
    ///
    /// - Parameters:
    ///   - rulesMode: The ``RulesMode`` for this configuration.
    ///   - allRulesWrapped: The rules with their own configurations already applied.
    ///   - ruleList: The list of all rules, used for alias resolving and as a fallback
    ///     if `allRulesWrapped` is `nil`.
    ///   - rootDirectory: The root directory for path resolution, defaults to cwd.
    ///   - includedPaths: Included paths to lint.
    ///   - excludedPaths: Excluded paths to not lint.
    ///   - indentation: The style to use when indenting Swift source code.
    ///   - cachePath: The location of the persisted cache to use with this configuration.
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

    /// Create a ``Configuration`` from a single configuration file
    ///
    /// - Parameters:
    ///   - configurationFile: The path on disk to a configuration file. If empty,
    ///     the default `.swiftiomatic.yaml` will be used.
    ///   - enableAllRules: Enable all available rules.
    ///   - onlyRule: Rules to restrict the run to.
    ///   - cachePath: The location of the persisted cache to use with this configuration.
    ///   - useDefaultConfigOnFailure: If specified, overrides the normal behavior.
    ///     Only intended for tests checking whether invalid configs fail.
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
                throw SwiftiomaticError.initialFileNotFound(path: absolutePath)
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
            if case SwiftiomaticError.initialFileNotFound = error, !hasCustomConfigurationFile {
                self.init(rulesMode: rulesMode, cachePath: cachePath)
                return
            }
            if useDefaultConfigOnFailure ?? !hasCustomConfigurationFile {
                Console.printError(
                    "\(SwiftiomaticError.wrap(error: error).localizedDescription) – Falling back to default configuration",
                )
                self.init(rulesMode: rulesMode, cachePath: cachePath)
            } else {
                Console.printError(SwiftiomaticError.wrap(error: error).asError.localizedDescription)
                Console.fatalError("Could not read configuration")
            }
        }
    }

    // MARK: - Unified Config Loading

    /// Find config file by walking up from the given directory
    ///
    /// - Parameters:
    ///   - directory: The starting directory to search from.
    /// - Returns: The path to the first `.swiftiomatic.yaml` found, or `nil`.
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

    /// Load a YAML file at the given path and return the top-level dictionary
    ///
    /// Returns `[String: Any]` because YAML is inherently untyped -- values are cast to
    /// concrete types in ``loadUnified(from:)``.
    ///
    /// - Parameters:
    ///   - path: The file system path to the YAML file.
    /// - Returns: The parsed top-level dictionary.
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

    /// Load a unified configuration from a `.swiftiomatic.yaml` file
    ///
    /// Parses format, suggest, and lint-override sections.
    ///
    /// - Parameters:
    ///   - path: The file system path to the YAML configuration file.
    /// - Returns: The parsed ``Configuration``.
    public static func loadUnified(from path: String) throws -> Configuration {
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
            if let confidence = suggest["min_confidence"] as? String,
               let level = Confidence(rawValue: confidence) {
                config.suggestMinConfidence = level
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
                if let version = options["swiftversion"] as? String,
                   let parsed = Version(rawValue: version) {
                    config.formatSwiftVersion = parsed
                }
            }
        }

        // Legacy: top-level "exclude" adds to disabled rules list
        if let exclude = yaml["exclude"] as? [String] {
            config.disabledLintRules += exclude
        }

        return config
    }

    /// Load unified configuration, searching from the given config path or by walking up from cwd
    ///
    /// - Parameters:
    ///   - configPath: An explicit path to the config file, or `nil` to search from the current working directory.
    /// - Returns: The loaded ``Configuration``, falling back to ``default`` on failure.
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

// MARK: - FormatEngine Factory

extension Configuration {
    /// Create a ``FormatEngine`` configured from this configuration's format settings
    ///
    /// - Parameters:
    ///   - additionalEnable: Extra format rule names to enable beyond the configuration.
    ///   - additionalDisable: Extra format rule names to disable beyond the configuration.
    /// - Returns: A configured ``FormatEngine``.
    package func makeFormatEngine(
        additionalEnable: [String] = [],
        additionalDisable: [String] = []
    ) -> FormatEngine {
        var options = FormatOptions.default
        options.indent = formatIndent
        options.maxWidth = formatMaxWidth
        options.swiftVersion = formatSwiftVersion
        return FormatEngine(
            enable: enabledFormatRules + additionalEnable,
            disable: disabledFormatRules + additionalDisable,
            options: options,
        )
    }
}

// MARK: - YAML Write-Back

extension Configuration {
    /// Serialize non-default values back to YAML, writing only sections that differ from defaults
    ///
    /// - Parameters:
    ///   - path: The file system path to write the YAML file to.
    public func writeYAML(to path: String) throws {
        var yaml: [String: Any] = [:]

        // Rules section
        var rules: [String: Any] = [:]
        if !enabledLintRules.isEmpty { rules["enabled"] = enabledLintRules }
        if !disabledLintRules.isEmpty { rules["disabled"] = disabledLintRules }
        if !lintRuleConfigs.isEmpty {
            rules["config"] = lintRuleConfigs.mapValues(\.asAny)
        }
        if !rules.isEmpty { yaml["rules"] = rules }

        // Format section
        var format: [String: Any] = [:]
        var formatRules: [String: Any] = [:]
        if !enabledFormatRules.isEmpty { formatRules["enable"] = enabledFormatRules }
        if !disabledFormatRules.isEmpty { formatRules["disable"] = disabledFormatRules }
        if !formatRules.isEmpty { format["rules"] = formatRules }

        var formatOptions: [String: Any] = [:]
        let defaults = Configuration.default
        if formatIndent != defaults.formatIndent { formatOptions["indent"] = formatIndent }
        if formatMaxWidth != defaults.formatMaxWidth { formatOptions["maxwidth"] = formatMaxWidth }
        if !formatOptions.isEmpty { format["options"] = formatOptions }
        if !format.isEmpty { yaml["format"] = format }

        // Suggest section
        if suggestMinConfidence != defaults.suggestMinConfidence {
            yaml["suggest"] = ["min_confidence": suggestMinConfidence.rawValue]
        }

        let yamlString: String
        if yaml.isEmpty {
            yamlString = "# Swiftiomatic configuration\n# See https://github.com/toba/swiftiomatic for documentation\n"
        } else {
            yamlString = try Yams.dump(object: yaml, allowUnicode: true, sortKeys: true)
        }
        try yamlString.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

// MARK: - Sendable

extension Configuration: Sendable {}

// MARK: - Hashable

extension Configuration: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(includedPaths)
        hasher.combine(excludedPaths)
        hasher.combine(indentation)
        hasher.combine(cachePath)
        hasher.combine(rules.map { type(of: $0).identifier })
        hasher.combine(rootDirectory)
    }

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        lhs.includedPaths == rhs.includedPaths && lhs.excludedPaths == rhs.excludedPaths
            && lhs.indentation == rhs.indentation
            && lhs.cachePath == rhs.cachePath && lhs.rules == rhs.rules
            && lhs.rootDirectory == rhs.rootDirectory
            && lhs.rulesMode == rhs.rulesMode
    }
}

// MARK: - CustomStringConvertible

extension Configuration: CustomStringConvertible {
    public var description: String {
        "Configuration: \n"
            + "- Indentation Style: \(indentation)\n"
            + "- Included Paths: \(includedPaths)\n"
            + "- Excluded Paths: \(excludedPaths)\n"
            + "- Root Directory: \(rootDirectory as Optional)\n"
            + "- Cache Path: \(cachePath as Optional)\n"
            + "- Rules: \(rules.map { type(of: $0).identifier })"
    }
}
