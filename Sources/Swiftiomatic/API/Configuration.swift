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

/// A version number that can be specified in the configuration file, which allows us to change the
/// format in the future if desired and still support older files.
///
/// Note that *adding* new configuration values is not a version-breaking change; sm will
/// use default values when loading older configurations that don't contain the new settings. This
/// value only needs to be updated if the configuration changes in a way that would be incompatible
/// with the previous format.
internal let highestSupportedConfigurationVersion = 3

/// Holds the complete set of configured values and defaults.
public struct Configuration: Codable, Equatable, Sendable {

  private enum CodingKeys: CodingKey {
    case version
    case format
    case lint
  }

  /// A coding key backed by a runtime string, used to iterate heterogeneous JSON dictionaries.
  private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ string: String) { self.stringValue = string }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
  }

  /// Codable container for the formatting settings that live inside the `format` JSON section.
  /// Rule keys (anything not a CodingKey case) are ignored by the decoder and handled separately.
  private struct FormatSettings: Codable, Equatable {
    var lineLength: Int
    var spacesBeforeEndOfLineComments: Int
    var tabWidth: Int
    var indentation: Indent
    var respectsExistingLineBreaks: Bool
    var lineBreakBeforeControlFlowKeywords: Bool
    var lineBreakBeforeEachArgument: Bool
    var lineBreakBeforeEachGenericRequirement: Bool
    var lineBreakBetweenDeclarationAttributes: Bool
    var prioritizeKeepingFunctionOutputTogether: Bool
    var indentConditionalCompilationBlocks: Bool
    var lineBreakAroundMultilineExpressionChainComponents: Bool
    var indentSwitchCaseLabels: Bool
    var spacesAroundRangeFormationOperators: Bool
    var multilineTrailingCommaBehavior: MultilineTrailingCommaBehavior
    var multiElementCollectionTrailingCommas: Bool
    var reflowMultilineStringLiterals: MultilineStringReflowBehavior
    var indentBlankLines: Bool

    init(from config: Configuration) {
      self.lineLength = config.lineLength
      self.spacesBeforeEndOfLineComments = config.spacesBeforeEndOfLineComments
      self.tabWidth = config.tabWidth
      self.indentation = config.indentation
      self.respectsExistingLineBreaks = config.respectsExistingLineBreaks
      self.lineBreakBeforeControlFlowKeywords = config.lineBreakBeforeControlFlowKeywords
      self.lineBreakBeforeEachArgument = config.lineBreakBeforeEachArgument
      self.lineBreakBeforeEachGenericRequirement = config.lineBreakBeforeEachGenericRequirement
      self.lineBreakBetweenDeclarationAttributes = config.lineBreakBetweenDeclarationAttributes
      self.prioritizeKeepingFunctionOutputTogether = config.prioritizeKeepingFunctionOutputTogether
      self.indentConditionalCompilationBlocks = config.indentConditionalCompilationBlocks
      self.lineBreakAroundMultilineExpressionChainComponents = config.lineBreakAroundMultilineExpressionChainComponents
      self.indentSwitchCaseLabels = config.indentSwitchCaseLabels
      self.spacesAroundRangeFormationOperators = config.spacesAroundRangeFormationOperators
      self.multilineTrailingCommaBehavior = config.multilineTrailingCommaBehavior
      self.multiElementCollectionTrailingCommas = config.multiElementCollectionTrailingCommas
      self.reflowMultilineStringLiterals = config.reflowMultilineStringLiterals
      self.indentBlankLines = config.indentBlankLines
    }

    init(from decoder: Decoder) throws {
      let defaults = Configuration()
      let c = try decoder.container(keyedBy: CodingKeys.self)
      self.lineLength = try c.decodeIfPresent(Int.self, forKey: .lineLength) ?? defaults.lineLength
      self.spacesBeforeEndOfLineComments = try c.decodeIfPresent(Int.self, forKey: .spacesBeforeEndOfLineComments) ?? defaults.spacesBeforeEndOfLineComments
      self.tabWidth = try c.decodeIfPresent(Int.self, forKey: .tabWidth) ?? defaults.tabWidth
      self.indentation = try c.decodeIfPresent(Indent.self, forKey: .indentation) ?? defaults.indentation
      self.respectsExistingLineBreaks = try c.decodeIfPresent(Bool.self, forKey: .respectsExistingLineBreaks) ?? defaults.respectsExistingLineBreaks
      self.lineBreakBeforeControlFlowKeywords = try c.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeControlFlowKeywords) ?? defaults.lineBreakBeforeControlFlowKeywords
      self.lineBreakBeforeEachArgument = try c.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeEachArgument) ?? defaults.lineBreakBeforeEachArgument
      self.lineBreakBeforeEachGenericRequirement = try c.decodeIfPresent(Bool.self, forKey: .lineBreakBeforeEachGenericRequirement) ?? defaults.lineBreakBeforeEachGenericRequirement
      self.lineBreakBetweenDeclarationAttributes = try c.decodeIfPresent(Bool.self, forKey: .lineBreakBetweenDeclarationAttributes) ?? defaults.lineBreakBetweenDeclarationAttributes
      self.prioritizeKeepingFunctionOutputTogether = try c.decodeIfPresent(Bool.self, forKey: .prioritizeKeepingFunctionOutputTogether) ?? defaults.prioritizeKeepingFunctionOutputTogether
      self.indentConditionalCompilationBlocks = try c.decodeIfPresent(Bool.self, forKey: .indentConditionalCompilationBlocks) ?? defaults.indentConditionalCompilationBlocks
      self.lineBreakAroundMultilineExpressionChainComponents = try c.decodeIfPresent(Bool.self, forKey: .lineBreakAroundMultilineExpressionChainComponents) ?? defaults.lineBreakAroundMultilineExpressionChainComponents
      self.indentSwitchCaseLabels = try c.decodeIfPresent(Bool.self, forKey: .indentSwitchCaseLabels) ?? defaults.indentSwitchCaseLabels
      self.spacesAroundRangeFormationOperators = try c.decodeIfPresent(Bool.self, forKey: .spacesAroundRangeFormationOperators) ?? defaults.spacesAroundRangeFormationOperators
      self.multilineTrailingCommaBehavior = try c.decodeIfPresent(MultilineTrailingCommaBehavior.self, forKey: .multilineTrailingCommaBehavior) ?? defaults.multilineTrailingCommaBehavior
      self.multiElementCollectionTrailingCommas = try c.decodeIfPresent(Bool.self, forKey: .multiElementCollectionTrailingCommas) ?? defaults.multiElementCollectionTrailingCommas
      self.reflowMultilineStringLiterals = try c.decodeIfPresent(MultilineStringReflowBehavior.self, forKey: .reflowMultilineStringLiterals) ?? defaults.reflowMultilineStringLiterals
      self.indentBlankLines = try c.decodeIfPresent(Bool.self, forKey: .indentBlankLines) ?? defaults.indentBlankLines
    }

    func apply(to config: inout Configuration) {
      config.lineLength = lineLength
      config.spacesBeforeEndOfLineComments = spacesBeforeEndOfLineComments
      config.tabWidth = tabWidth
      config.indentation = indentation
      config.respectsExistingLineBreaks = respectsExistingLineBreaks
      config.lineBreakBeforeControlFlowKeywords = lineBreakBeforeControlFlowKeywords
      config.lineBreakBeforeEachArgument = lineBreakBeforeEachArgument
      config.lineBreakBeforeEachGenericRequirement = lineBreakBeforeEachGenericRequirement
      config.lineBreakBetweenDeclarationAttributes = lineBreakBetweenDeclarationAttributes
      config.prioritizeKeepingFunctionOutputTogether = prioritizeKeepingFunctionOutputTogether
      config.indentConditionalCompilationBlocks = indentConditionalCompilationBlocks
      config.lineBreakAroundMultilineExpressionChainComponents = lineBreakAroundMultilineExpressionChainComponents
      config.indentSwitchCaseLabels = indentSwitchCaseLabels
      config.spacesAroundRangeFormationOperators = spacesAroundRangeFormationOperators
      config.multilineTrailingCommaBehavior = multilineTrailingCommaBehavior
      config.multiElementCollectionTrailingCommas = multiElementCollectionTrailingCommas
      config.reflowMultilineStringLiterals = reflowMultilineStringLiterals
      config.indentBlankLines = indentBlankLines
    }

    func encode(into container: inout KeyedEncodingContainer<DynamicCodingKey>) throws {
      func key(_ name: String) -> DynamicCodingKey { DynamicCodingKey(name) }
      try container.encode(lineLength, forKey: key("lineLength"))
      try container.encode(spacesBeforeEndOfLineComments, forKey: key("spacesBeforeEndOfLineComments"))
      try container.encode(tabWidth, forKey: key("tabWidth"))
      try container.encode(indentation, forKey: key("indentation"))
      try container.encode(respectsExistingLineBreaks, forKey: key("respectsExistingLineBreaks"))
      try container.encode(lineBreakBeforeControlFlowKeywords, forKey: key("lineBreakBeforeControlFlowKeywords"))
      try container.encode(lineBreakBeforeEachArgument, forKey: key("lineBreakBeforeEachArgument"))
      try container.encode(lineBreakBeforeEachGenericRequirement, forKey: key("lineBreakBeforeEachGenericRequirement"))
      try container.encode(lineBreakBetweenDeclarationAttributes, forKey: key("lineBreakBetweenDeclarationAttributes"))
      try container.encode(prioritizeKeepingFunctionOutputTogether, forKey: key("prioritizeKeepingFunctionOutputTogether"))
      try container.encode(indentConditionalCompilationBlocks, forKey: key("indentConditionalCompilationBlocks"))
      try container.encode(lineBreakAroundMultilineExpressionChainComponents, forKey: key("lineBreakAroundMultilineExpressionChainComponents"))
      try container.encode(indentSwitchCaseLabels, forKey: key("indentSwitchCaseLabels"))
      try container.encode(spacesAroundRangeFormationOperators, forKey: key("spacesAroundRangeFormationOperators"))
      try container.encode(multilineTrailingCommaBehavior, forKey: key("multilineTrailingCommaBehavior"))
      try container.encode(multiElementCollectionTrailingCommas, forKey: key("multiElementCollectionTrailingCommas"))
      try container.encode(reflowMultilineStringLiterals, forKey: key("reflowMultilineStringLiterals"))
      try container.encode(indentBlankLines, forKey: key("indentBlankLines"))
    }

    /// The CodingKey names that correspond to settings or umbrella groups (not individual rules).
    static let keyNames: Set<String> = [
      "lineLength", "spacesBeforeEndOfLineComments", "tabWidth",
      "indentation", "respectsExistingLineBreaks", "lineBreakBeforeControlFlowKeywords",
      "lineBreakBeforeEachArgument", "lineBreakBeforeEachGenericRequirement",
      "lineBreakBetweenDeclarationAttributes", "prioritizeKeepingFunctionOutputTogether",
      "indentConditionalCompilationBlocks", "lineBreakAroundMultilineExpressionChainComponents",
      "indentSwitchCaseLabels", "spacesAroundRangeFormationOperators",
      "multilineTrailingCommaBehavior", "multiElementCollectionTrailingCommas",
      "reflowMultilineStringLiterals", "indentBlankLines",
      // Umbrella config groups (handled separately from individual rules).
      "UpdateBlankLines", "RemoveRedundant",
    ]
  }

  /// Maps rule names to the config structs they should decode into.
  private static let ruleConfigDecoders: [String: @Sendable (Decoder, inout Configuration) throws -> Void] = [
    "FileScopedDeclarationPrivacy": { d, c in c.fileScopedDeclarationPrivacy = try .init(from: d) },
    "NoAssignmentInExpressions": { d, c in c.noAssignmentInExpressions = try .init(from: d) },
    "SortImports": { d, c in c.sortImports = try .init(from: d) },
    "CapitalizeAcronyms": { d, c in c.acronyms = try .init(from: d) },
    "NoExtensionAccessLevel": { d, c in c.extensionAccessControl = try .init(from: d) },
    "PatternLetPlacement": { d, c in c.patternLet = try .init(from: d) },
    "URLMacro": { d, c in c.urlMacro = try .init(from: d) },
    "FileHeader": { d, c in c.fileHeader = try .init(from: d) },
  ]

  // MARK: - Umbrella config groups

  /// Maps umbrella config names to their sub-option→rule-name mappings.
  /// Sub-options that are `true` inherit the umbrella severity; `false` means off.
  private static let umbrellaGroups: [String: [(option: String, rule: String)]] = [
    "UpdateBlankLines": [
      ("afterGuardStatements", "BlankLinesAfterGuardStatements"),
      ("afterImports", "BlankLinesAfterImports"),
      ("afterSwitchCase", "BlankLinesAfterSwitchCase"),
      ("aroundMark", "BlankLinesAroundMark"),
      ("betweenChainedFunctions", "BlankLinesBetweenChainedFunctions"),
      ("betweenImports", "BlankLinesBetweenImports"),
      ("betweenScopes", "BlankLinesBetweenScopes"),
    ],
    "RemoveRedundant": [
      ("accessControl", "RedundantAccessControl"),
      ("async", "RedundantAsync"),
      ("backticks", "RedundantBackticks"),
      ("break", "RedundantBreak"),
      ("closure", "RedundantClosure"),
      ("equatable", "RedundantEquatable"),
      ("init", "RedundantInit"),
      ("let", "RedundantLet"),
      ("letError", "RedundantLetError"),
      ("nilInit", "RedundantNilInit"),
      ("objc", "RedundantObjc"),
      ("optionalBinding", "RedundantOptionalBinding"),
      ("pattern", "RedundantPattern"),
      ("property", "RedundantProperty"),
      ("rawValues", "RedundantRawValues"),
      ("self", "RedundantSelf"),
      ("sendable", "RedundantSendable"),
      ("staticSelf", "RedundantStaticSelf"),
      ("swiftTestingSuite", "RedundantSwiftTestingSuite"),
      ("throws", "RedundantThrows"),
      ("type", "RedundantType"),
      ("typedThrows", "RedundantTypedThrows"),
      ("viewBuilder", "RedundantViewBuilder"),
    ],
  ]

  /// Rule names managed by umbrella groups (excluded from normal encode loop).
  private static let umbrellaManagedRules: Set<String> = {
    var names = Set<String>()
    for (_, mappings) in umbrellaGroups {
      for (_, rule) in mappings { names.insert(rule) }
    }
    return names
  }()

  /// A dictionary containing the default enabled/disabled states of rules, keyed by the rules'
  /// names.
  ///
  /// This value is generated by `generate-swiftiomatic` based on the `isOptIn` value of each rule.
  public static let defaultRuleEnablements: [String: RuleSeverity] = RuleRegistry.rules

  /// The version of this configuration.
  private var version: Int = highestSupportedConfigurationVersion

  /// MARK: Common configuration

  /// The dictionary containing the rule names that we wish to run on. A rule is not used if it is
  /// marked as `false`, or if it is missing from the dictionary.
  public var rules: [String: RuleSeverity]

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

  /// MARK: Rule-specific configuration

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

  /// Determines the formal access level (i.e., the level specified in source code) for file-scoped
  /// declarations whose effective access level is private to the containing file.
  public var fileScopedDeclarationPrivacy: FileScopedDeclarationPrivacyConfiguration

  /// Determines if `case` statements should be indented compared to the containing `switch` block.
  ///
  /// When `false`, the correct form is:
  /// ```swift
  /// switch someValue {
  /// case someCase:
  ///   someStatement
  /// ...
  /// }
  /// ```
  ///
  /// When `true`, the correct form is:
  /// ```swift
  /// switch someValue {
  ///   case someCase:
  ///     someStatement
  ///   ...
  /// }
  ///```
  public var indentSwitchCaseLabels: Bool

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
  ///
  /// This setting takes precedence over `multiElementCollectionTrailingCommas`.
  /// If set to `.keptAsWritten` (the default), the formatter defers to `multiElementCollectionTrailingCommas`
  /// for collections only. In all other cases, existing trailing commas are preserved as-is and not modified.
  /// If set to `.alwaysUsed` or `.neverUsed`, that behavior is applied uniformly across all list types,
  /// regardless of `multiElementCollectionTrailingCommas`.
  public var multilineTrailingCommaBehavior: MultilineTrailingCommaBehavior

  /// Determines if multi-element collection literals should have trailing commas.
  ///
  /// When `true` (default), the correct form is:
  /// ```swift
  /// let MyCollection = [1, 2]
  /// ...
  /// let MyCollection = [
  ///   "a": 1,
  ///   "b": 2,
  /// ]
  /// ```
  ///
  /// When `false`, the correct form is:
  /// ```swift
  /// let MyCollection = [1, 2]
  /// ...
  /// let MyCollection = [
  ///   "a": 1,
  ///   "b": 2
  /// ]
  /// ```
  public var multiElementCollectionTrailingCommas: Bool

  /// Determines how multiline string literals should reflow when formatted.
  public enum MultilineStringReflowBehavior: String, Codable, Sendable {
    /// Never reflow multiline string literals.
    case never
    /// Reflow lines in string literal that exceed the maximum line length. For example with a line length of 10:
    /// ```swift
    /// """
    /// an escape\
    ///  line break
    /// a hard line break
    /// """
    /// ```
    /// will be formatted as:
    /// ```swift
    /// """
    /// an escape\
    ///  line break
    /// a hard \
    /// line break
    /// """
    /// ```
    /// The existing `\` is left in place, but the line over line length is broken.
    case onlyLinesOverLength
    /// Always reflow multiline string literals, this will ignore existing escaped newlines in the literal and reflow each line. Hard linebreaks are still respected.
    /// For example, with a line length of 10:
    /// ```swift
    /// """
    /// one \
    /// word \
    /// a line.
    /// this is too long.
    /// """
    /// ```
    /// will be formatted as:
    /// ```swift
    /// """
    /// one word \
    /// a line.
    /// this is \
    /// too long.
    /// """
    /// ```
    case always

    var isNever: Bool {
      self == .never
    }

    var isAlways: Bool {
      self == .always
    }
  }

  public var reflowMultilineStringLiterals: MultilineStringReflowBehavior

  /// Determines whether to add indentation whitespace to blank lines or remove it entirely.
  ///
  /// If true, blank lines will be modified to match the current indentation level:
  /// if they contain whitespace, the existing whitespace will be adjusted, and if they are empty, spaces will be added to match the indentation.
  /// If false (the default), the whitespace in blank lines will be removed entirely.
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.version =
      try container.decodeIfPresent(Int.self, forKey: .version)
      ?? highestSupportedConfigurationVersion
    guard version <= highestSupportedConfigurationVersion else {
      throw SwiftiomaticError.unsupportedConfigurationVersion(
        version,
        highestSupported: highestSupportedConfigurationVersion
      )
    }

    // Start from defaults; sections below override what they find.
    var config = Configuration()

    // MARK: - Decode `format` section (settings + format rules)

    var formatRuleEnablements: [String: RuleSeverity] = [:]

    if container.contains(.format) {
      // Decode typed settings (ignores unknown keys = rule names).
      let settings = try container.decode(FormatSettings.self, forKey: .format)
      settings.apply(to: &config)

      // Iterate all keys; anything not a setting key or umbrella is a rule toggle/object.
      let fmt = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .format)
      for key in fmt.allKeys where !FormatSettings.keyNames.contains(key.stringValue) {
        let ruleName = key.stringValue

        if let severity = try? fmt.decode(RuleSeverity.self, forKey: key) {
          formatRuleEnablements[ruleName] = severity
          continue
        }

        // Object value: extract `severity` and decode rule-specific options.
        let entryDecoder = try fmt.superDecoder(forKey: key)
        let entryContainer = try entryDecoder.container(keyedBy: DynamicCodingKey.self)
        formatRuleEnablements[ruleName] =
          try entryContainer.decodeIfPresent(RuleSeverity.self, forKey: DynamicCodingKey("severity")) ?? .warning

        if let decode = Self.ruleConfigDecoders[ruleName] {
          try decode(entryDecoder, &config)
        }
      }

      // MARK: Decode umbrella config groups

      for (umbrella, mappings) in Self.umbrellaGroups {
        let key = DynamicCodingKey(umbrella)
        guard fmt.contains(key) else { continue }

        let obj = try fmt.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: key)
        let severity = try obj.decodeIfPresent(RuleSeverity.self, forKey: DynamicCodingKey("severity")) ?? .warning

        // UpdateBlankLines owns maximumBlankLines.
        if umbrella == "UpdateBlankLines" {
          if let maxBlanks = try obj.decodeIfPresent(Int.self, forKey: DynamicCodingKey("maximumBlankLines")) {
            config.maximumBlankLines = maxBlanks
          }
        }

        for (option, rule) in mappings {
          let optKey = DynamicCodingKey(option)
          guard obj.contains(optKey) else { continue }
          // true → inherit severity, false → off, severity string → override.
          if let boolVal = try? obj.decode(Bool.self, forKey: optKey) {
            formatRuleEnablements[rule] = boolVal ? severity : .off
          } else if let optSeverity = try? obj.decode(RuleSeverity.self, forKey: optKey) {
            formatRuleEnablements[rule] = optSeverity
          }
        }
      }
    }

    // MARK: - Decode `lint` section (lint rules only)

    var lintRuleEnablements: [String: RuleSeverity] = [:]

    if container.contains(.lint) {
      let lint = try container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .lint)
      for key in lint.allKeys {
        if let severity = try? lint.decode(RuleSeverity.self, forKey: key) {
          lintRuleEnablements[key.stringValue] = severity
        }
      }
    }

    // Merge format + lint rules over defaults.
    for (name, severity) in formatRuleEnablements { config.rules[name] = severity }
    for (name, severity) in lintRuleEnablements { config.rules[name] = severity }
    self = config
  }


  /// Rules that have config structs, mapped to the encodable config value.
  private func ruleConfigEncodable(for ruleName: String) -> (any Encodable)? {
    switch ruleName {
    case "FileScopedDeclarationPrivacy": fileScopedDeclarationPrivacy
    case "NoAssignmentInExpressions": noAssignmentInExpressions
    case "SortImports": sortImports
    case "CapitalizeAcronyms": acronyms
    case "NoExtensionAccessLevel": extensionAccessControl
    case "PatternLetPlacement": patternLet
    case "URLMacro": urlMacro
    case "FileHeader": fileHeader
    default: nil
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(version, forKey: .version)

    // MARK: - Encode `format` section (settings + format rules)

    var fmt = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .format)
    try FormatSettings(from: self).encode(into: &fmt)

    let formatRuleNames = Set(RuleRegistry.formatRules.keys)
    for (name, severity) in rules
      where formatRuleNames.contains(name) && !Self.umbrellaManagedRules.contains(name)
    {
      if let config = ruleConfigEncodable(for: name) {
        let configData = try JSONEncoder().encode(AnyEncodable(config))
        if var configDict = try JSONSerialization.jsonObject(with: configData) as? [String: Any] {
          configDict["severity"] = severity.encodedString
          try fmt.encode(JSONFragment(configDict), forKey: DynamicCodingKey(name))
        }
      } else {
        try fmt.encode(severity, forKey: DynamicCodingKey(name))
      }
    }

    // MARK: Encode umbrella config groups

    for (umbrella, mappings) in Self.umbrellaGroups {
      var dict: [String: Any] = [:]

      // Determine umbrella severity from first active sub-rule, or .warning.
      let umbrellaSeverity: RuleSeverity = mappings
        .compactMap { rules[$0.rule] }
        .first(where: \.isActive) ?? .warning
      dict["severity"] = umbrellaSeverity.encodedString

      // UpdateBlankLines owns maximumBlankLines.
      if umbrella == "UpdateBlankLines" {
        dict["maximumBlankLines"] = maximumBlankLines
      }

      for (option, rule) in mappings {
        if let severity = rules[rule] {
          if severity == umbrellaSeverity {
            dict[option] = true
          } else if severity == .off {
            dict[option] = false
          } else {
            dict[option] = severity.encodedString
          }
        } else {
          dict[option] = false
        }
      }

      try fmt.encode(JSONFragment(dict), forKey: DynamicCodingKey(umbrella))
    }

    // MARK: - Encode `lint` section

    var lint = container.nestedContainer(keyedBy: DynamicCodingKey.self, forKey: .lint)
    let lintRuleNames = Set(RuleRegistry.lintRules.keys)
    for (name, severity) in rules where lintRuleNames.contains(name) {
      try lint.encode(severity, forKey: DynamicCodingKey(name))
    }
  }

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
    // Despite the variable's name, this value might start out first as a file path (the path to a
    // source file being formatted). However, it will immediately have its basename removed in the
    // loop below, and from then on serve as a directory path only.
    var candidateDirectory = url.absoluteURL.standardized
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: candidateDirectory.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    {
      // If the path actually was a directory, append a fake basename so that the trimming code
      // below doesn't have to deal with the first-time special case.
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

/// Configuration for the `FileScopedDeclarationPrivacy` rule.
public struct FileScopedDeclarationPrivacyConfiguration: Codable, Equatable, Sendable {
  public enum AccessLevel: String, Codable, Sendable {
    /// Private file-scoped declarations should be declared `private`.
    ///
    /// If a file-scoped declaration is declared `fileprivate`, it will be diagnosed (in lint mode)
    /// or changed to `private` (in format mode).
    case `private`

    /// Private file-scoped declarations should be declared `fileprivate`.
    ///
    /// If a file-scoped declaration is declared `private`, it will be diagnosed (in lint mode) or
    /// changed to `fileprivate` (in format mode).
    case `fileprivate`
  }

  /// The formal access level to use when encountering a file-scoped declaration with effective
  /// private access.
  public var accessLevel: AccessLevel = .private

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.accessLevel =
      try container.decodeIfPresent(AccessLevel.self, forKey: .accessLevel)
      ?? defaults.accessLevel
  }
}

