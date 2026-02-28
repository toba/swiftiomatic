/// All the possible rule kinds (categories).
enum RuleKind: String, CaseIterable, Codable, Sendable {
    /// Describes rules that validate Swift source conventions.
    case lint
    /// Describes rules that validate common practices in the Swift community.
    case idiomatic
    /// Describes rules that validate stylistic choices.
    case style
    /// Describes rules that validate magnitudes or measurements of Swift source.
    case metrics
    /// Describes rules that validate that code patterns with poor performance are avoided.
    case performance
    /// Describes rules from the suggest engine (deep AST analysis).
    case suggest
    /// Describes rules that validate concurrency patterns.
    case concurrency
    /// Describes rules that validate Observation framework usage.
    case observation

    /// Human-readable display name for text output.
    var displayName: String {
        switch self {
            case .lint: "Lint"
            case .idiomatic: "Idiomatic Swift"
            case .style: "Style"
            case .metrics: "Metrics"
            case .performance: "Performance"
            case .suggest: "Suggestions"
            case .concurrency: "Concurrency"
            case .observation: "Observation"
        }
    }
}
