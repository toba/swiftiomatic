/// Container to register and look up SwiftLint rules.
final class RuleRegistry: @unchecked Sendable {
    private var registeredRules = [any Rule.Type]()

    /// Shared rule registry instance.
    static let shared = RuleRegistry()

    /// Rule list associated with this registry. Lazily created, and
    /// immutable once looked up.
    ///
    /// - note: Adding registering more rules after this was first
    ///         accessed will not work.
    private(set) lazy var list = RuleList(rules: registeredRules)

    private init() { /* To guarantee that this is singleton. */ }

    /// Register rules.
    ///
    /// - parameter rules: The rules to register.
    func register(rules: [any Rule.Type]) {
        registeredRules.append(contentsOf: rules)
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
