public import Foundation

/// Adds `TextOutputStream` conformance so ``FileHandle`` can be used as a
/// target for `print(_:to:)` and similar output functions.
extension FileHandle: @retroactive TextOutputStream {
  /// Writes a string to the file handle as UTF-8 data
  ///
  /// - Parameters:
  ///   - string: The text to write.
  public func write(_ string: String) {
    let data = Data(string.utf8)
    write(data)
  }
}
