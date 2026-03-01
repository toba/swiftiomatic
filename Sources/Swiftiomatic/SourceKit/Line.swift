import Foundation

/// A single line within a source string, with both UTF-16 and byte-based ranges
struct Line {
    /// One-based line number
    let index: Int
    /// The text content of the line (excluding the newline terminator)
    let content: String
    /// UTF-16 based range in the entire string, including the trailing newline
    let range: NSRange
    /// Byte-based range in the entire string, including the trailing newline
    let byteRange: ByteRange
}
