/// Where a rule participates in the analysis pipeline.
public enum Scope: String, CaseIterable, Codable, Sendable {
    /// Definitive checks — wrong code, anti-patterns, style violations.
    case lint
    /// Formatting only — whitespace, indentation, brace placement.
    case format
    /// Research patterns for agent investigation.
    case suggest

    /// Human-readable display name for text output.
    public var displayName: String {
        switch self {
            case .lint: "Lint"
            case .format: "Format"
            case .suggest: "Suggestions"
        }
    }
}
