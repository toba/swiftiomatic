import SwiftiomaticSyntax

/// A `Sendable` wrapper for untyped YAML configuration values
///
/// Replaces `[String: Any]` in configuration properties where `Sendable` conformance
/// is required. Converts to/from `Any` at system boundaries (YAML parsing, rule init).
public enum ConfigValue: Sendable, Equatable {
  /// A string value
  case string(String)
  /// An integer value
  case int(Int)
  /// A double-precision floating-point value
  case double(Double)
  /// A boolean value
  case bool(Bool)
  /// An ordered list of ``ConfigValue`` elements
  case array([ConfigValue])
  /// A keyed dictionary of ``ConfigValue`` entries
  case dictionary([String: ConfigValue])

  /// Create a ``ConfigValue`` from an untyped value, returning `nil` if the type isn't representable
  ///
  /// - Parameters:
  ///   - any: The untyped value to wrap.
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

  /// Convert back to an untyped value for passing to ``Rule/init(configuration:)``
  var asAny: Any {
    switch self {
    case .string(let v): v
    case .int(let v): v
    case .double(let v): v
    case .bool(let v): v
    case .array(let v): v.map(\.asAny)
    case .dictionary(let v): v.mapValues(\.asAny)
    }
  }
}