/// Configuration for the `NoAssignmentInExpressions` rule.
public struct NoAssignmentInExpressionsConfiguration: Codable, Equatable, Sendable {
  /// A list of function names where assignments are allowed to be embedded in expressions that are
  /// passed as parameters to that function.
  public var allowedFunctions: [String] = [
    // Allow `XCTAssertNoThrow` because `XCTAssertNoThrow(x = try ...)` is clearer about intent than
    // `x = try XCTUnwrap(try? ...)` or force-unwrapped if you need to use the value `x` later on
    // in the test.
    "XCTAssertNoThrow"
  ]

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.allowedFunctions =
      try container.decodeIfPresent([String].self, forKey: .allowedFunctions)
      ?? defaults.allowedFunctions
  }
}

/// Configuration for the `SortImports` rule.
public struct SortImportsConfiguration: Codable, Equatable, Sendable {
  /// Determines whether imports within conditional compilation blocks should be ordered.
  public var includeConditionalImports = false
  /// Determines whether imports are separated into groups based on their type.
  public var shouldGroupImports = true

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.includeConditionalImports =
      try container.decodeIfPresent(Bool.self, forKey: .includeConditionalImports)
      ?? defaults.includeConditionalImports
    self.shouldGroupImports =
      try container.decodeIfPresent(Bool.self, forKey: .shouldGroupImports)
      ?? defaults.shouldGroupImports
  }
}

