/// The 8 analysis categories matching the swift-review skill sections.
enum Category: String, Codable, CaseIterable, Sendable {
    case anyElimination = "any-elimination"
    case typedThrows = "typed-throws"
    case concurrencyModernization = "concurrency"
    case swift62Modernization = "swift-6.2"
    case performanceAntiPatterns = "performance"
    case namingHeuristics = "naming"
    case observationPitfalls = "observation"
    case agentReview = "agent-review"

    /// Section number matching the swift-review skill.
    var sectionNumber: Int {
        switch self {
        case .anyElimination: 1
        case .typedThrows: 2
        case .concurrencyModernization: 3
        case .swift62Modernization: 4
        case .performanceAntiPatterns: 5
        case .namingHeuristics: 6
        case .observationPitfalls: 7
        case .agentReview: 8
        }
    }

    /// Human-readable display name for text output.
    var displayName: String {
        switch self {
        case .anyElimination: "Generic Consolidation & Any Elimination"
        case .typedThrows: "Typed Throws Candidates"
        case .concurrencyModernization: "Structured Concurrency / GCD Modernization"
        case .swift62Modernization: "Swift 6.2 Modernization"
        case .performanceAntiPatterns: "Performance Anti-Patterns"
        case .namingHeuristics: "Naming Heuristics"
        case .observationPitfalls: "Observation Framework Pitfalls"
        case .agentReview: "Agent Review Candidates"
        }
    }
}
