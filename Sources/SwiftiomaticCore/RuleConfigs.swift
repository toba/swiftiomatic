/// Configuration for the `FileScopedDeclarationPrivacy` rule.
public struct FileScopedDeclarationPrivacyConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "FileScopedDeclarationPrivacy"
  public static let configProperties: [ConfigProperty] = [
    .init("accessLevel", .stringEnum(
      description: "Access level for file-scoped private declarations.",
      values: ["private", "fileprivate"], defaultValue: "private")),
  ]

  public enum AccessLevel: String, Codable, Sendable {
    case `private`
    case `fileprivate`
  }

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
public struct NoAssignmentInExpressionsConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "NoAssignmentInExpressions"
  public static let configProperties: [ConfigProperty] = [
    .init("allowedFunctions", .stringArray(
      description: "Functions where embedded assignments are allowed.",
      defaultValue: ["XCTAssertNoThrow"])),
  ]

  public var allowedFunctions: [String] = ["XCTAssertNoThrow"]

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
public struct SortImportsConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "SortImports"
  public static let configProperties: [ConfigProperty] = [
    .init("includeConditionalImports", .bool(description: "Sort imports within #if blocks.", defaultValue: false)),
    .init("shouldGroupImports", .bool(description: "Separate imports into groups by type.", defaultValue: true)),
  ]

  public var includeConditionalImports = false
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
public struct AcronymsConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "CapitalizeAcronyms"
  public static let configProperties: [ConfigProperty] = [
    .init("words", .stringArray(
      description: "Acronyms to capitalize (fully uppercased).",
      defaultValue: [
        "API", "CSS", "DNS", "FTP", "GIF", "HTML", "HTTP", "HTTPS",
        "ID", "JPEG", "JSON", "PDF", "PNG", "RGB", "RGBA",
        "SQL", "SSH", "TCP", "UDP", "URL", "UUID", "XML",
      ])),
  ]
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
public struct ExtensionAccessControlConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "NoExtensionAccessLevel"
  public static let configProperties: [ConfigProperty] = [
    .init("placement", .stringEnum(
      description: "Where to place access control modifiers.",
      values: ["onDeclarations", "onExtension"], defaultValue: "onDeclarations")),
  ]
  public enum Placement: String, Codable, Sendable {
    case onDeclarations
    case onExtension
  }

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
public struct PatternLetConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "PatternLetPlacement"
  public static let configProperties: [ConfigProperty] = [
    .init("placement", .stringEnum(
      description: "Where to place let/var in case patterns.",
      values: ["eachBinding", "outerPattern"], defaultValue: "eachBinding")),
  ]
  public enum Placement: String, Codable, Sendable {
    case eachBinding
    case outerPattern
  }

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
public struct URLMacroConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "URLMacro"
  public static let configProperties: [ConfigProperty] = [
    .init("macroName", .string(description: "Macro name, e.g. \"#URL\". Omit to disable.")),
    .init("moduleName", .string(description: "Module to import for the macro.")),
  ]
  public var macroName: String?
  public var moduleName: String?

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.macroName = try container.decodeIfPresent(String.self, forKey: .macroName)
    self.moduleName = try container.decodeIfPresent(String.self, forKey: .moduleName)
  }
}

/// Configuration for the `FileHeader` rule.
public struct FileHeaderConfiguration: Codable, Equatable, Sendable, ConfigRepresentable {
  public static let ruleName = "FileHeader"
  public static let configProperties: [ConfigProperty] = [
    .init("text", .string(description: "Header text. Omit to disable, empty string to remove headers.")),
  ]
  public var text: String?

  public init() {}

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.text = try container.decodeIfPresent(String.self, forKey: .text)
  }
}

/// Rule config schemas keyed by rule name, for the schema generator.
public enum RuleConfigSchemas {
  public static let schemas: [String: [ConfigProperty]] = {
    let entries: [(String, [ConfigProperty])] = [
      (FileScopedDeclarationPrivacyConfiguration.ruleName, FileScopedDeclarationPrivacyConfiguration.configProperties),
      (NoAssignmentInExpressionsConfiguration.ruleName, NoAssignmentInExpressionsConfiguration.configProperties),
      (SortImportsConfiguration.ruleName, SortImportsConfiguration.configProperties),
      (AcronymsConfiguration.ruleName, AcronymsConfiguration.configProperties),
      (ExtensionAccessControlConfiguration.ruleName, ExtensionAccessControlConfiguration.configProperties),
      (PatternLetConfiguration.ruleName, PatternLetConfiguration.configProperties),
      (URLMacroConfiguration.ruleName, URLMacroConfiguration.configProperties),
      (FileHeaderConfiguration.ruleName, FileHeaderConfiguration.configProperties),
    ]
    return Dictionary(uniqueKeysWithValues: entries)
  }()
}
