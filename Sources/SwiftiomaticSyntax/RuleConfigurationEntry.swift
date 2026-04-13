/// Concrete ``Codable`` struct holding rule metadata.
///
/// This is the single metadata type returned by the catalog, used by the app,
/// and serialized to JSON by the CLI. Replaces ``RuleCatalogEntry``.
public struct RuleConfigurationEntry: Sendable, Codable, Hashable, Identifiable {
  public let id: String
  public let name: String
  public let summary: String
  public let rationale: String?
  public let category: RuleCategory
  public let scope: Scope
  public let isCorrectable: Bool
  public let isOptIn: Bool
  public let isDeprecated: Bool
  public let deprecationMessage: String?
  public let requiresSourceKit: Bool
  public let requiresCompilerArguments: Bool
  public let isCrossFile: Bool
  public let canEnrichAsync: Bool
  public let examples: RuleExamples
  public let configurationOptions: [ConfigOptionDescriptor]
  public let relatedRuleIDs: [String]

  public init(
    id: String,
    name: String,
    summary: String,
    rationale: String? = nil,
    category: RuleCategory = .uncategorized,
    scope: Scope,
    isCorrectable: Bool = false,
    isOptIn: Bool = false,
    isDeprecated: Bool = false,
    deprecationMessage: String? = nil,
    requiresSourceKit: Bool = false,
    requiresCompilerArguments: Bool = false,
    isCrossFile: Bool = false,
    canEnrichAsync: Bool = false,
    examples: RuleExamples = RuleExamples(),
    configurationOptions: [ConfigOptionDescriptor] = [],
    relatedRuleIDs: [String] = [],
  ) {
    self.id = id
    self.name = name
    self.summary = summary
    self.rationale = rationale
    self.category = category
    self.scope = scope
    self.isCorrectable = isCorrectable
    self.isOptIn = isOptIn
    self.isDeprecated = isDeprecated
    self.deprecationMessage = deprecationMessage
    self.requiresSourceKit = requiresSourceKit
    self.requiresCompilerArguments = requiresCompilerArguments
    self.isCrossFile = isCrossFile
    self.canEnrichAsync = canEnrichAsync
    self.examples = examples
    self.configurationOptions = configurationOptions
    self.relatedRuleIDs = relatedRuleIDs
  }
}
