/// Confidence level for a rule violation.
///
/// - `high`: Definitive — the finding is certain.
/// - `medium`: Likely true — probably correct but verify.
/// - `low`: Needs review — pattern matched but context required.
public enum Confidence: String, Codable, CaseIterable, Comparable, Sendable {
  case low
  case medium
  case high

  private var order: Int {
    switch self {
    case .low: 0
    case .medium: 1
    case .high: 2
    }
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.order < rhs.order
  }
}
