import Foundation

/// Encodes a value as pretty-printed JSON with sorted keys.
///
/// - Parameters:
///   - value: The value to encode.
///   - fallback: The text to return when the encoder fails.
///   - extraFormatting: Formatting options to add to `.prettyPrinted` and `.sortedKeys`.
///   - keyEncodingStrategy: The key strategy for the encoder.
func encodePrettyJSON(
    _ value: some Encodable,
    fallback: String,
    extraFormatting: JSONEncoder.OutputFormatting = [],
    keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.outputFormatting.formUnion(extraFormatting)
    encoder.keyEncodingStrategy = keyEncodingStrategy

    guard let data = try? encoder.encode(value) else { return fallback }
    return String(bytes: data, encoding: .utf8) ?? fallback
}

/// Writes the text to standard output, terminated with a newline.
func writeLineToStandardOutput(_ text: String) {
    FileHandle.standardOutput.write(Data(text.utf8))
    FileHandle.standardOutput.write(Data([0x0A]))
}
