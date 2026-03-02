import Foundation

/// An executable value that can identify issues (violations) in Swift source code
public protocol Rule: Sendable {
    /// The type of the configuration used to configure this rule
    associatedtype OptionsType: RuleOptions

    // MARK: - Required metadata (dispatches dynamically through existentials)

    /// The rule's unique identifier (e.g. "trailing_whitespace")
    static var id: String { get }

    /// Human-readable display name
    static var name: String { get }

    /// Brief description of what the rule checks or formats
    static var summary: String { get }

    /// Previous identifiers for this rule, used for backwards-compatible disable commands
    static var deprecatedAliases: Set<String> { get }

    /// Whether the rule is opt-in (not enabled by default)
    static var isOptIn: Bool { get }

    /// Where the rule participates: `.lint`, `.format`, or `.suggest`
    static var scope: Scope { get }

    /// Whether the rule is deprecated
    static var isDeprecated: Bool { get }

    /// Deprecation message, or `nil` if not deprecated
    static var deprecationMessage: String? { get }

    /// Detailed rationale in Markdown, or `nil` if none
    static var rationale: String? { get }

    /// Whether the rule requires SourceKit to operate
    static var requiresSourceKit: Bool { get }

    /// Whether the rule requires compiler arguments (analyzer rules)
    static var requiresCompilerArguments: Bool { get }

    /// The oldest Swift version supported by this rule
    static var minSwiftVersion: SwiftVersion { get }

    /// Whether the rule requires its file to exist on disk
    static var requiresFileOnDisk: Bool { get }

    /// Configurable options exposed by this rule
    static var configurationOptions: [ConfigOptionDescriptor] { get }

    /// Identifiers of related rules
    static var relatedRuleIDs: [String] { get }

    /// Raw non-triggering examples with test metadata
    static var nonTriggeringExamples: [Example] { get }

    /// Raw triggering examples with test metadata
    static var triggeringExamples: [Example] { get }

    /// Raw correction pairs with test metadata
    static var corrections: [Example: Example] { get }

    // MARK: - Runtime

    /// This rule's configuration
    var options: OptionsType { get set }

    /// Whether this rule should be used on empty files, defaults to `false`
    var shouldLintEmptyFiles: Bool { get }

    /// A default initializer for rules; all rules need to be trivially initializable
    init()

    /// Create a rule by applying its configuration
    ///
    /// - Parameters:
    ///   - configuration: The untyped configuration value to apply.
    /// - Throws: ``SwiftiomaticError`` if the configuration didn't match the expected format.
    init(configuration: Any) throws

    /// Create a description of how this rule has been configured to run
    ///
    /// - Parameters:
    ///   - exclusiveOptions: A set of options that should be excluded from the description.
    /// - Returns: A description of the rule's configuration.
    func createConfigurationDescription(exclusiveOptions: Set<String>)
        -> RuleOptionsDescription

    /// Execute the rule on a file and return any violations
    ///
    /// - Parameters:
    ///   - file: The file for which to execute the rule.
    ///   - compilerArguments: The compiler arguments needed to compile this file.
    /// - Returns: All style violations to the rule's expectations.
    func validate(file: SwiftSource, compilerArguments: [String]) -> [RuleViolation]

    /// Execute the rule on a file and return any violations
    ///
    /// - Parameters:
    ///   - file: The file for which to execute the rule.
    /// - Returns: All style violations to the rule's expectations.
    func validate(file: SwiftSource) -> [RuleViolation]

    /// Check whether the specified rule is equivalent to the current rule
    ///
    /// - Parameters:
    ///   - rule: The rule value to compare against.
    /// - Returns: Whether the specified rule is equivalent to the current rule.
    func isEqualTo(_ rule: some Rule) -> Bool

    /// Collect information for the specified file into a storage object
    ///
    /// Called by the linter; always implemented in extensions.
    ///
    /// - Parameters:
    ///   - file: The file for which to collect info.
    ///   - storage: The storage object where collected info should be saved.
    ///   - compilerArguments: The compiler arguments needed to compile this file.
    func collectInfo(
        for file: SwiftSource,
        into storage: RuleStorage,
        compilerArguments: [String],
    )

