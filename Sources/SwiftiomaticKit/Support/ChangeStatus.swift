/// Whether a finding is on a changed line or on a line that the change did not touch.
public enum ChangeStatus: String, Codable, Sendable {
    /// The finding is on a changed line.
    case introduced

    /// The finding is on a line that the change did not touch.
    case existing

    /// Classifies a 1-based line against the changed line ranges.
    public init(line: Int, changedLines: [ClosedRange<Int>]) {
        self = changedLines.contains { $0.contains(line) } ? .introduced : .existing
    }
}
