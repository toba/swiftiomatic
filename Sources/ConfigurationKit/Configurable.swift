/// Derives a lowerCamelCase configuration key from a PascalCase type name.
///
/// Lowercases a leading uppercase run, stopping before the last capital when it
/// begins the next word: `URLMacro` → `urlMacro`, `BlankLines` → `blankLines`.
///
/// This is the single source of truth for the default key derivation used by both
/// `Configurable.key` (runtime) and `DetectedRule.configKey` (build-time code generation).
private nonisolated(unsafe) let leadingUppercase = /^[A-Z]+(?=[A-Z][a-z])|^[A-Z]/

package func configurationKey(forTypeName name: String) -> String {
    name.replacing(leadingUppercase) { $0.output.lowercased() }
}

/// A configurable item with a key, default value, and optional group membership.
///
/// Both syntax rules and layout settings conform to this protocol, unifying the
/// concept of "something in the configuration that has a key and a default."
package protocol Configurable {
    /// The type of the default value for this item.
    associatedtype Value: Sendable & Codable & Equatable

    /// The key used to identify this item in the configuration.
    static var key: String { get }

    /// The config group this item belongs to, or `nil` if ungrouped.
    static var group: ConfigurationGroup? { get }

    /// Human-readable description for schema and documentation generation.
    static var description: String { get }

    /// The default value when not specified in the configuration file.
    static var defaultValue: Value { get }
}

extension Configurable {
    /// By default, the key is the name of the conforming type with a lowercase initial letter.
    package static var key: String {
        let name = String("\(self)".split(separator: ".").last!)
        return configurationKey(forTypeName: name)
    }
    package static var group: ConfigurationGroup? { nil }
    package static var description: String { key }

    /// Fully qualified key: `group.key` for grouped items, bare `key` otherwise.
    package static var qualifiedKey: String {
        if let group { "\(group.key).\(key)" } else { key }
    }
}
