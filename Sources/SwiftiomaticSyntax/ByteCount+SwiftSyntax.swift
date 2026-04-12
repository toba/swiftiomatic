package import SwiftSyntax

extension ByteCount {
  /// Creates a byte count from a SwiftSyntax ``AbsolutePosition``
  ///
  /// - Parameters:
  ///   - position: The SwiftSyntax position whose UTF-8 offset is used.
  package init(_ position: AbsolutePosition) {
    self.init(position.utf8Offset)
  }
}
