package import Foundation
import Synchronization

/// Thread-safe container to register and look up Swiftiomatic rules
package final class RuleRegistry: Sendable {
    private struct State: Sendable {
        var registeredRules = [any Rule.Type]()
        var list: RuleList?
    }

    private let state = Mutex(State())

    /// Shared rule registry instance
    package static let shared = RuleRegistry()

    /// Rule list associated with this registry, lazily created and immutable once accessed
    ///
    /// Registering more rules after this property is first read has no effect.
    var list: RuleList {
        state.withLock { state in
            if let list = state.list { return list }
            let list = RuleList(rules: state.registeredRules)
            state.list = list
            return list
        }
    }

    /// The number of registered rules
    package var ruleCount: Int {
        list.rules.count
    }

    private init() { /* To guarantee that this is singleton. */ }

    /// Register rules
    ///
    /// - Parameters:
    ///   - rules: The rules to register.
    func register(rules: [any Rule.Type]) {
        state.withLock { $0.registeredRules.append(contentsOf: rules) }
    }

    /// Look up a rule for a given ID
    ///
    /// - Parameters:
    ///   - id: The ID for the rule to look up.
    /// - Returns: The rule matching the specified ID, if one was found.
    func rule(forID id: String) -> (any Rule.Type)? {
        list.rules[id]
    }

    /// Generate rule documentation to the specified directory
    ///
    /// - Parameters:
    ///   - url: The directory URL where documentation files will be written.
    package func generateDocs(to url: URL) throws {
        let docs = RuleListDocumentation(list)
        try docs.write(to: url)
    }
}