/// Configuration for the `CapitalizeAcronyms` rule.
public struct AcronymsConfiguration: Codable, Equatable, Sendable {
  /// The list of acronyms to capitalize. Each entry should be fully uppercased (e.g. "URL", "ID").
  public var words: [String] = [
    "ID", "URL", "UUID", "HTTP", "HTTPS", "JSON", "XML", "HTML",
    "API", "TCP", "UDP", "DNS", "SSH", "FTP", "SQL", "CSS",
    "RGB", "RGBA", "PDF", "GIF", "PNG", "JPEG",
  ]

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.words =
      try container.decodeIfPresent([String].self, forKey: .words)
      ?? defaults.words
  }
}

/// Configuration for the `NoExtensionAccessLevel` rule.
public struct ExtensionAccessControlConfiguration: Codable, Equatable, Sendable {
  public enum Placement: String, Codable, Sendable {
    /// Access control modifiers should be placed on individual declarations within the extension.
    ///
    /// If an extension has an access level modifier, it will be removed and applied to each member.
    case onDeclarations

    /// When all members share the same access level, it should be hoisted to the extension.
    ///
    /// If all members have the same explicit access level (`public`, `package`, or `fileprivate`),
    /// that modifier is moved to the extension and removed from individual members.
    case onExtension
  }

