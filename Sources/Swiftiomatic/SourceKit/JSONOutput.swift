import Foundation

/// Shared pretty-printing JSON encoder with sorted keys
private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return encoder
}()

/// Encode an `Encodable` value to a pretty-printed JSON string
///
/// Returns an empty string if encoding fails.
///
/// - Parameters:
///   - value: The value to encode.
func toJSON<T: Encodable>(_ value: T) -> String {
    do {
        let data = try jsonEncoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    } catch {
        return ""
    }
}
