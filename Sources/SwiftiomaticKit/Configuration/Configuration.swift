import Foundation
@_exported import ConfigurationKit

/// Holds the complete set of configured values and defaults.
package struct Configuration: Sendable, Equatable {
    package static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        guard lhs.version == rhs.version else { return false }
        for entry in settingEntries where !entry.isEqual(lhs, rhs) { return false }
        for entry in ruleEntries where !entry.isEqual(lhs, rhs) { return false }
        return true
    }

    /// Type-erased store for layout settings and rule values.
    private var values: [String: any Sendable] = [:]

    /// Version of the configuration format.
    private var version: Int = highestSupportedConfigurationVersion

    // MARK: - Typed access

    /// Look up any `Configurable` value by type, falling back to its default.
    ///
    /// A type mismatch in the underlying storage is a programmer error — typically a
    /// duplicate key registered for two different `Configurable` types. The getter
    /// traps with a diagnostic instead of silently returning the default, which
    /// would hide the bug.
    package subscript<C: Configurable>(_: C.Type = C.self) -> C.Value {
        get {
            let key = C.group.map { "\($0.key).\(C.key)" } ?? C.key
            guard let stored = values[key] else { return C.defaultValue }
            guard let typed = stored as? C.Value else {
                preconditionFailure(
                    "Configuration key '\(key)' has stored type \(type(of: stored)), "
                        + "expected \(C.Value.self). This indicates a duplicate Configurable "
                        + "registration with conflicting Value types.")
            }
            return typed
        }
        set {
            let key = C.group.map { "\($0.key).\(C.key)" } ?? C.key
            values[key] = newValue
        }
    }

    /// Returns whether the given rule is active, using existential dispatch on the
    /// runtime metatype.
    ///
    /// This is the dynamic-type-correct counterpart to `configuration[R.self].isActive`.
    /// The generic subscript binds `C` from the static call-site type — when called
    /// from inside a generic base class (e.g. `StructuralFormatRule.visitAny`), `C` is
    /// the static base type and `C.key`/`C.defaultValue` lookups resolve against the
    /// base class's witness, NOT the dynamic subclass. That returns the wrong rule key
    /// (`"rewriteSyntaxRule<BasicRuleValue>"`) and a default of `(rewrite: true, lint:
    /// .warn)`, which causes disabled rules to fire.
    ///
    /// This helper avoids that footgun by going through `any SyntaxRule.Type`, whose
    /// member access dispatches on the runtime metatype.
    func isActive(rule: any SyntaxRule.Type) -> Bool {
        let qualified = rule.group.map { "\($0.key).\(rule.key)" } ?? rule.key
        if let stored = values[qualified] as? any SyntaxRuleValue {
            return stored.isActive
        }
        return rule.defaultIsActive
    }

    // MARK: - Layout setting registry

    private typealias SettingDecoder =
        @Sendable (
            KeyedDecodingContainer<AnyCodingKey>, AnyCodingKey, inout Configuration
        ) throws -> Void

    private typealias SettingEncoder =
        @Sendable (
            Configuration, inout KeyedEncodingContainer<AnyCodingKey>, AnyCodingKey
        ) throws -> Void

    private struct SettingEntry: Sendable {
        let key: String
        let groupKey: ConfigurationGroup.Key?
        let decode: SettingDecoder
        let encode: SettingEncoder
        let isEqual: @Sendable (Configuration, Configuration) -> Bool
    }

    /// Builds the shared decode/encode/equality closures for any `Configurable` type.
    /// Used by both `SettingEntry` and `RuleEntry` factories.
    private static func codingClosures<C: Configurable>(
        for _: C.Type
    ) -> (
        decode: @Sendable (KeyedDecodingContainer<AnyCodingKey>, AnyCodingKey, inout Configuration)
            throws -> Void,
        encode: @Sendable (Configuration, inout KeyedEncodingContainer<AnyCodingKey>, AnyCodingKey)
            throws -> Void,
        isEqual: @Sendable (Configuration, Configuration) -> Bool
    ) {
        (
            decode: { container, codingKey, config in
                if let value = try container.decodeIfPresent(C.Value.self, forKey: codingKey) {
                    config[C.self] = value
                }
            },
            encode: { config, container, codingKey in
                try container.encode(config[C.self], forKey: codingKey)
            },
            isEqual: { lhs, rhs in lhs[C.self] == rhs[C.self] }
        )
    }

    private static func entry(for type: any LayoutRule.Type) -> SettingEntry {
        func open<D: LayoutRule>(_: D.Type) -> SettingEntry {
            let codecs = codingClosures(for: D.self)
            return SettingEntry(
                key: D.key,
                groupKey: D.group?.key,
                decode: codecs.decode,
                encode: codecs.encode,
                isEqual: codecs.isEqual
            )
        }
        return open(type)
    }

    private static let settingEntries: [SettingEntry] = LayoutRegistry.all.map { entry(for: $0) }

    private static let settingsByKey: [String: SettingEntry] = Dictionary(
        uniqueKeysWithValues: settingEntries.map { ($0.key, $0) })

    private static let settingKeyNames: Set<String> = {
        // Only include setting keys that don't collide with group names,
        // so group keys still fall through to the group decoder.
        var names = Set(settingEntries.map(\.key)).subtracting(groupKeyNames)
        names.insert("version")
        return names
    }()

    // MARK: - Rule value registry

    private struct RuleEntry: Sendable {
        /// Short key used for JSON encoding within a group (or at root if ungrouped).
        let key: String
        /// Qualified key (`group.key` or bare `key`) for unique internal lookup.
        let qualifiedKey: String
        let groupKey: ConfigurationGroup.Key?
        let decode:
            @Sendable (KeyedDecodingContainer<AnyCodingKey>, AnyCodingKey, inout Configuration)
                throws -> Void
        let encode:
            @Sendable (Configuration, inout KeyedEncodingContainer<AnyCodingKey>, AnyCodingKey)
                throws -> Void
        let disable: @Sendable (inout Configuration) -> Void
        let enable: @Sendable (inout Configuration) -> Void
        let isEqual: @Sendable (Configuration, Configuration) -> Bool
    }

    private static func ruleEntry(for type: any SyntaxRule.Type) -> RuleEntry {
        func open<R: SyntaxRule>(_: R.Type) -> RuleEntry {
            let codecs = codingClosures(for: R.self)
            return RuleEntry(
                key: R.key,
                qualifiedKey: R.qualifiedKey,
                groupKey: R.group?.key,
                decode: codecs.decode,
                encode: codecs.encode,
                disable: { config in
                    var value = config[R.self]
                    value.rewrite = false
                    value.lint = .no
                    config[R.self] = value
                },
                enable: { config in
                    var value = config[R.self]
                    value.rewrite = true
                    value.lint = .warn
                    config[R.self] = value
                },
                isEqual: codecs.isEqual
            )
        }
        return open(type)
    }

    private static let ruleEntries:
        [RuleEntry] = ConfigurationRegistry.allRuleTypes.map { ruleEntry(for: $0) }

    private static let rulesByKey: [String: RuleEntry] = Dictionary(
        uniqueKeysWithValues: ruleEntries.map { ($0.qualifiedKey, $0) })

    // MARK: - Rule key metadata (for `sm update`)

    /// All valid rule qualified keys (`group.key` or bare `key`).
    package static var allRuleQualifiedKeys: Set<String> { Set(ruleEntries.map(\.qualifiedKey)) }

    /// Maps each rule's short key to its canonical qualified key.
    /// If two rules share a short key (different groups), one is chosen arbitrarily.
    package static var qualifiedKeyByShortKey: [String: String] {
        var map: [String: String] = [:]
        for entry in ruleEntries { map[entry.key] = entry.qualifiedKey }
        return map
    }

    /// All keys that are settings or meta fields (not rules or groups),
    /// regardless of whether they're currently grouped or ungrouped.
    package static var allSettingAndMetaKeys: Set<String> {
        var keys = Set(settingEntries.map(\.key))
        keys.insert("version")
        keys.insert("$schema")
        return keys
    }

    /// All configuration group key names.
    package static var groupKeyNames: Set<String> {
        Set(ConfigurationGroup.Key.allCases.map(\.rawValue))
    }

    /// Setting keys that live inside a given group (not rules).
    package static func settingKeys(inGroup group: ConfigurationGroup.Key) -> Set<String> {
        Set(settingEntries.filter { $0.groupKey == group }.map(\.key))
    }

    // MARK: - Rule helpers

    /// Disables all syntax rules by setting `enabled = false` on each rule's value.
    package mutating func disableAllRules() {
        for entry in Self.ruleEntries { entry.disable(&self) }
    }

    /// Enables a rule by qualified key (`group.key`) or short key (`key`).
    package mutating func enableRule(named name: String) {
        if let entry = Self.rulesByKey[name] {
            entry.enable(&self)
        } else if let entry = Self.ruleEntries.first(where: { $0.key == name }) {
            entry.enable(&self)
        }
    }

    // MARK: - Init

    package init() {}

    package init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(data: data)
    }

    package init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        self = try decoder.decode(Configuration.self, from: data)
    }

    /// Returns the URL of the configuration file that applies to the given file or directory.
    package static func url(forConfigurationFileApplyingTo url: URL) -> URL? {
        var candidateDirectory = url.absoluteURL.standardized
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(
            atPath: candidateDirectory.path,
            isDirectory: &isDirectory
        ),
           isDirectory.boolValue
        {
            candidateDirectory.appendPathComponent("placeholder")
        }
        repeat {
            candidateDirectory.deleteLastPathComponent()
            let candidateFile = candidateDirectory.appendingPathComponent("swiftiomatic.json")

            if FileManager.default.isReadableFile(atPath: candidateFile.path) {
                return candidateFile
            }
        } while !candidateDirectory.isRoot
        return nil
    }
}

