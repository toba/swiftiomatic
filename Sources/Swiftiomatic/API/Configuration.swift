//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@_exported import SwiftiomaticCore

/// A version number that can be specified in the configuration file, which allows us to change the
/// format in the future if desired and still support older files.
///
/// Note that *adding* new configuration values is not a version-breaking change; sm will
/// use default values when loading older configurations that don't contain the new settings. This
/// value only needs to be updated if the configuration changes in a way that would be incompatible
/// with the previous format.
internal let highestSupportedConfigurationVersion = 4

/// Holds the complete set of configured values and defaults.
public struct Configuration: Codable, Equatable, Sendable {

  /// A coding key backed by a runtime string, used to iterate heterogeneous JSON dictionaries.
  private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
  }

  // MARK: - FormatSetting table (replaces FormatSettings struct)

  /// A single pretty-print setting, with closure-based decode/encode keyed by a JSON key name.
  /// Settings may optionally belong to a ``ConfigGroup``, in which case they decode/encode
  /// inside that group's JSON object rather than at the root.
  private struct FormatSetting: Sendable {
    let key: String
    let group: ConfigGroup?
    let decode: @Sendable (KeyedDecodingContainer<DynamicCodingKey>, inout Configuration) throws -> Void
    let encode: @Sendable (Configuration, inout KeyedEncodingContainer<DynamicCodingKey>) throws -> Void

    static func setting<V: Codable & Sendable>(
      _ key: String,
      _ keyPath: WritableKeyPath<Configuration, V> & Sendable,
      group: ConfigGroup? = nil
    ) -> FormatSetting {
      FormatSetting(
        key: key,
        group: group,
        decode: { container, config in
          // Use try? to tolerate type mismatches (e.g. "indentation" key can be
          // either an Indent value or a ConfigGroup object depending on format).
          if let value = try? container.decodeIfPresent(V.self, forKey: DynamicCodingKey(key)) {
            config[keyPath: keyPath] = value
          }
        },
        encode: { config, container in
          try container.encode(config[keyPath: keyPath], forKey: DynamicCodingKey(key))
        }
      )
    }
  }

  /// All pretty-print settings. Root-level settings have `group: nil`; group-owned settings
  /// have a non-nil group and encode/decode inside that group's JSON object.
  private static let allSettings: [FormatSetting] = [
    // Root-level settings
    .setting("lineLength", \.lineLength),
    .setting("tabWidth", \.tabWidth),
    .setting("indentation", \.indentation),
    .setting("respectsExistingLineBreaks", \.respectsExistingLineBreaks),
    .setting("spacesBeforeEndOfLineComments", \.spacesBeforeEndOfLineComments),
    .setting("spacesAroundRangeFormationOperators", \.spacesAroundRangeFormationOperators),
    .setting("prioritizeKeepingFunctionOutputTogether", \.prioritizeKeepingFunctionOutputTogether),
    .setting("multilineTrailingCommaBehavior", \.multilineTrailingCommaBehavior),
    .setting("multiElementCollectionTrailingCommas", \.multiElementCollectionTrailingCommas),
    .setting("reflowMultilineStringLiterals", \.reflowMultilineStringLiterals),

    // Group-owned settings (encode inside their group's JSON object)
    .setting("blankLines", \.indentBlankLines, group: .indentation),
    .setting("conditionalCompilationBlocks", \.indentConditionalCompilationBlocks, group: .indentation),
    .setting("maximumBlankLines", \.maximumBlankLines, group: .blankLines),
    .setting("beforeControlFlowKeywords", \.lineBreakBeforeControlFlowKeywords, group: .lineBreaks),
    .setting("beforeEachArgument", \.lineBreakBeforeEachArgument, group: .lineBreaks),
    .setting("beforeEachGenericRequirement", \.lineBreakBeforeEachGenericRequirement, group: .lineBreaks),
    .setting("betweenDeclarationAttributes", \.lineBreakBetweenDeclarationAttributes, group: .lineBreaks),
    .setting("aroundMultilineExpressionChainComponents", \.lineBreakAroundMultilineExpressionChainComponents, group: .lineBreaks),
    .setting("beforeGuardConditions", \.lineBreakBeforeGuardConditions, group: .lineBreaks),
  ]

  /// Keys that are known settings (not rules or groups), used to skip them during rule decoding.
  private static let settingKeyNames: Set<String> = {
    var names = Set(allSettings.filter { $0.group == nil }.map(\.key))
    names.insert("version")
    return names
  }()

  /// Keys that are config group names.
  private static let groupKeyNames: Set<String> = Set(ConfigGroup.allCases.map(\.rawValue))

  // MARK: - Rule config registration

  /// Pairs a rule type with its config type's keyPath on Configuration.
  private struct RuleConfigEntry: Sendable {
    let ruleName: String
    let configProperties: [ConfigProperty]
    let decode: @Sendable (Decoder, inout Configuration) throws -> Void
    /// Decode from a keyed container at the given key (used for group-nested rules
    /// where `superDecoder(forKey:)` on a nested container is unreliable).
    let decodeFromContainer: @Sendable (KeyedDecodingContainer<DynamicCodingKey>, DynamicCodingKey, inout Configuration) throws -> Void
    let encode: @Sendable (Configuration) -> any Encodable

    static func entry<R: Rule, C: ConfigRepresentable & Codable>(
      _: R.Type,
      _ keyPath: WritableKeyPath<Configuration, C> & Sendable
    ) -> RuleConfigEntry {
      RuleConfigEntry(
        ruleName: R.name,
        configProperties: C.configProperties,
        decode: { decoder, config in config[keyPath: keyPath] = try C(from: decoder) },
        decodeFromContainer: { container, key, config in
          config[keyPath: keyPath] = try container.decode(C.self, forKey: key)
        },
        encode: { config in config[keyPath: keyPath] }
      )
    }
  }

  private static let ruleConfigEntries: [RuleConfigEntry] = [
    .entry(FileScopedDeclarationPrivacy.self, \.fileScopedDeclarationPrivacy),
    .entry(NoAssignmentInExpressions.self, \.noAssignmentInExpressions),
    .entry(SortImports.self, \.sortImports),
    .entry(CapitalizeAcronyms.self, \.acronyms),
    .entry(NoExtensionAccessLevel.self, \.extensionAccessControl),
    .entry(PatternLetPlacement.self, \.patternLet),
    .entry(URLMacro.self, \.urlMacro),
    .entry(FileHeader.self, \.fileHeader),
    .entry(WrapSingleLineBodies.self, \.singleLineBodies),
    .entry(SwitchCaseIndentation.self, \.switchCaseIndentation),
  ]

  private static let ruleConfigDecoders: [String: @Sendable (Decoder, inout Configuration) throws -> Void] = {
    Dictionary(uniqueKeysWithValues: ruleConfigEntries.map { ($0.ruleName, $0.decode) })
  }()

  private static let ruleConfigContainerDecoders: [String: @Sendable (KeyedDecodingContainer<DynamicCodingKey>, DynamicCodingKey, inout Configuration) throws -> Void] = {
    Dictionary(uniqueKeysWithValues: ruleConfigEntries.map { ($0.ruleName, $0.decodeFromContainer) })
  }()

  /// Rule config schemas keyed by rule name, for the schema generator.
  package static let ruleConfigSchemas: [String: [ConfigProperty]] = {
    Dictionary(uniqueKeysWithValues: ruleConfigEntries.map { ($0.ruleName, $0.configProperties) })
  }()

  /// A dictionary containing the default enabled/disabled states of rules, keyed by the rules'
  /// names.
  ///
  /// This value is generated by `generate-swiftiomatic` based on the `isOptIn` value of each rule.
  public static let defaultRuleEnablements: [String: RuleHandling] = RuleRegistry.rules

  /// The version of this configuration.
  private var version: Int = highestSupportedConfigurationVersion

  // MARK: - Common configuration

  /// The dictionary containing the rule names that we wish to run on. A rule is not used if it is
  /// marked as `.off`, or if it is missing from the dictionary.
  public var rules: [String: RuleHandling]

  /// The maximum number of consecutive blank lines that may appear in a file.
  public var maximumBlankLines: Int

  /// The maximum length of a line of source code, after which the formatter will break lines.
  public var lineLength: Int

  /// Number of spaces that precede line comments.
  public var spacesBeforeEndOfLineComments: Int

  /// The width of the horizontal tab in spaces.
  ///
  /// This value is used when converting indentation types (for example, from tabs into spaces).
  public var tabWidth: Int

  /// A value representing a single level of indentation.
  ///
  /// All indentation will be conducted in multiples of this configuration.
  public var indentation: Indent

  /// Indicates that the formatter should try to respect users' discretionary line breaks when
  /// possible.
  ///
  /// For example, a short `if` statement and its single-statement body might be able to fit on one
  /// line, but for readability the user might break it inside the curly braces. If this setting is
  /// true, those line breaks will be kept. If this setting is false, the formatter will act more
  /// "opinionated" and collapse the statement onto a single line.
  public var respectsExistingLineBreaks: Bool

  // MARK: - Rule-specific configuration

  /// Determines the line-breaking behavior for control flow keywords that follow a closing brace,
  /// like `else` and `catch`.
  ///
  /// If true, a line break will be added before the keyword, forcing it onto its own line. If
  /// false (the default), the keyword will be placed after the closing brace (separated by a
  /// space).
  public var lineBreakBeforeControlFlowKeywords: Bool

  /// Determines the line-breaking behavior for generic arguments and function arguments when a
  /// declaration is wrapped onto multiple lines.
  ///
  /// If false (the default), arguments will be laid out horizontally first, with line breaks only
  /// being fired when the line length would be exceeded. If true, a line break will be added before
  /// each argument, forcing the entire argument list to be laid out vertically.
  public var lineBreakBeforeEachArgument: Bool

  /// Determines the line-breaking behavior for generic requirements when the requirements list
  /// is wrapped onto multiple lines.
  ///
  /// If true, a line break will be added before each requirement, forcing the entire requirements
  /// list to be laid out vertically. If false (the default), requirements will be laid out
  /// horizontally first, with line breaks only being fired when the line length would be exceeded.
  public var lineBreakBeforeEachGenericRequirement: Bool

  /// If true, a line break will be added between adjacent attributes.
  public var lineBreakBetweenDeclarationAttributes: Bool

  /// Determines if function-like declaration outputs should be prioritized to be together with the
  /// function signature's right (closing) parenthesis.
  ///
  /// If false (the default), function output (i.e. throws, return type) is not prioritized to be
  /// together with the signature's right parenthesis, and when the line length would be exceeded,
  /// a line break will be fired after the function signature first, indenting the declaration output
  /// one additional level. If true, a line break will be fired further up in the function's
  /// declaration (e.g. generic parameters, parameters) before breaking on the function's output.
  public var prioritizeKeepingFunctionOutputTogether: Bool

  /// Determines the indentation behavior for `#if`, `#elseif`, and `#else`.
  public var indentConditionalCompilationBlocks: Bool

  /// Determines whether line breaks should be forced before and after multiline components of
  /// dot-chained expressions, such as function calls and subscripts chained together through member
  /// access (i.e. "." expressions). When any component is multiline and this option is true, a line
  /// break is forced before the "." of the component and after the component's closing delimiter
  /// (i.e. right paren, right bracket, right brace, etc.).
  public var lineBreakAroundMultilineExpressionChainComponents: Bool

  /// Determines whether guard statement conditions are placed on separate lines from the `guard`
  /// keyword.
  ///
  /// If true (the default), all conditions are placed on their own lines below `guard`, matching
  /// the original swift-format behavior. If false, the first condition stays on the same line as
  /// `guard` (like `if` statements), and `else` stays on the same line as the last condition when
  /// it fits.
  public var lineBreakBeforeGuardConditions: Bool

  /// Determines the formal access level (i.e., the level specified in source code) for file-scoped
  /// declarations whose effective access level is private to the containing file.
  public var fileScopedDeclarationPrivacy: FileScopedDeclarationPrivacyConfiguration

  /// Determines the indentation style for switch case labels (flush or indented).
  public var switchCaseIndentation: SwitchCaseIndentationConfiguration

  /// Determines whether whitespace should be forced before and after the range formation operators
  /// `...` and `..<`.
  public var spacesAroundRangeFormationOperators: Bool

  /// Contains exceptions for the `NoAssignmentInExpressions` rule.
  public var noAssignmentInExpressions: NoAssignmentInExpressionsConfiguration

  /// Determines how trailing commas in comma-separated lists should be handled during formatting.
  public enum MultilineTrailingCommaBehavior: String, Codable, Sendable {
    case alwaysUsed
    case neverUsed
    case keptAsWritten
  }

  /// Determines how trailing commas in multiline comma-separated lists are handled during formatting.
  public var multilineTrailingCommaBehavior: MultilineTrailingCommaBehavior

  /// Determines if multi-element collection literals should have trailing commas.
  public var multiElementCollectionTrailingCommas: Bool

  /// Determines how multiline string literals should reflow when formatted.
  public enum MultilineStringReflowBehavior: String, Codable, Sendable {
    case never
    case onlyLinesOverLength
    case always

    var isNever: Bool { self == .never }
    var isAlways: Bool { self == .always }
  }

  public var reflowMultilineStringLiterals: MultilineStringReflowBehavior

  /// Determines whether to add indentation whitespace to blank lines or remove it entirely.
  public var indentBlankLines: Bool

  /// Configuration for the `SortImports` rule.
  public var sortImports: SortImportsConfiguration

  /// Configuration for the `CapitalizeAcronyms` rule.
  public var acronyms: AcronymsConfiguration = AcronymsConfiguration()

  /// Determines where access control modifiers are placed for extension declarations.
  public var extensionAccessControl: ExtensionAccessControlConfiguration

  /// Determines where `let`/`var` is placed in case patterns.
  public var patternLet: PatternLetConfiguration

  /// Configuration for replacing `URL(string:)!` with a macro like `#URL(...)`.
  public var urlMacro: URLMacroConfiguration

  /// Configuration for enforcing a file header comment.
  public var fileHeader: FileHeaderConfiguration

  /// Configuration for single-line body handling (wrap or inline).
  public var singleLineBodies: SingleLineBodiesConfiguration

  /// Creates a new `Configuration` by loading it from a configuration file.
  public init(contentsOf url: URL) throws {
    let data = try Data(contentsOf: url)
    try self.init(data: data)
  }

  /// Creates a new `Configuration` by decoding it from the UTF-8 representation in the given data.
  public init(data: Data) throws {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.allowsJSON5 = true
    self = try jsonDecoder.decode(Configuration.self, from: data)
  }

  // MARK: - Decoding

  public init(from decoder: Decoder) throws {
    let root = try decoder.container(keyedBy: DynamicCodingKey.self)

    // Decode version.
    let version = try root.decodeIfPresent(Int.self, forKey: DynamicCodingKey("version"))
      ?? highestSupportedConfigurationVersion
    guard version <= highestSupportedConfigurationVersion else {
      throw SwiftiomaticError.unsupportedConfigurationVersion(
        version,
        highestSupported: highestSupportedConfigurationVersion
      )
    }

    // Start from defaults; keys below override what they find.
    var config = Configuration()

    // Decode root-level settings.
    for setting in Self.allSettings where setting.group == nil {
      try setting.decode(root, &config)
    }

    // Decode rules and groups from the root.
    var ruleEnablements: [String: RuleHandling] = [:]

    for key in root.allKeys {
      let name = key.stringValue

      // Config group: decode rules + owned settings.
      // Check groups first — "indentation" is both a root setting and a group name.
      if let group = ConfigGroup(rawValue: name) {
        let obj = try root.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key)

        // Decode group-owned settings.
        for setting in Self.allSettings where setting.group == group {
          try setting.decode(obj, &config)
        }

        // Decode rules within the group.
        if let mappings = RuleRegistry.groupRules[group] {
          for (option, rule) in mappings {
            let optKey = DynamicCodingKey(option)
            guard obj.contains(optKey) else { continue }

            // Simple string value (e.g. "autoFix", "warn", "off").
            if let ruleMode = try? obj.decode(RuleHandling.self, forKey: optKey) {
              ruleEnablements[rule] = ruleMode
            } else {
              // Object value with "mode" + rule-specific config.
              let nested = try obj.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: optKey)
              ruleEnablements[rule] =
                try nested.decodeIfPresent(RuleHandling.self, forKey: DynamicCodingKey("mode")) ?? .warning

              if let decode = Self.ruleConfigContainerDecoders[rule] {
                try decode(obj, optKey, &config)
              }
            }
          }
        }
        continue
      }

      // Skip known settings and the version key.
      guard !Self.settingKeyNames.contains(name) else { continue }

      // Simple rule: string value (e.g., "autoFix", "warn", "off").
      if let mode = try? root.decode(RuleHandling.self, forKey: key) {
        ruleEnablements[name] = mode
        continue
      }

      // Rule with options: object value with "mode" + rule-specific config.
      // Guard against non-object values (e.g. "$schema" URL string).
      guard let entryContainer = try? root.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key) else {
        continue
      }
      ruleEnablements[name] =
        try entryContainer.decodeIfPresent(RuleHandling.self, forKey: DynamicCodingKey("mode")) ?? .warning

      if let decode = Self.ruleConfigDecoders[name] {
        let entryDecoder = try root.superDecoder(forKey: key)
        try decode(entryDecoder, &config)
      }
    }

    // Merge decoded rules over defaults.
    for (name, mode) in ruleEnablements { config.rules[name] = mode }
    self = config
  }

  // MARK: - Encoding

  /// Rules that have config structs, mapped to the encodable config value.
  private func ruleConfigEncodable(for ruleName: String) -> (any Encodable)? {
    Self.ruleConfigEntries.first { $0.ruleName == ruleName }?.encode(self)
  }

  public func encode(to encoder: Encoder) throws {
    var root = encoder.container(keyedBy: DynamicCodingKey.self)
    try root.encode(version, forKey: DynamicCodingKey("version"))

    // Encode root-level settings.
    for setting in Self.allSettings where setting.group == nil {
      try setting.encode(self, &root)
    }

    // Encode ungrouped rules.
    for (name, mode) in rules
      where !RuleRegistry.groupManagedRules.contains(name)
    {
      if let config = ruleConfigEncodable(for: name) {
        let configData = try JSONEncoder().encode(AnyEncodable(config))
        if var configDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] {
          configDict["mode"] = mode.encodedString
          try root.encode(JSONFragment(configDict), forKey: DynamicCodingKey(name))
        }
      } else {
        try root.encode(mode, forKey: DynamicCodingKey(name))
      }
    }

    // Encode config groups.
    for group in ConfigGroup.allCases {
      guard let mappings = RuleRegistry.groupRules[group] else { continue }

      var dict: [String: Any] = [:]

      // Encode group-owned settings.
      for setting in Self.allSettings where setting.group == group {
        // Use a temporary container to extract the value, then put it in the dict.
        let tempEncoder = DictEncoder()
        var tempContainer = tempEncoder.container(keyedBy: DynamicCodingKey.self)
        try setting.encode(self, &tempContainer)
        for (k, v) in tempEncoder.dict { dict[k] = v }
      }

      // Encode rules within the group.
      for (option, rule) in mappings {
        let mode = rules[rule] ?? .off
        if let config = ruleConfigEncodable(for: rule) {
          let configData = try JSONEncoder().encode(AnyEncodable(config))
          if var configDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] {
            configDict["mode"] = mode.encodedString
            dict[option] = configDict
          }
        } else {
          dict[option] = mode.encodedString
        }
      }

      try root.encode(JSONFragment(dict), forKey: DynamicCodingKey(group.rawValue))
    }
  }

  // MARK: - Helpers

  /// Type-erased Encodable wrapper.
  private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
  }

  /// Encodes a `[String: Any]` dict as a JSON object via JSONSerialization round-trip.
  private struct JSONFragment: Encodable {
    let dict: [String: Any]
    init(_ dict: [String: Any]) { self.dict = dict }
    func encode(to encoder: Encoder) throws {
      let data = try JSONSerialization.data(withJSONObject: dict)
      let decoded = try JSONDecoder().decode([String: JSONValue].self, from: data)
      var container = encoder.container(keyedBy: DynamicCodingKey.self)
      for (key, value) in decoded {
        try container.encode(value, forKey: DynamicCodingKey(key))
      }
    }
  }

  /// A temporary encoder that captures encoded values into a dictionary.
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
        encoder.dict[key.stringValue] = value
      }
      mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type, forKey key: Key
      ) -> KeyedEncodingContainer<NestedKey> { fatalError() }
      mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { fatalError() }
      mutating func superEncoder() -> Encoder { fatalError() }
      mutating func superEncoder(forKey key: Key) -> Encoder { fatalError() }
    }
  }

  /// Generic JSON value for re-encoding arbitrary JSON.
  private enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if let v = try? container.decode(Bool.self) { self = .bool(v) }
      else if let v = try? container.decode(Int.self) { self = .int(v) }
      else if let v = try? container.decode(Double.self) { self = .double(v) }
      else if let v = try? container.decode(String.self) { self = .string(v) }
      else if let v = try? container.decode([JSONValue].self) { self = .array(v) }
      else if let v = try? container.decode([String: JSONValue].self) { self = .object(v) }
      else if container.decodeNil() { self = .null }
      else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")) }
    }

    func encode(to encoder: Encoder) throws {
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

  /// Returns the URL of the configuration file that applies to the given file or directory.
  public static func url(forConfigurationFileApplyingTo url: URL) -> URL? {
    var candidateDirectory = url.absoluteURL.standardized
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: candidateDirectory.path, isDirectory: &isDirectory),
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

// Rule-specific configuration types are defined in SwiftiomaticCore/RuleConfigs.swift
