import Foundation

/// Shared naming convention checking aligned with the Swift API Design Guidelines
///
/// Used by both `NamingHeuristicsCheck` (suggest) and `NamingHeuristicsRule` (lint).
enum NamingConventionChecker {
    /// Prefixes that make a Bool property read as an assertion (e.g. `is`, `has`, `can`)
    static let assertionPrefixes = [
        "is", "has", "can", "should", "will", "did", "was",
        "needs", "allows", "requires", "supports", "includes",
        "contains", "enables",
    ]

    /// Whether a Bool property name reads as an assertion (e.g. `isEnabled`)
    ///
    /// - Parameters:
    ///   - name: The property name to check.
    /// - Returns: `true` if the name starts with a recognized assertion prefix followed by an uppercase letter.
    static func isAssertionNamed(_ name: String) -> Bool {
        assertionPrefixes.contains { prefix in
            name.hasPrefix(prefix) && name.count > prefix.count
                && name[name.index(name.startIndex, offsetBy: prefix.count)].isUppercase
        }
    }

    /// Suggests a `make`-prefixed name for a factory method
    ///
    /// - Parameters:
    ///   - name: The current method name to evaluate.
    /// - Returns: A `make`-prefixed alternative, or `nil` if the name does not use a `create`/`new`/`build` prefix.
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

    /// Prefixes considered action verbs for protocol naming heuristics
    static let actionVerbPrefixes = [
        "provide", "supply", "create", "generate",
        "load", "fetch", "report", "coordinate",
    ]
}

extension String {
    /// Replaces a trailing suffix with a different string
    ///
    /// - Parameters:
    ///   - suffix: The suffix to match.
    ///   - replacement: The string to substitute in place of the suffix.
    /// - Returns: The modified string, or `nil` if the suffix was not present.
    func replacingSuffix(_ suffix: String, with replacement: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count)) + replacement
    }
}