  /// Where access control modifiers should be placed for extensions.
  public var placement: Placement = .onDeclarations

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.placement =
      try container.decodeIfPresent(Placement.self, forKey: .placement)
      ?? defaults.placement
  }
}

/// Configuration for the `PatternLetPlacement` rule.
public struct PatternLetConfiguration: Codable, Equatable, Sendable {
  public enum Placement: String, Codable, Sendable {
    /// Each bound variable has its own `let`/`var`: `case .foo(let x, let y)`.
    case eachBinding

    /// The `let`/`var` is hoisted to the pattern level: `case let .foo(x, y)`.
    case outerPattern
  }

  /// Where `let`/`var` should be placed in case patterns.
  public var placement: Placement = .eachBinding

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = Self()
    self.placement =
      try container.decodeIfPresent(Placement.self, forKey: .placement)
      ?? defaults.placement
  }
}

/// Configuration for the `URLMacro` rule.
public struct URLMacroConfiguration: Codable, Equatable, Sendable {
  /// The macro name to use (e.g. `"#URL"`). When `nil`, the rule is inactive.
  public var macroName: String?

  /// The module to import when replacements are made (e.g. `"URLFoundation"`).
  public var moduleName: String?

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.macroName = try container.decodeIfPresent(String.self, forKey: .macroName)
    self.moduleName = try container.decodeIfPresent(String.self, forKey: .moduleName)
  }
}

/// Configuration for the `FileHeader` rule.
public struct FileHeaderConfiguration: Codable, Equatable, Sendable {
  /// The header text to enforce.
  ///
  /// - `nil` (default): rule does nothing.
  /// - `""` (empty string): clear any existing file header.
  /// - Non-empty: replace file header with this text (include `//` comment markers).
  ///
  /// Example: `"// Copyright 2024 My Company\n// All rights reserved."`
  public var text: String?

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.text = try container.decodeIfPresent(String.self, forKey: .text)
  }
}

