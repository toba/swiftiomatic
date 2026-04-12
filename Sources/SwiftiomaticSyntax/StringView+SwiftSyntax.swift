package import Foundation
package import SwiftSyntax

extension StringView {
  /// Converts two SwiftSyntax absolute positions to an `NSRange`
  ///
  /// Returns `nil` when the underlying string is empty.
  ///
  /// - Parameters:
  ///   - start: Starting absolute position.
  ///   - end: Ending absolute position (must be >= `start`).
  package func NSRange(start: AbsolutePosition, end: AbsolutePosition) -> NSRange? {
    precondition(end >= start, "End position should be bigger than the start position")
    return NSRange(start: start, length: ByteCount(end.utf8Offset - start.utf8Offset))
  }

  /// Converts an absolute position and byte length to an `NSRange`
  ///
  /// - Parameters:
  ///   - start: Starting absolute position.
  ///   - length: Length in bytes.
  private func NSRange(start: AbsolutePosition, length: ByteCount) -> NSRange? {
    let byteRange = ByteRange(location: ByteCount(start), length: length)
    return byteRangeToNSRange(byteRange)
  }

  /// Converts two SwiftSyntax absolute positions to a `Range<String.Index>`
  ///
  /// - Parameters:
  ///   - start: Starting absolute position.
  ///   - end: Ending absolute position (must be >= `start`).
  package func stringRange(start: AbsolutePosition, end: AbsolutePosition) -> Range<String.Index>? {
    precondition(end >= start, "End position should be bigger than the start position")
    let byteRange = ByteRange(
      location: ByteCount(start),
      length: ByteCount(end.utf8Offset - start.utf8Offset),
    )
    return byteRangeToStringRange(byteRange)
  }
}
