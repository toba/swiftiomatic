import SwiftSyntax

extension SourceRange {
  /// Whether the given absolute position falls within this source range
  ///
  /// - Parameters:
  ///   - position: The absolute position to check.
  ///   - locationConverter: The converter used to translate line/column to absolute positions.
  func contains(
    _ position: AbsolutePosition,
    locationConverter: SourceLocationConverter
  ) -> Bool {
    let startPosition = locationConverter.position(ofLine: start.line, column: start.column)
    let endPosition = locationConverter.position(ofLine: end.line, column: end.column)
    return startPosition <= position && position <= endPosition
  }
}
