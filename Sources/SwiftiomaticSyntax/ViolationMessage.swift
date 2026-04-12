/// A compile-time-safe violation message.
///
/// Each rule defines its messages as `fileprivate static` methods or properties
/// on an extension of this type:
///
///     extension ViolationMessage {
///         fileprivate static func doNotForceUnwrap(name: String) -> Self {
///             "do not force unwrap '\(name)'"
///         }
///     }
public struct ViolationMessage: Hashable, Sendable, CustomStringConvertible,
  ExpressibleByStringLiteral, ExpressibleByStringInterpolation, Codable
{
  package let text: String

  public var description: String { text }

  /// Whether the message contains the given substring.
  package func contains(_ other: some StringProtocol) -> Bool {
    text.contains(other)
  }

  public init(stringLiteral value: String) {
    text = value
  }

  public init(stringInterpolation: DefaultStringInterpolation) {
    text = String(stringInterpolation: stringInterpolation)
  }

  public init(from decoder: any Decoder) throws {
    text = try decoder.singleValueContainer().decode(String.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(text)
  }
}