/// A version number that can be specified in the configuration file, which allows us to change the
/// format in the future if desired and still support older files.
private let highestSupportedConfigurationVersion = 7

extension Configuration {
    /// The URL of the JSON schema hosted on GitHub. Embedded as `$schema` by `encode(to:)`.
    package static let schemaURL =
        "https://raw.githubusercontent.com/toba/swiftiomatic/refs/heads/main/schema.json"
}

extension String {
    /// Splits a qualified configuration key like `"group.name"` into `(group, name)` parts.
    /// Returns `(nil, self)` when no group prefix is present.
    package var qualifiedKeyParts: (group: String?, name: String) {
        let parts = split(separator: ".", maxSplits: 1).map(String.init)
        if parts.count == 2 { return (parts[0], parts[1]) }
        return (nil, self)
    }
}

// MARK: - Codable

extension Configuration: Codable {
    package init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: AnyCodingKey.self)

        // Decode version.
        let version = try root.decodeIfPresent(Int.self, forKey: AnyCodingKey("version"))
            ?? highestSupportedConfigurationVersion
        guard version <= highestSupportedConfigurationVersion else {
            throw SwiftiomaticError.unsupportedConfigurationVersion(
                version,
                highestSupported: highestSupportedConfigurationVersion
            )
        }

        var config = Configuration()
        config.version = version

        // Decode root-level layout settings (including grouped settings placed at root).
        // Skip any setting whose key collides with a group name (e.g. "blankLines").
        for entry in Self.settingEntries where !Self.groupKeyNames.contains(entry.key) {
            let codingKey = AnyCodingKey(entry.key)
            guard root.contains(codingKey) else { continue }
            try entry.decode(root, codingKey, &config)
        }

        // Walk remaining keys for groups and rules.
        for key in root.allKeys {
            let name = key.stringValue

            // Skip known root-level settings and version.
            guard !Self.settingKeyNames.contains(name) else { continue }

            // Config group: decode grouped settings + rules.
            if let groupKey = ConfigurationGroup.Key(rawValue: name) {
                let groupContainer = try root.nestedContainer(
                    keyedBy: AnyCodingKey.self, forKey: key)

                // Decode group-owned settings.
                for entry in Self.settingEntries where entry.groupKey == groupKey {
                    let codingKey = AnyCodingKey(entry.key)
                    guard groupContainer.contains(codingKey) else { continue }
                    try entry.decode(groupContainer, codingKey, &config)
                }

                // Decode rules within the group.
                if let mappings = ConfigurationRegistry.groupRules[ConfigurationGroup(groupKey)] {
                    for rule in mappings {
                        let ruleKey = AnyCodingKey(rule)
                        guard groupContainer.contains(ruleKey) else { continue }
                        let qualifiedKey = "\(groupKey.rawValue).\(rule)"

                        if let entry = Self.rulesByKey[qualifiedKey] {
                            try entry.decode(groupContainer, ruleKey, &config)
                        }
                    }
                }
                continue
            }

            // Rule value: decode via the rule's entry.
            if let entry = Self.rulesByKey[name] {
                try entry.decode(root, key, &config)
                continue
            }
        }

        self = config
    }

    package func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: AnyCodingKey.self)
        try root.encode(Self.schemaURL, forKey: AnyCodingKey("$schema"))
        try root.encode(version, forKey: AnyCodingKey("version"))

        // Encode root-level layout settings.
        for entry in Self.settingEntries where entry.groupKey == nil {
            try entry.encode(self, &root, AnyCodingKey(entry.key))
        }

        // Encode ungrouped rules.
        for entry in Self.ruleEntries.sorted(by: { $0.key < $1.key })
        where !ConfigurationRegistry.groupManagedRules.contains(entry.qualifiedKey) {
            try entry.encode(self, &root, AnyCodingKey(entry.key))
        }

        // Encode config groups.
        for group in ConfigurationGroup.Key.allCases {
            let configurationGroup = ConfigurationGroup(group)
            let groupSettings = Self.settingEntries.filter { $0.groupKey == group }
            let groupRuleNames = ConfigurationRegistry.groupRules[configurationGroup] ?? []

            guard !groupSettings.isEmpty || !groupRuleNames.isEmpty else { continue }

            var groupValues: [String: JSONValue] = [:]

            // Encode group-owned settings.
            for entry in groupSettings {
                let settingEncoder = JSONValueEncoder()
                var settingContainer = settingEncoder.container(keyedBy: AnyCodingKey.self)
                try entry.encode(self, &settingContainer, AnyCodingKey(entry.key))
                for (key, value) in settingEncoder.values { groupValues[key] = value }
            }

            // Encode rules within the group.
            for ruleName in groupRuleNames {
                let qualifiedKey = "\(group.rawValue).\(ruleName)"

                if let entry = Self.rulesByKey[qualifiedKey] {
                    let ruleEncoder = JSONValueEncoder()
                    var ruleContainer = ruleEncoder.container(keyedBy: AnyCodingKey.self)
                    try entry.encode(self, &ruleContainer, AnyCodingKey(ruleName))
                    for (key, value) in ruleEncoder.values { groupValues[key] = value }
                }
            }

            try root.encode(JSONValue.object(groupValues), forKey: AnyCodingKey(group.rawValue))
        }
    }
}
