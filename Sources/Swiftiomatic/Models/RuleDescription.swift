import Foundation

/// A detailed description for a rule. Used for both documentation and testing purposes.
public struct RuleDescription: Equatable, Sendable {
    /// The rule's unique identifier, to be used in configuration files and commands.
    /// Should be short and only comprised of lowercase latin alphabet letters and underscores formatted in snake case.
    public let identifier: String

    /// The rule's human-readable name. Should be short, descriptive and formatted in Title Case. May contain spaces.
    public let name: String

    /// The rule's verbose description. Should read as a sentence or short paragraph. Good things to include are an
    /// explanation of the rule's purpose and rationale.
    public let description: String

    /// A longer explanation of the rule's purpose and rationale. Typically defined as a multiline string, long text
    /// lines should be wrapped. Markdown formatting is supported. Multiline code blocks will be formatted as
    /// `swift` code unless otherwise specified, and will automatically be indented by four spaces when printed
    /// to the console.
    public let rationale: String?

    /// Where this rule participates in the analysis pipeline.
    public let scope: Scope

    /// Swift source examples that do not trigger a violation for this rule.
    let nonTriggeringExamples: [Example]

    /// Swift source examples that do trigger one or more violations for this rule.
    let triggeringExamples: [Example]

    /// Pairs of Swift source examples, where keys are examples that trigger violations for this rule, and the values
    /// are the expected value after applying corrections with the rule.
    let corrections: [Example: Example]

    /// Any previous iteration of the rule's identifier that was previously shipped.
    let deprecatedAliases: Set<String>

    /// The oldest version of the Swift compiler supported by this rule.
    let minSwiftVersion: SwiftVersion

    /// Whether or not this rule can only be executed on a file physically on-disk. Typically necessary for rules
    /// that require compiler arguments.
    let requiresFileOnDisk: Bool

    /// Whether this rule is opt-in (not enabled by default).
    public let isOptIn: Bool

    /// Whether this rule operates purely on SwiftSyntax and does not require SourceKit.
    public let requiresSourceKit: Bool

    /// Whether this rule requires compiler arguments to operate.
    public let requiresCompilerArguments: Bool

    /// Whether this rule has corrections defined.
    public var isCorrectable: Bool {
        !corrections.isEmpty
    }

    /// The console-printable string for this description.
    var consoleDescription: String {
        "\(name) (\(identifier)): \(description)"
    }

    /// The console-printable rationale for this description.
    var consoleRationale: String? {
        rationale?.consoleRationale
    }

    /// The rationale for this description, with Markdown formatting.
    var formattedRationale: String? {
        rationale?.formattedRationale
    }

    /// All identifiers that have been used to uniquely identify this rule in past and current versions.
    var allIdentifiers: [String] {
        Array(deprecatedAliases) + [identifier]
    }

    /// Creates a `RuleDescription` by specifying all its properties directly.
    ///
    /// - Parameters:
    ///   - identifier:               Sets the description's `identifier` property.
    ///   - name:                     Sets the description's `name` property.
    ///   - description:              Sets the description's `description` property.
    ///   - rationale:                Sets the description's `rationale` property.
    ///   - scope:                    Sets the description's `scope` property.
    ///   - isOptIn:                  Whether this rule is opt-in (not enabled by default).
    ///   - requiresSourceKit:        Whether this rule requires SourceKit to operate.
    ///   - requiresCompilerArguments: Whether this rule requires compiler arguments.
    ///   - minSwiftVersion:          Sets the description's `minSwiftVersion` property.
    ///   - nonTriggeringExamples:    Sets the description's `nonTriggeringExamples` property.
    ///   - triggeringExamples:       Sets the description's `triggeringExamples` property.
    ///   - corrections:              Sets the description's `corrections` property.
    ///   - deprecatedAliases:        Sets the description's `deprecatedAliases` property.
    ///   - requiresFileOnDisk:       Sets the description's `requiresFileOnDisk` property.
    public init(
        identifier: String,
        name: String,
        description: String,
        rationale: String? = nil,
        scope: Scope = .lint,
        isOptIn: Bool = false,
        requiresSourceKit: Bool = false,
        requiresCompilerArguments: Bool = false,
        minSwiftVersion: SwiftVersion = .v6,
        nonTriggeringExamples: [Example] = [],
        triggeringExamples: [Example] = [],
        corrections: [Example: Example] = [:],
        deprecatedAliases: Set<String> = [],
        requiresFileOnDisk: Bool = false,
    ) {
        self.identifier = identifier
        self.name = name
        self.description = description
        self.rationale = rationale
        self.scope = scope
        self.isOptIn = isOptIn
        self.requiresSourceKit = requiresSourceKit
        self.requiresCompilerArguments = requiresCompilerArguments
        self.nonTriggeringExamples = nonTriggeringExamples
        self.triggeringExamples = triggeringExamples
        self.corrections = corrections
        self.deprecatedAliases = deprecatedAliases
        self.minSwiftVersion = minSwiftVersion
        self.requiresFileOnDisk = requiresFileOnDisk
    }

    // MARK: Equatable

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

// MARK: - Bridge to RuleConfiguration

/// Wraps a ``RuleDescription`` to conform to ``RuleConfiguration``.
///
/// Used as the default `ConfigurationType` during migration. Rules that have
/// not yet moved to a dedicated `[Name]Configuration` struct get this adapter
/// automatically via the default `Rule.configuration` implementation.
public struct RuleDescriptionAdapter: RuleConfiguration {
    private let desc: RuleDescription
    private let _isCorrectable: Bool
    private let _isCrossFile: Bool
    private let _canEnrichAsync: Bool

    init(_ desc: RuleDescription, isCorrectable: Bool = false, isCrossFile: Bool = false, canEnrichAsync: Bool = false) {
        self.desc = desc
        self._isCorrectable = isCorrectable
        self._isCrossFile = isCrossFile
        self._canEnrichAsync = canEnrichAsync
    }

    public var id: String { desc.identifier }
    public var name: String { desc.name }
    public var summary: String { desc.description }
    public var rationale: String? { desc.rationale }
    public var scope: Scope { desc.scope }
    public var isCorrectable: Bool { _isCorrectable || desc.isCorrectable }
    public var isOptIn: Bool { desc.isOptIn }
    public var requiresSourceKit: Bool { desc.requiresSourceKit }
    public var requiresCompilerArguments: Bool { desc.requiresCompilerArguments }
    public var isCrossFile: Bool { _isCrossFile }
    public var canEnrichAsync: Bool { _canEnrichAsync }
}

private extension String {
    var formattedRationale: String {
        formattedRationale(forConsole: false)
    }

    var consoleRationale: String {
        formattedRationale(forConsole: true)
    }

    private func formattedRationale(forConsole: Bool) -> String {
        var insideMultilineString = false
        return components(separatedBy: "\n").compactMap { line -> String? in
            if line.contains("```") {
                if insideMultilineString {
                    insideMultilineString = false
                    return forConsole ? nil : line
                }
                insideMultilineString = true
                if line.hasSuffix("```") {
                    return forConsole ? nil : (line + "swift")
                }
            }
            return line.indent(by: (insideMultilineString && forConsole) ? 4 : 0)
        }.joined(separator: "\n")
    }
}
