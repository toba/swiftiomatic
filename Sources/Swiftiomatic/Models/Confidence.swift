/// Confidence level for a rule violation.
///
/// - `high`: Definitive — the finding is certain.
/// - `medium`: Likely true — probably correct but verify.
/// - `low`: Needs review — pattern matched but context required.
package enum Confidence: String, Codable, CaseIterable, Comparable, Sendable {
    case low
    case medium
    case high

    package static func < (lhs: Confidence, rhs: Confidence) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}