    /// Validate a file after collecting file info for all files
    ///
    /// Called by the linter; always implemented in extensions.
    ///
    /// - Parameters:
    ///   - file: The file for which to execute the rule.
    ///   - storage: The storage object containing all collected info.
    ///   - compilerArguments: The compiler arguments needed to compile this file.
    /// - Returns: All style violations to the rule's expectations.
    func validate(file: SwiftSource, using storage: RuleStorage, compilerArguments: [String])
        -> [RuleViolation]

    /// Check if a style violation can be disabled by a command specifying a rule ID
    ///
    /// Only the rule can claim that for sure since it knows all the possible identifiers.
    ///
    /// - Parameters:
    ///   - violation: A style violation.
    ///   - ruleID: The name of a rule as used in a disable command.
    /// - Returns: A boolean value indicating whether the violation can be disabled by the given ID.
    func canBeDisabled(violation: RuleViolation, by ruleID: RuleIdentifier) -> Bool

    /// Check if the rule is enabled in a given region
    ///
    /// - Parameters:
    ///   - region: The region to check.
    ///   - ruleID: Rule identifier deviating from the default rule's name.
    /// - Returns: A boolean value indicating whether the rule is enabled in the given region.
    func isEnabled(in region: Region, for ruleID: String) -> Bool
}

// MARK: - Metadata defaults

extension Rule {
    static var rationale: String? { nil }
    static var scope: Scope { .lint }
    static var isCorrectable: Bool { false }
    static var isOptIn: Bool { false }
    static var isDeprecated: Bool { false }
    static var deprecationMessage: String? { nil }
    static var requiresSourceKit: Bool { false }
    static var requiresCompilerArguments: Bool { false }
    static var isCrossFile: Bool { false }
    static var canEnrichAsync: Bool { false }
    static var configurationOptions: [ConfigOptionDescriptor] { [] }
    static var relatedRuleIDs: [String] { [] }
    static var deprecatedAliases: Set<String> { [] }
    static var minSwiftVersion: SwiftVersion { .v6 }
    static var requiresFileOnDisk: Bool { false }
    static var nonTriggeringExamples: [Example] { [] }
    static var triggeringExamples: [Example] { [] }
    static var corrections: [Example: Example] { [:] }

    /// All identifiers (current + deprecated) this rule responds to
    static var allIdentifiers: [String] {
        Array(deprecatedAliases) + [id]
    }

    /// Structured examples for this rule
    static var examples: RuleExamples {
        RuleExamples(
            nonTriggering: nonTriggeringExamples.map { CodeExample(code: $0.code) },
            triggering: triggeringExamples.map { CodeExample(code: $0.code) },
            corrections: corrections.map { CorrectionExample(before: $0.key.code, after: $0.value.code) },
        )
    }
}

// MARK: - Default implementations

extension Rule {
    var shouldLintEmptyFiles: Bool {
        false
    }

    init(configuration: Any) throws {
        self.init()
        let normalized: [String: Any]
        if let dict = configuration as? [String: Any] {
            normalized = dict
        } else if let string = configuration as? String {
            normalized = ["severity": string]
        } else {
            throw SwiftiomaticError.invalidConfiguration(ruleID: Self.identifier)
        }
        try self.options.apply(configuration: normalized)
    }

    func validate(file: SwiftSource, using _: RuleStorage, compilerArguments: [String])
        -> [RuleViolation]
    {
        validate(file: file, compilerArguments: compilerArguments)
    }

    func validate(file: SwiftSource, compilerArguments _: [String]) -> [RuleViolation] {
        validate(file: file)
    }

    func isEqualTo(_ rule: some Rule) -> Bool {
        if let rule = rule as? Self {
            return options == rule.options
        }
        return false
    }

    func collectInfo(for _: SwiftSource, into _: RuleStorage, compilerArguments _: [String]) {
        // no-op: only CollectingRules mutate their storage
    }

    /// A string fingerprint of this rule's configuration used for cache invalidation
    var cacheDescription: String {
        createConfigurationDescription().oneLiner()
    }

