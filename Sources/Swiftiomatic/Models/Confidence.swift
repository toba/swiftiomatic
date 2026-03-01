/// Confidence level for a rule violation.
///
/// - `high`: Definitive — the finding is certain.
/// - `medium`: Likely true — probably correct but verify.
/// - `low`: Needs review — pattern matched but context required.
public enum Confidence: String, Codable, CaseIterable, Comparable, Sendable {
    case low
    case medium
    case high
}

extension CaseIterable where Self: Equatable & Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        guard let lhsIndex = allCases.firstIndex(of: lhs),
              let rhsIndex = allCases.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
