/// A `Sendable` wrapper for untyped YAML configuration values.
///
/// Replaces `[String: Any]` in configuration properties where `Sendable` conformance
/// is required. Converts to/from `Any` at system boundaries (YAML parsing, rule init).
package enum ConfigValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([ConfigValue])
    case dictionary([String: ConfigValue])

    /// Creates a `ConfigValue` from an untyped value, returning `nil` if the type isn't representable.
    init?(_ any: Any) {
        switch any {
            case let value as String: self = .string(value)
            case let value as Int: self = .int(value)
            case let value as Double: self = .double(value)
            case let value as Bool: self = .bool(value)
            case let value as [Any]:
                self = .array(value.compactMap(ConfigValue.init))
            case let value as [String: Any]:
                self = .dictionary(value.compactMapValues(ConfigValue.init))
            default: return nil
        }
    }

    /// Converts back to an untyped value for passing to `Rule.init(configuration:)`.
    var asAny: Any {
        switch self {
            case let .string(v): v
            case let .int(v): v
            case let .double(v): v
            case let .bool(v): v
            case let .array(v): v.map(\.asAny)
            case let .dictionary(v): v.mapValues(\.asAny)
        }
    }
}