    func createConfigurationDescription(exclusiveOptions: Set<String> = [])
        -> RuleOptionsDescription
    {
        RuleOptionsDescription.from(
            configuration: options, exclusiveOptions: exclusiveOptions,
        )
    }

    func canBeDisabled(violation: RuleViolation, by ruleID: RuleIdentifier) -> Bool {
        switch ruleID {
            case .all:
                true
            case let .single(identifier: id):
                Self.allIdentifiers.contains(id)
                    && Self.allIdentifiers.contains(violation.ruleIdentifier)
        }
    }

    func isEnabled(in region: Region, for ruleID: String) -> Bool {
        !Self.allIdentifiers.contains(ruleID) || region.isRuleEnabled(self)
    }
}

// MARK: - Computed aliases (for backward compatibility and convenience)

extension Rule {
    /// The rule's unique identifier (alias for ``id``)
    static var identifier: String { id }

    /// Human-readable display name (alias for ``name``)
    static var ruleName: String { name }

    /// Brief description (alias for ``summary``)
    static var ruleSummary: String { summary }

    /// Detailed rationale in Markdown (alias for ``rationale``)
    static var ruleRationale: String? { rationale }

    /// Previous identifiers (alias for ``deprecatedAliases``)
    static var ruleDeprecatedAliases: Set<String> { deprecatedAliases }

    /// Whether this rule requires compiler arguments (alias for ``requiresCompilerArguments``)
    static var runsWithCompilerArguments: Bool { requiresCompilerArguments }

    /// Whether this rule requires SourceKit (alias for ``requiresSourceKit``)
    static var runsWithSourceKit: Bool { requiresSourceKit }

    /// Scope (alias for ``scope``)
    static var ruleScope: Scope { scope }

    /// The oldest Swift version (alias for ``minSwiftVersion``)
    static var ruleMinSwiftVersion: SwiftVersion { minSwiftVersion }

    /// Non-triggering examples (alias for ``nonTriggeringExamples``)
    static var ruleNonTriggeringExamples: [Example] { nonTriggeringExamples }

    /// Triggering examples (alias for ``triggeringExamples``)
    static var ruleTriggeringExamples: [Example] { triggeringExamples }

    /// Correction pairs (alias for ``corrections``)
    static var ruleCorrections: [Example: Example] { corrections }
}

/// A rule that is not enabled by default and must be explicitly enabled by users
///
/// - Note: Deprecated. Use `Rule.isOptIn` instead. This protocol remains
///   for backward compatibility but is no longer checked at runtime.
protocol OptInRule: Rule {}

/// A rule that can correct violations
public protocol CorrectableRule: Rule {
    /// Attempt to correct violations in the specified file
    ///
    /// - Parameters:
    ///   - file: The file for which to correct violations.
    ///   - compilerArguments: The compiler arguments needed to compile this file.
    /// - Returns: Number of corrections that were applied.
    func correct(file: SwiftSource, compilerArguments: [String]) -> Int

    /// Attempt to correct violations in the specified file
    ///
    /// - Parameters:
    ///   - file: The file for which to correct violations.
    /// - Returns: Number of corrections that were applied.
    func correct(file: SwiftSource) -> Int

    /// Correct violations after collecting file info for all files
    ///
    /// Called by the linter; always implemented in extensions.
    ///
    /// - Parameters:
    ///   - file: The file for which to execute the rule.
    ///   - storage: The storage object containing all collected info.
    ///   - compilerArguments: The compiler arguments needed to compile this file.
    /// - Returns: All corrections that were applied.
    func correct(file: SwiftSource, using storage: RuleStorage, compilerArguments: [String])
        -> Int
}

extension CorrectableRule {
    func correct(file: SwiftSource, compilerArguments _: [String]) -> Int {
        correct(file: file)
    }

    func correct(file: SwiftSource, using _: RuleStorage, compilerArguments: [String]) -> Int {
        correct(file: file, compilerArguments: compilerArguments)
    }
}

