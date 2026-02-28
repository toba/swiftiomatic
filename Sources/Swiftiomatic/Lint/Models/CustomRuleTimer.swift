import Foundation
import Synchronization

/// Utility to measure the time spent in each custom rule.
final class CustomRuleTimer: Sendable {
    private let state = Mutex([String: [TimeInterval]]())
    private let active = Mutex(false)

    /// Singleton.
    static let shared = CustomRuleTimer()

    /// Tell the timer it should record time spent in rules.
    func activate() {
        active.withLock { $0 = true }
    }

    /// Return all time spent for each custom rule, keyed by rule ID.
    func dump() -> [String: TimeInterval] {
        state.withLock { ruleIDForTimes in
            ruleIDForTimes.mapValues { $0.reduce(0, +) }
        }
    }

    /// Register time spent evaluating a rule with the specified ID.
    ///
    /// - parameter time:   The time interval spent evaluating this rule ID.
    /// - parameter ruleID: The ID of the rule that was evaluated.
    func register(time: TimeInterval, forRuleID ruleID: String) {
        let isActive = active.withLock { $0 }
        if isActive {
            state.withLock { $0[ruleID, default: []].append(time) }
        }
    }
}
