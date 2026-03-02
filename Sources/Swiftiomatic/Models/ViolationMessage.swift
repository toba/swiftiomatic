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
struct ViolationMessage: Hashable, Sendable, CustomStringConvertible,
    ExpressibleByStringLiteral, ExpressibleByStringInterpolation, Codable
{
    let text: String

    var description: String { text }

    /// Whether the message contains the given substring.
    func contains(_ other: some StringProtocol) -> Bool {
        text.contains(other)
    }

    init(stringLiteral value: String) {
        text = value
    }

    init(stringInterpolation: DefaultStringInterpolation) {
        text = String(stringInterpolation: stringInterpolation)
    }

    init(from decoder: any Decoder) throws {
        text = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
}