/// A correctable rule that applies corrections by replacing ranges in the offending file
protocol SubstitutionCorrectableRule: CorrectableRule {
    /// Return the ranges that violate this rule and should be replaced
    ///
    /// - Parameters:
    ///   - file: The file in which to find ranges of violations for this rule.
    /// - Returns: The ranges to be replaced in the specified file.
    func violationRanges(in file: SwiftSource) -> [Range<String.Index>]

    /// Return the substitution to apply for the given violation range
    ///
    /// - Parameters:
    ///   - violationRange: The range of the violation that should be replaced.
    ///   - file: The file in which the violation should be replaced.
    /// - Returns: The range of the correction and its contents, if one could be computed.
    func substitution(for violationRange: Range<String.Index>, in file: SwiftSource)
        -> (Range<String.Index>, String)?
}

extension SubstitutionCorrectableRule {
    func correct(file: SwiftSource) -> Int {
        let violatingRanges = file.ruleEnabled(
            violatingRanges: violationRanges(in: file),
            for: self,
        )
        guard violatingRanges.isNotEmpty else {
            return 0
        }
        var numberOfCorrections = 0
        var contents = file.contents
        for range in violatingRanges.sorted(by: { $0.lowerBound > $1.lowerBound }) {
            if let (rangeToRemove, substitution) = substitution(for: range, in: file) {
                contents.replaceSubrange(rangeToRemove, with: substitution)
                numberOfCorrections += 1
            }
        }

        file.write(contents)
        return numberOfCorrections
    }
}

/// :nodoc:
extension [any Rule] {
    static func == (lhs: Array, rhs: Array) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return !zip(lhs, rhs).contains { pair in
            let first = pair.0
            let second = pair.1
            return !first.isEqualTo(second)
        }
    }
}

/// A rule that operates purely on SwiftSyntax and does not require SourceKit
///
/// - Note: Deprecated. Use `Rule.requiresSourceKit` instead. This protocol
///   remains for backward compatibility with ``SwiftSyntaxRule``.
protocol SyntaxOnlyRule: Rule {}

extension Rule {
    /// Whether this rule requires SourceKit to operate
    var requiresSourceKit: Bool {
        Self.runsWithSourceKit
    }
}

/// A rule that can produce additional violations via async SourceKit enrichment
///
/// After the synchronous ``Rule/validate(file:)`` pass, the ``Analyzer`` calls
/// ``enrich(file:typeResolver:)`` for conforming rules when a ``TypeResolver``
/// is available. This allows rules to resolve types, check USRs, or query
/// expression types to upgrade confidence or add findings that require semantic
/// information.
///
/// The protocol is additive -- it does not change the synchronous
/// ``Rule/validate(file:)`` contract.
protocol AsyncEnrichableRule: Rule {
    /// Produce additional violations by resolving types via SourceKit
    ///
    /// Called after ``Rule/validate(file:)`` when a ``TypeResolver`` is available.
    /// Returns only the *new* violations discovered through async enrichment;
    /// the ``Analyzer`` merges them with the synchronous results.
    ///
    /// - Parameters:
    ///   - file: The file being analyzed.
    ///   - typeResolver: A connected SourceKit type resolver.
    /// - Returns: Additional violations found through type resolution.
    func enrich(
        file: SwiftSource,
        typeResolver: any TypeResolver,
    ) async -> [RuleViolation]
}

/// A rule that operates on the post-typechecked AST using compiler arguments
///
/// Analyzer rules perform checks that are more like static analysis than
/// syntactic checks. They are always opt-in and require compiler arguments.
/// Set `isOptIn = true` and `requiresCompilerArguments = true` as static
/// properties on the rule.
protocol AnalyzerRule: Rule {}

extension AnalyzerRule {
    func validate(file _: SwiftSource) -> [RuleViolation] {
        Console.fatalError("Must call `validate(file:compilerArguments:)` for AnalyzerRule")
    }
}

/// :nodoc:
extension AnalyzerRule where Self: CorrectableRule {
    func correct(file _: SwiftSource) -> Int {
        Console.fatalError("Must call `correct(file:compilerArguments:)` for AnalyzerRule")
    }
}
