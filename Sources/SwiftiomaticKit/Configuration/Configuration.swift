@_exported import ConfigurationKit
import Foundation

/// Holds the complete set of configured values and defaults.
package struct Configuration: Sendable, Equatable {
    package static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        guard lhs.version == rhs.version else { return false }
        // Compare all layout settings via their LayoutRule types.
        for entry in settingEntries {
            let lKey = AnyCodingKey(entry.key)
            let tempL = JSONValueEncoder()
            var cL = tempL.container(keyedBy: AnyCodingKey.self)
            let tempR = JSONValueEncoder()
            var cR = tempR.container(keyedBy: AnyCodingKey.self)
            do {
                try entry.encode(lhs, &cL, lKey)
                try entry.encode(rhs, &cR, lKey)
            } catch { return false }
            guard tempL.dict == tempR.dict else { return false }
        }
        // Compare all rule values.
        for entry in ruleEntries {
            let lKey = AnyCodingKey(entry.key)
            let tempL = JSONValueEncoder()
            var cL = tempL.container(keyedBy: AnyCodingKey.self)
            let tempR = JSONValueEncoder()
            var cR = tempR.container(keyedBy: AnyCodingKey.self)
            do {
                try entry.encode(lhs, &cL, lKey)
                try entry.encode(rhs, &cR, lKey)
            } catch { return false }
            guard tempL.dict == tempR.dict else { return false }
        }
        return true
    }

    /// Type-erased store for layout settings and rule values.
    private var values: [String: any Sendable] = [:]

    /// Version of the configuration format.
    private var version: Int = highestSupportedConfigurationVersion

    // MARK: - Typed access

    /// Look up any `Configurable` value by type, falling back to its default.
    package subscript<C: Configurable>(type: C.Type = C.self) -> C.Value {
        get {
            if let group = C.group {
                if let v = values["\(group.key).\(C.key)"] as? C.Value { return v }
            }
            return values[C.key] as? C.Value ?? C.defaultValue
        }
        set {
            if let group = C.group {
                values["\(group.key).\(C.key)"] = newValue
            } else {
                values[C.key] = newValue
            }
        }
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
    }

    private static func entry(for type: any LayoutRule.Type) -> SettingEntry {
        func open<D: LayoutRule>(_ type: D.Type) -> SettingEntry {
            SettingEntry(
                key: D.key,
                groupKey: D.group?.key,
                decode: { container, codingKey, config in
                    if let value = try container.decodeIfPresent(D.Value.self, forKey: codingKey) {
                        config[D.self] = value
                    }
                },
                encode: { config, container, codingKey in
                    try container.encode(config[D.self], forKey: codingKey)
                }
            )
        }
        return open(type)
    }

    private static let settingEntries: [SettingEntry] =
        LayoutRegistry.all.map { entry(for: $0) }

    private static let settingsByKey: [String: SettingEntry] = {
        Dictionary(uniqueKeysWithValues: settingEntries.map { ($0.key, $0) })
    }()

    private static let settingKeyNames: Set<String> = {
        var names = Set(settingEntries.filter { $0.groupKey == nil }.map(\.key))
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
        let decode: @Sendable (KeyedDecodingContainer<AnyCodingKey>, AnyCodingKey, inout Configuration) throws -> Void
        let encode: @Sendable (Configuration, inout KeyedEncodingContainer<AnyCodingKey>, AnyCodingKey) throws -> Void
        let disable: @Sendable (inout Configuration) -> Void
        let enable: @Sendable (inout Configuration) -> Void
    }

    private static func ruleEntry(for type: any SyntaxRule.Type) -> RuleEntry {
        func open<R: SyntaxRule>(_ type: R.Type) -> RuleEntry {
            RuleEntry(
                key: R.key,
                qualifiedKey: R.qualifiedKey,
                groupKey: R.group?.key,
                decode: { container, codingKey, config in
                    if let value = try container.decodeIfPresent(R.Value.self, forKey: codingKey) {
                        config[R.self] = value
                    }
                },
                encode: { config, container, codingKey in
                    try container.encode(config[R.self], forKey: codingKey)
                },
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
                }
            )
        }
        return open(type)
    }

    private static let ruleEntries: [RuleEntry] =
        ConfigurationRegistry.allRuleTypes.map { ruleEntry(for: $0) }

    private static let rulesByKey: [String: RuleEntry] = {
        Dictionary(uniqueKeysWithValues: ruleEntries.map { ($0.qualifiedKey, $0) })
    }()

    // MARK: - Rule helpers

    /// Disables all syntax rules by setting `enabled = false` on each rule's value.
    package mutating func disableAllRules() {
        for entry in Self.ruleEntries {
            entry.disable(&self)
        }
    }

    /// Enables a rule by qualified key (`group.key` or bare `key`).
    package mutating func enableRule(named name: String) {
        if let entry = Self.rulesByKey[name] {
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
private let highestSupportedConfigurationVersion = 6

// MARK: - Codable

extension Configuration: Codable {
    package init(from decoder: any Decoder) throws {
        let root = try decoder.container(keyedBy: AnyCodingKey.self)

        // Decode version.
        let version =
            try root.decodeIfPresent(Int.self, forKey: AnyCodingKey("version"))
            ?? highestSupportedConfigurationVersion
        guard version <= highestSupportedConfigurationVersion else {
            throw SwiftiomaticError.unsupportedConfigurationVersion(
                version,
                highestSupported: highestSupportedConfigurationVersion
            )
        }

        var config = Configuration()
        config.version = version

        // Decode root-level layout settings.
        for entry in Self.settingEntries where entry.groupKey == nil {
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
                let obj = try root.nestedContainer(keyedBy: AnyCodingKey.self, forKey: key)

                // Decode group-owned settings.
                for entry in Self.settingEntries where entry.groupKey == groupKey {
                    let codingKey = AnyCodingKey(entry.key)
                    guard obj.contains(codingKey) else { continue }
                    try entry.decode(obj, codingKey, &config)
                }

                // Decode rules within the group.
                if let mappings = ConfigurationRegistry.groupRules[ConfigurationGroup(groupKey)] {
                    for rule in mappings {
                        let ruleKey = AnyCodingKey(rule)
                        guard obj.contains(ruleKey) else { continue }
                        let qualified = "\(groupKey.rawValue).\(rule)"
                        if let entry = Self.rulesByKey[qualified] {
                            try entry.decode(obj, ruleKey, &config)
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
            let cfgGroup = ConfigurationGroup(group)
            let groupSettings = Self.settingEntries.filter { $0.groupKey == group }
            let groupRuleNames = ConfigurationRegistry.groupRules[cfgGroup] ?? []

            guard !groupSettings.isEmpty || !groupRuleNames.isEmpty else { continue }

            var dict: [String: JSONValue] = [:]

            // Encode group-owned settings.
            for entry in groupSettings {
                let tempEncoder = JSONValueEncoder()
                var tempContainer = tempEncoder.container(keyedBy: AnyCodingKey.self)
                try entry.encode(self, &tempContainer, AnyCodingKey(entry.key))
                for (k, v) in tempEncoder.dict { dict[k] = v }
            }

            // Encode rules within the group.
            for ruleName in groupRuleNames {
                let qualified = "\(group.rawValue).\(ruleName)"
                if let entry = Self.rulesByKey[qualified] {
                    let tempEncoder = JSONValueEncoder()
                    var tempContainer = tempEncoder.container(keyedBy: AnyCodingKey.self)
                    try entry.encode(self, &tempContainer, AnyCodingKey(ruleName))
                    for (k, v) in tempEncoder.dict { dict[k] = v }
                }
            }

            try root.encode(JSONValue.object(dict), forKey: AnyCodingKey(group.rawValue))
        }
    }

}

// MARK: - JSONValue Encoder

/// Lightweight encoder that captures key-value pairs as `JSONValue`
/// instead of `Any`, enabling type-safe equality and direct encoding
/// without `JSONSerialization` round-trips.
final class JSONValueEncoder: Encoder {
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]
    var dict: [String: JSONValue] = [:]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(JSONValueKeyedContainer<Key>(encoder: self))
    }
    func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
    func singleValueContainer() -> SingleValueEncodingContainer {
        JSONValueSingleContainer(encoder: self)
    }

    /// Converts an arbitrary `Encodable` to `JSONValue` via `JSONEncoder`
    /// round-trip. Used only for complex nested types.
    private static func encodeToJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    private struct JSONValueKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []
        mutating func encodeNil(forKey key: Key) throws {
            encoder.dict[key.stringValue] = .null
        }
        mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
            encoder.dict[key.stringValue] = try JSONValueEncoder.toJSONValue(value)
        }
        mutating func nestedContainer<NestedKey: CodingKey>(
            keyedBy keyType: NestedKey.Type,
            forKey key: Key
        ) -> KeyedEncodingContainer<NestedKey> { fatalError() }
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            fatalError()
        }
        mutating func superEncoder() -> any Encoder { fatalError() }
        mutating func superEncoder(forKey key: Key) -> any Encoder { fatalError() }
    }

    private struct JSONValueSingleContainer: SingleValueEncodingContainer {
        let encoder: JSONValueEncoder
        var codingPath: [CodingKey] = []
        mutating func encodeNil() throws {
            encoder.dict["_singleValue"] = .null
        }
        mutating func encode<T: Encodable>(_ value: T) throws {
            encoder.dict["_singleValue"] = try JSONValueEncoder.toJSONValue(value)
        }
    }

    /// Converts a primitive or complex `Encodable` value to `JSONValue`.
    fileprivate static func toJSONValue<T: Encodable>(_ value: T) throws -> JSONValue {
        switch value {
        case let v as String: .string(v)
        case let v as Bool: .bool(v)
        case let v as any FixedWidthInteger: .int(Int(v))
        case let v as any BinaryFloatingPoint: .double(Double(v))
        default: try encodeToJSONValue(value)
        }
    }
}

