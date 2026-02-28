import SwiftSyntax

extension ByteCount {
  /// Converts a SwiftSyntax `AbsolutePosition` to a SourceKit `ByteCount`.
  ///
  /// - parameter position: The SwiftSyntax position to convert.
  init(_ position: AbsolutePosition) {
    self.init(position.utf8Offset)
  }
}
