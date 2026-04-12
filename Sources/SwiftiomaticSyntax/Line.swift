package import Foundation

/// A single line within a source string, with both UTF-16 and byte-based ranges
package struct Line {
  /// One-based line number
  package let index: Int
  /// The text content of the line (excluding the newline terminator)
  package let content: String
  /// UTF-16 based range in the entire string, including the trailing newline
  package let range: NSRange
  /// Byte-based range in the entire string, including the trailing newline
  package let byteRange: ByteRange

  /// Creates a line with the given index, content, and ranges
  ///
  /// - Parameters:
  ///   - index: One-based line number.
  ///   - content: The text content of the line.
  ///   - range: UTF-16 based range including trailing newline.
  ///   - byteRange: Byte-based range including trailing newline.
  package init(index: Int, content: String, range: NSRange, byteRange: ByteRange) {
    self.index = index
    self.content = content
    self.range = range
    self.byteRange = byteRange
  }
}
