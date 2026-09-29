package import Foundation

/// Decodes the bytes of a source file into a `String` .
package enum SourceText {
    /// The UTF-8 byte order mark.
    private static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]

    /// Returns the text of the given UTF-8 bytes, or `nil` when the bytes are not valid UTF-8.
    ///
    /// The result is the same as the result of `String(data:encoding: .utf8)` . A leading byte
    /// order mark is removed. The slice shares the storage of `data` , so the bytes are validated
    /// and copied once, into the new string.
    package static func decode(_ data: Data) -> String? {
        let body = data.starts(with: byteOrderMark)
            ? data.dropFirst(byteOrderMark.count)
            : data[...]
        return String(validating: body, as: UTF8.self)
    }
}
