/// A type that describes its configurable properties for schema generation.
///
/// Structs implement this as a static property; enums (like ``ConfigGroup``)
/// return different properties per case via the instance property.
package protocol ConfigRepresentable: Sendable {
    /// The properties this type contributes to the JSON configuration schema.
    var configProperties: [ConfigProperty] { get }
    /// Static access for types where properties don't vary by instance.
    static var configProperties: [ConfigProperty] { get }
}

extension ConfigRepresentable {
    /// Default: forward instance access to the static property.
    package var configProperties: [ConfigProperty] { Self.configProperties }
    /// Default: empty (types that only use instance override this).
    package static var configProperties: [ConfigProperty] { [] }
}

/// Describes a single configuration property for schema generation.
package struct ConfigProperty: Sendable {
    package let key: String
    package let schema: Schema

    package enum Schema: Sendable {
        case bool(description: String, defaultValue: Bool)
        case integer(description: String, defaultValue: Int, minimum: Int)
        case string(description: String)
        case stringEnum(description: String, values: [String], defaultValue: String)
        case stringArray(description: String, defaultValue: [String])
    }

    package init(_ key: String, _ schema: Schema) {
        self.key = key
        self.schema = schema
    }
}
