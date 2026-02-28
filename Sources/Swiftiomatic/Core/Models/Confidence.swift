/// Confidence level for a rule violation.
///
/// - `high`: Definitive — the finding is certain.
/// - `medium`: Likely true — probably correct but verify.
/// - `low`: Needs review — pattern matched but context required.
enum Confidence: String, Codable, Comparable, Sendable {
    case low
    case medium
    case high

    private var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }

    static func < (lhs: Confidence, rhs: Confidence) -> Bool {
        lhs.rank < rhs.rank
    }
}
