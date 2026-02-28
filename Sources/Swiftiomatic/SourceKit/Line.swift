import Foundation

/// Representation of a single line in a larger String.
struct Line {
    /// origin = 0.
    let index: Int
    /// Content.
    let content: String
    /// UTF16 based range in entire String. Equivalent to `Range<UTF16Index>`.
    let range: NSRange
    /// Byte based range in entire String. Equivalent to `Range<UTF8Index>`.
    let byteRange: ByteRange
}
