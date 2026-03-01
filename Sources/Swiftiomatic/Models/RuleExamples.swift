/// Unified container for rule examples, supporting both lint-style structured examples
/// and format-style markdown diffs.
public struct RuleExamples: Sendable, Codable, Hashable {
    /// Examples of code that does not trigger this rule
    public let nonTriggering: [CodeExample]

    /// Examples of code that triggers one or more violations
    public let triggering: [CodeExample]

    /// Before/after pairs showing how corrections are applied
    public let corrections: [CorrectionExample]

    /// Markdown-formatted diff showing format rule transformations (format rules only)
    public let diffMarkdown: String?

    public init(
        nonTriggering: [CodeExample] = [],
        triggering: [CodeExample] = [],
        corrections: [CorrectionExample] = [],
        diffMarkdown: String? = nil,
    ) {
        self.nonTriggering = nonTriggering
        self.triggering = triggering
        self.corrections = corrections
        self.diffMarkdown = diffMarkdown
    }

    /// An empty container with no examples
    public static let empty = RuleExamples()

    /// Whether this container has any examples at all
    public var isEmpty: Bool {
        nonTriggering.isEmpty && triggering.isEmpty && corrections.isEmpty && diffMarkdown == nil
    }
}

/// A single code example with optional configuration context
public struct CodeExample: Sendable, Codable, Hashable {
    /// The Swift source code of this example
    public let code: String

    /// Optional configuration that was applied when this example triggers/doesn't trigger
    public let configuration: [String: String]?

    public init(code: String, configuration: [String: String]? = nil) {
        self.code = code
        self.configuration = configuration
    }
}

/// A before/after correction pair
public struct CorrectionExample: Sendable, Codable, Hashable {
    /// The code before the correction is applied
    public let before: String

    /// The code after the correction is applied
    public let after: String

    public init(before: String, after: String) {
        self.before = before
        self.after = after
    }
}
