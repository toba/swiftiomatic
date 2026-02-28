/// Severity level for a finding.
enum Severity: String, Codable, Comparable, Sendable {
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

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rank < rhs.rank
    }
}
