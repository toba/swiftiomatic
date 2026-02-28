import Synchronization

/// Container to register and look up SwiftLint rules.
final class RuleRegistry: Sendable {
    private struct State: @unchecked Sendable {
        var registeredRules = [any Rule.Type]()
        var list: RuleList?
    }

    private let state = Mutex(State())

    /// Shared rule registry instance.
    static let shared = RuleRegistry()

    /// Rule list associated with this registry. Lazily created, and
    /// immutable once looked up.
    ///
    /// - note: Registering more rules after this was first
    ///         accessed will not work.
    var list: RuleList {
        state.withLock { state in
            if let list = state.list { return list }
            let list = RuleList(rules: state.registeredRules)
            state.list = list
            return list
        }
    }

    private init() { /* To guarantee that this is singleton. */ }

    /// Register rules.
    ///
    /// - parameter rules: The rules to register.
    func register(rules: [any Rule.Type]) {
        state.withLock { $0.registeredRules.append(contentsOf: rules) }
    }

    /// Look up a rule for a given ID.
    ///
    /// - parameter id: The ID for the rule to look up.
    ///
    /// - returns: The rule matching the specified ID, if one was found.
    func rule(forID id: String) -> (any Rule.Type)? {
        list.list[id]
    }
}
