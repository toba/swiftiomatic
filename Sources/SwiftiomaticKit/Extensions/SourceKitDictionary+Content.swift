import Foundation
import SwiftiomaticSyntax

extension SourceKitDictionary {
  /// Collects all structure kinds and their byte ranges that contain the given offset
  ///
  /// When `byteOffset` is `nil`, returns every kind in the entire structure tree.
  ///
  /// - Parameters:
  ///   - byteOffset: Byte offset to filter by, or `nil` to return all kinds.
  func kinds(forByteOffset byteOffset: ByteCount? = nil)
    -> [(kind: String, byteRange: ByteRange)]
  {
    var results = [(kind: String, byteRange: ByteRange)]()

    func parse(_ dictionary: SourceKitDictionary) {
      guard let range = dictionary.byteRange else {
        return
      }
      if let byteOffset, !range.contains(byteOffset) {
        return
      }
      if let kind = dictionary.kind {
        results.append((kind: kind, byteRange: range))
      }
      dictionary.substructure.forEach(parse)
    }
    parse(self)
    return results
  }

  /// Extracts the string content of this structure node from the given source file
  ///
  /// - Parameters:
  ///   - file: The ``SwiftSource`` file this structure occurs in.
  func content(in file: SwiftSource) -> String? {
    guard let byteRange, let range = file.stringView.byteRangeToNSRange(byteRange) else {
      return nil
    }
    return String(file.stringView.nsString.substring(with: range))
  }
}
