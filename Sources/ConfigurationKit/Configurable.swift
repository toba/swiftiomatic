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
        return name.prefix(1).lowercased() + name.dropFirst()
    }
    package static var group: ConfigurationGroup? { nil }
    package static var description: String { key }
}

