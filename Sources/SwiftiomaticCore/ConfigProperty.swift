/// A type that describes its configurable properties for schema generation.
///
/// Structs implement this as a static property; enums (like ``ConfigGroup``)
/// return different properties per case via the instance property.
public protocol ConfigRepresentable: Sendable {
  /// The properties this type contributes to the JSON configuration schema.
  var configProperties: [ConfigProperty] { get }
  /// Static access for types where properties don't vary by instance.
  static var configProperties: [ConfigProperty] { get }
}

extension ConfigRepresentable {
  /// Default: forward instance access to the static property.
  public var configProperties: [ConfigProperty] { Self.configProperties }
  /// Default: empty (types that only use instance override this).
  public static var configProperties: [ConfigProperty] { [] }
}

/// Describes a single configuration property for schema generation.
public struct ConfigProperty: Sendable {
  public let key: String
  public let schema: Schema

  public enum Schema: Sendable {
    case bool(description: String, defaultValue: Bool)
    case integer(description: String, defaultValue: Int, minimum: Int)
    case string(description: String)
    case stringEnum(description: String, values: [String], defaultValue: String)
    case stringArray(description: String, defaultValue: [String])
  }

  public init(_ key: String, _ schema: Schema) {
    self.key = key
    self.schema = schema
  }
}
