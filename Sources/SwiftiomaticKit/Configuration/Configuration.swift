@_exported import ConfigurationKit
import Foundation

/// A version number that can be specified in the configuration file, which allows us to change the
/// format in the future if desired and still support older files.
private let highestSupportedConfigurationVersion = 4

/// Holds the complete set of configured values and defaults.
package struct Configuration: Sendable, Equatable {
    package static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        guard lhs.rules == rhs.rules, lhs.version == rhs.version else { return false }
        // Compare all layout settings via their LayoutRule types.
        for entry in settingEntries {
            let lKey = AnyCodingKey(entry.key)
            let tempL = DictEncoder()
            var cL = tempL.container(keyedBy: AnyCodingKey.self)
            let tempR = DictEncoder()
            var cR = tempR.container(keyedBy: AnyCodingKey.self)
            do {
                try entry.encode(lhs, &cL, lKey)
                try entry.encode(rhs, &cR, lKey)
            } catch { return false }
            // Compare via string representation of encoded values.
            guard "\(tempL.dict)" == "\(tempR.dict)" else { return false }
        }
        return true
    }
    /// Rule enablements keyed by rule name.
    package var rules: [String: RuleHandling] = ConfigurationRegistry.rules

    /// Type-erased store for layout settings and rule-specific config.
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

    // MARK: - Registry

    /// A decode closure that reads a value from a keyed container and stores it.
    private typealias SettingDecoder =
        @Sendable (
            KeyedDecodingContainer<AnyCodingKey>, AnyCodingKey, inout Configuration
        ) throws -> Void

    /// A encode closure that writes a value to a keyed container.
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

    /// Opens the existential `any LayoutRule.Type` to capture the concrete `Value` type.
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

    /// All layout setting entries, derived from `LayoutSettings.all`.
    private static let settingEntries: [SettingEntry] =
        LayoutRegistry.all.map { entry(for: $0) }

    /// Setting entries keyed by their JSON key for lookup during decoding.
    private static let settingsByKey: [String: SettingEntry] = {
        Dictionary(uniqueKeysWithValues: settingEntries.map { ($0.key, $0) })
    }()

    /// Keys that are known settings (not rules or groups).
    private static let settingKeyNames: Set<String> = {
        var names = Set(settingEntries.filter { $0.groupKey == nil }.map(\.key))
        names.insert("version")
        return names
    }()

    // MARK: - Rule config registry

    /// A rule config entry pairs a rule name with closures to decode/encode its config struct.
    private struct RuleConfigEntry: Sendable {
        /// The rule name this config belongs to (used to match JSON keys).
        let ruleName: String
        /// Decode the config struct from a Decoder (for rule objects).
        let decode: @Sendable (any Decoder, inout Configuration) throws -> Void
        /// Encode the config struct as an Encodable value.
        let encode: @Sendable (Configuration) -> any Encodable
    }

    private static func ruleConfigEntry<C: Configurable>(
        for ruleName: String, _ type: C.Type
    ) -> RuleConfigEntry where C.Value == C, C: Codable {
        RuleConfigEntry(
            ruleName: ruleName,
            decode: { decoder, config in
                config[C.self] = try C(from: decoder)
            },
            encode: { config in
                config[C.self]
            }
        )
    }

    /// All rule config entries.
    private static let ruleConfigEntries: [RuleConfigEntry] = [
        ruleConfigEntry(for: "FileScopedDeclarationPrivacy", FileScopedDeclarationPrivacyConfiguration.self),
        ruleConfigEntry(for: "NoAssignmentInExpressions", NoAssignmentInExpressionsConfiguration.self),
        ruleConfigEntry(for: "SortImports", SortImportsConfiguration.self),
        ruleConfigEntry(for: "CapitalizeAcronyms", AcronymsConfiguration.self),
        ruleConfigEntry(for: "NoExtensionAccessLevel", ExtensionAccessControlConfiguration.self),
        ruleConfigEntry(for: "PatternLetPlacement", PatternLetConfiguration.self),
        ruleConfigEntry(for: "URLMacro", URLMacroConfiguration.self),
        ruleConfigEntry(for: "FileHeader", FileHeaderConfiguration.self),
        ruleConfigEntry(for: "WrapSingleLineBodies", SingleLineBodiesConfiguration.self),
        ruleConfigEntry(for: "SwitchCaseIndentation", SwitchCaseIndentationConfiguration.self),
    ]

    /// Rule config decoders keyed by rule name.
    private static let ruleConfigDecoders: [String: @Sendable (any Decoder, inout Configuration) throws -> Void] = {
        Dictionary(uniqueKeysWithValues: ruleConfigEntries.map { ($0.ruleName, $0.decode) })
    }()

    /// Look up a rule config encoder by rule name.
    private func ruleConfigEncodable(for ruleName: String) -> (any Encodable)? {
        Self.ruleConfigEntries.first { $0.ruleName == ruleName }?.encode(self)
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

    /// Default rule enablements (generated).
    package static let defaultRuleEnablements: [String: RuleHandling] = ConfigurationRegistry.rules

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

        // Decode root-level settings.
        for entry in Self.settingEntries where entry.groupKey == nil {
            let codingKey = AnyCodingKey(entry.key)
            guard root.contains(codingKey) else { continue }
            try entry.decode(root, codingKey, &config)
        }

        // Walk remaining keys for groups and rules.
        var ruleEnablements: [String: RuleHandling] = [:]

        for key in root.allKeys {
            let name = key.stringValue

            // Skip known root-level settings (already decoded above) and version.
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
                        let optKey = AnyCodingKey(rule)
                        guard obj.contains(optKey) else { continue }

                        if let ruleMode = try? obj.decode(RuleHandling.self, forKey: optKey) {
                            ruleEnablements[rule] = ruleMode
                        } else {
                            let nested = try obj.nestedContainer(
                                keyedBy: AnyCodingKey.self,
                                forKey: optKey
                            )
                            ruleEnablements[rule] =
                                try nested.decodeIfPresent(
                                    RuleHandling.self,
                                    forKey: AnyCodingKey("handling")
                                )
                                ?? nested.decodeIfPresent(
                                    RuleHandling.self,
                                    forKey: AnyCodingKey("mode")
                                ) ?? .warning

                        }
                    }
                }
                continue
            }

            // Simple rule: string value.
            if let mode = try? root.decode(RuleHandling.self, forKey: key) {
                ruleEnablements[name] = mode
                continue
            }

            // Rule with options: object value.
            guard
                let entryContainer = try? root.nestedContainer(
                    keyedBy: AnyCodingKey.self,
                    forKey: key
                )
            else { continue }

            ruleEnablements[name] =
                try entryContainer.decodeIfPresent(
                    RuleHandling.self,
                    forKey: AnyCodingKey("handling")
                )
                ?? entryContainer.decodeIfPresent(
                    RuleHandling.self,
                    forKey: AnyCodingKey("mode")
                ) ?? .warning

            // Decode rule config struct if one is registered.
            if let decode = Self.ruleConfigDecoders[name] {
                let ruleDecoder = try root.superDecoder(forKey: key)
                try decode(ruleDecoder, &config)
            }

        }

        // Merge decoded rules over defaults.
        for (name, mode) in ruleEnablements { config.rules[name] = mode }
        self = config
    }

    package func encode(to encoder: any Encoder) throws {
        var root = encoder.container(keyedBy: AnyCodingKey.self)
        try root.encode(version, forKey: AnyCodingKey("version"))

        // Encode root-level settings.
        for entry in Self.settingEntries where entry.groupKey == nil {
            try entry.encode(self, &root, AnyCodingKey(entry.key))
        }

        // Encode ungrouped rules.
        for (name, mode) in rules.sorted(by: { $0.key < $1.key })
        where !ConfigurationRegistry.groupManagedRules.contains(name) {
            if let configEncodable = ruleConfigEncodable(for: name) {
                // Rule with config: encode as object with mode + config properties.
                let tempEncoder = DictEncoder()
                var tempContainer = tempEncoder.container(keyedBy: AnyCodingKey.self)
                try tempContainer.encode(mode.encodedString, forKey: AnyCodingKey("mode"))
                try configEncodable.encode(to: tempEncoder)
                try root.encode(JSONFragment(tempEncoder.dict), forKey: AnyCodingKey(name))
            } else {
                try root.encode(mode, forKey: AnyCodingKey(name))
            }
        }

        // Encode config groups.
        for group in ConfigurationGroup.Key.allCases {
            let cfgGroup = ConfigurationGroup(group)
            guard let mappings = ConfigurationRegistry.groupRules[cfgGroup] else { continue }

            var dict: [String: Any] = [:]

            // Encode group-owned settings.
            for entry in Self.settingEntries where entry.groupKey == group {
                let tempEncoder = DictEncoder()
                var tempContainer = tempEncoder.container(keyedBy: AnyCodingKey.self)
                try entry.encode(self, &tempContainer, AnyCodingKey(entry.key))
                for (k, v) in tempEncoder.dict { dict[k] = v }
            }

            // Encode rules within the group.
            for rule in mappings {
                let mode = rules[rule] ?? .off
                dict[rule] = mode.encodedString
            }

            try root.encode(JSONFragment(dict), forKey: AnyCodingKey(group.rawValue))
        }
    }

    // MARK: - Encoding helpers

    private struct AnyEncodable: Encodable {
        let value: any Encodable
        init(_ value: any Encodable) { self.value = value }
        func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
    }

    private struct JSONFragment: Encodable {
        let dict: [String: Any]
        init(_ dict: [String: Any]) { self.dict = dict }
        func encode(to encoder: any Encoder) throws {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let decoded = try JSONDecoder().decode([String: JSONValue].self, from: data)
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in decoded {
                try container.encode(value, forKey: AnyCodingKey(key))
            }
        }
    }

    private class DictEncoder: Encoder {
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey: Any] = [:]
        var dict: [String: Any] = [:]

        func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
            KeyedEncodingContainer(DictKeyedContainer<Key>(encoder: self))
        }
        func unkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
        func singleValueContainer() -> SingleValueEncodingContainer { fatalError() }

        private struct DictKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
            let encoder: DictEncoder
            var codingPath: [CodingKey] = []
            mutating func encodeNil(forKey key: Key) throws {}
            mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
                // Primitive types bridge to Foundation for JSONSerialization.
                // Non-primitives (enums, structs) must be round-tripped through
                // JSONEncoder to produce Foundation-compatible values.
                switch value {
                case let v as String: encoder.dict[key.stringValue] = v
                case let v as Bool: encoder.dict[key.stringValue] = v
                case let v as any FixedWidthInteger:
                    encoder.dict[key.stringValue] = Int(v)
                case let v as any BinaryFloatingPoint:
                    encoder.dict[key.stringValue] = Double(v)
                default:
                    let data = try JSONEncoder().encode(value)
                    encoder.dict[key.stringValue] = try JSONSerialization.jsonObject(
                        with: data, options: .fragmentsAllowed
                    )
                }
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
    }

    private enum JSONValue: Codable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case array([JSONValue])
        case object([String: JSONValue])
        case null

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let v = try? container.decode(Bool.self) {
                self = .bool(v)
            } else if let v = try? container.decode(Int.self) {
                self = .int(v)
            } else if let v = try? container.decode(Double.self) {
                self = .double(v)
            } else if let v = try? container.decode(String.self) {
                self = .string(v)
            } else if let v = try? container.decode([JSONValue].self) {
                self = .array(v)
            } else if let v = try? container.decode([String: JSONValue].self) {
                self = .object(v)
            } else if container.decodeNil() {
                self = .null
            } else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unsupported JSON value"
                    )
                )
            }
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let v): try container.encode(v)
            case .int(let v): try container.encode(v)
            case .double(let v): try container.encode(v)
            case .bool(let v): try container.encode(v)
            case .array(let v): try container.encode(v)
            case .object(let v): try container.encode(v)
            case .null: try container.encodeNil()
            }
        }
    }
}
