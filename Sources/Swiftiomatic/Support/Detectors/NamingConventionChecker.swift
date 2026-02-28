import Foundation

/// Shared naming convention checking used by both `NamingHeuristicsCheck` (suggest)
/// and `NamingHeuristicsRule` (lint).
enum NamingConventionChecker {
    /// Prefixes that make a Bool property read as an assertion.
    static let assertionPrefixes = [
        "is", "has", "can", "should", "will", "did", "was",
        "needs", "allows", "requires", "supports", "includes",
        "contains", "enables",
    ]

    /// Whether a Bool property name reads as an assertion (e.g. `isEnabled`).
    static func isAssertionNamed(_ name: String) -> Bool {
        assertionPrefixes.contains { prefix in
            name.hasPrefix(prefix) && name.count > prefix.count
                && name[name.index(name.startIndex, offsetBy: prefix.count)].isUppercase
        }
    }

    /// Returns the suggested `make`-prefixed name for a factory method, or `nil` if
    /// the method name doesn't use a create/new/build prefix.
    static func factoryMethodSuggestion(for name: String) -> String? {
        let stripped: String
        if name.hasPrefix("create") {
            stripped = String(name.dropFirst(6))
        } else if name.hasPrefix("new") {
            stripped = String(name.dropFirst(3))
        } else if name.hasPrefix("build") {
            stripped = String(name.dropFirst(5))
        } else {
            return nil
        }
        return "make\(stripped)"
    }

    /// Prefixes considered action verbs for protocol suffix heuristics.
    static let actionVerbPrefixes = [
        "provide", "supply", "create", "generate",
        "load", "fetch", "report", "coordinate",
    ]
}

extension String {
    func replacingSuffix(_ suffix: String, with replacement: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count)) + replacement
    }
}
