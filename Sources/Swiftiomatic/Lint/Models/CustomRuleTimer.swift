import Foundation

/// Utility to measure the time spent in each custom rule.
final class CustomRuleTimer: @unchecked Sendable {
    private let lock = NSLock()
    private var ruleIDForTimes = [String: [TimeInterval]]()
    private var shouldRecord = false

    /// Singleton.
    static let shared = CustomRuleTimer()

    /// Tell the timer it should record time spent in rules.
    func activate() {
        shouldRecord = true
    }

    /// Return all time spent for each custom rule, keyed by rule ID.
    func dump() -> [String: TimeInterval] {
        lock.withLock {
            ruleIDForTimes.mapValues { $0.reduce(0, +) }
        }
    }

    /// Register time spent evaluating a rule with the specified ID.
    ///
    /// - parameter time:   The time interval spent evaluating this rule ID.
    /// - parameter ruleID: The ID of the rule that was evaluated.
    func register(time: TimeInterval, forRuleID ruleID: String) {
        if shouldRecord {
            lock.withLock {
                ruleIDForTimes[ruleID, default: []].append(time)
            }
        }
    }
}
