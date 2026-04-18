/// A self-describing pretty-print configuration setting.
///
/// Each layout descriptor is a single source of truth for its JSON key, group,
/// description, default value, and schema. ``Configuration`` derives its
/// encode/decode logic from these types, and schema generators read their
/// metadata directly.
///
/// Layout descriptors share two protocols with syntax rule configs:
/// - ``Groupable`` — optional ``ConfigGroup`` membership (also on ``Rule``)
/// - ``ConfigRepresentable`` — emit ``ConfigProperty`` for schema generation
///   (also on rule config structs like `SortImportsConfiguration`)
package protocol LayoutDescriptor: Groupable, ConfigRepresentable {
    /// The type of value this setting holds.
    associatedtype Value: Codable & Equatable & Sendable

    /// The JSON key used to encode and decode this setting.
    static var key: String { get }

    /// Human-readable description for schema and documentation generation.
    static var description: String { get }

    /// The default value when not specified in the configuration file.
    static var defaultValue: Value { get }

    /// The JSON Schema representation of this setting.
    static var schema: ConfigProperty.Schema { get }

    /// The writable key path into ``Configuration`` for this setting.
    static var keyPath: WritableKeyPath<Configuration, Value> & Sendable { get }

    /// Applies the default value to the given configuration.
    static func applyDefault(to config: inout Configuration)
}

extension LayoutDescriptor {
    package static var group: ConfigGroup? { nil }

    package static var configProperties: [ConfigProperty] {
        [ConfigProperty(key, schema)]
    }

    package static func applyDefault(to config: inout Configuration) {
        config[keyPath: keyPath] = defaultValue
    }
}
