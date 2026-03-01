/// Unified protocol exposing all rule metadata regardless of rule engine.
///
/// Adapters bridge existing ``Rule`` and ``FormatRule`` types into this protocol,
/// providing a single interface for documentation, YAML configuration, and app UX.
///
/// Concrete per-rule types (e.g. `RedundantVoidReturnConfiguration`) conform to
/// this protocol. Most properties have sensible defaults so minimal types only
/// need ``id``, ``name``, and ``summary``.
public protocol RuleConfiguration: Sendable, Identifiable where ID == String {
    /// The rule's unique identifier (e.g. "trailing_whitespace" or "redundantSelf")
    var id: String { get }

    /// Human-readable display name
    var name: String { get }

    /// Brief description of what the rule checks or formats
    var summary: String { get }

    /// Detailed rationale in Markdown, or `nil` if none
    var rationale: String? { get }

    /// Where the rule participates: `.lint`, `.format`, or `.suggest`
    var scope: Scope { get }

    /// Whether the rule can automatically fix violations
    var isCorrectable: Bool { get }

    /// Whether the rule is opt-in (not enabled by default)
    var isOptIn: Bool { get }

    /// Whether the rule is deprecated
    var isDeprecated: Bool { get }

    /// Deprecation message, or `nil` if not deprecated
    var deprecationMessage: String? { get }

    /// Whether the rule requires SourceKit to operate
    var requiresSourceKit: Bool { get }

    /// Whether the rule requires compiler arguments (analyzer rules)
    var requiresCompilerArguments: Bool { get }

    /// Whether the rule performs cross-file analysis (``CollectingRule``)
    var isCrossFile: Bool { get }

    /// Whether the rule can produce additional violations via async enrichment
    var canEnrichAsync: Bool { get }

    /// Structured examples for this rule
    var examples: RuleExamples { get }

    /// Configurable options exposed by this rule
    var configurationOptions: [ConfigOptionDescriptor] { get }

    /// Identifiers of related rules
    var relatedRuleIDs: [String] { get }

    // MARK: - Internal metadata (replaces RuleDescription fields)

    /// Previous identifiers for this rule, used for backwards-compatible disable commands
    var deprecatedAliases: Set<String> { get }

    /// The oldest Swift version supported by this rule
    var minSwiftVersion: SwiftVersion { get }

    /// Whether the rule requires its file to exist on disk
    var requiresFileOnDisk: Bool { get }

    /// Raw non-triggering examples with test metadata
    var nonTriggeringExamples: [Example] { get }

    /// Raw triggering examples with test metadata
    var triggeringExamples: [Example] { get }

    /// Raw correction pairs with test metadata
    var corrections: [Example: Example] { get }

    /// All identifiers (current + deprecated) this rule responds to
    var allIdentifiers: [String] { get }
}

// MARK: - Defaults

extension RuleConfiguration {
    public var rationale: String? { nil }
    public var scope: Scope { .lint }
    public var isCorrectable: Bool { false }
    public var isOptIn: Bool { false }
    public var isDeprecated: Bool { false }
    public var deprecationMessage: String? { nil }
    public var requiresSourceKit: Bool { false }
    public var requiresCompilerArguments: Bool { false }
    public var isCrossFile: Bool { false }
    public var canEnrichAsync: Bool { false }
    public var configurationOptions: [ConfigOptionDescriptor] { [] }
    public var relatedRuleIDs: [String] { [] }
    public var deprecatedAliases: Set<String> { [] }
    public var minSwiftVersion: SwiftVersion { .v6 }
    public var requiresFileOnDisk: Bool { false }
    public var nonTriggeringExamples: [Example] { [] }
    public var triggeringExamples: [Example] { [] }
    public var corrections: [Example: Example] { [:] }

    public var allIdentifiers: [String] {
        Array(deprecatedAliases) + [id]
    }

    /// Default `examples` computed from raw example arrays
    public var examples: RuleExamples {
        RuleExamples(
            nonTriggering: nonTriggeringExamples.map { CodeExample(code: $0.code) },
            triggering: triggeringExamples.map { CodeExample(code: $0.code) },
            corrections: corrections.map { CorrectionExample(before: $0.key.code, after: $0.value.code) },
        )
    }
}
