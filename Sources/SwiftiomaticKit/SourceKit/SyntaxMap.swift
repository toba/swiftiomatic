import SwiftiomaticSyntax

/// A Swift file's syntax token map as returned by SourceKit
struct SyntaxMap: Equatable {
  /// The ordered syntax tokens in the file
  let tokens: [SyntaxToken]

  /// Create a syntax map from pre-built tokens
  ///
  /// - Parameters:
  ///   - tokens: The array of ``SyntaxToken`` values.
  init(tokens: [SyntaxToken]) {
    self.tokens = tokens
  }

  /// Create a syntax map from raw ``SourceKitValue`` array entries
  ///
  /// - Parameters:
  ///   - data: The `key.syntaxmap` array from a SourceKit response.
  init(data: [SourceKitValue]) {
    tokens = data.compactMap { item in
      guard let dict = item.dictionaryValue,
        let type = dict["key.kind"]?.stringValue,
        let offset = dict["key.offset"]?.int64Value,
        let length = dict["key.length"]?.int64Value
      else { return nil }
      return SyntaxToken(type: type, offset: ByteCount(offset), length: ByteCount(length))
    }
  }

  /// Create a syntax map by extracting `key.syntaxmap` from a full SourceKit response
  ///
  /// - Parameters:
  ///   - sourceKitResponse: The full response dictionary from an `editor.open` request.
  init(sourceKitResponse: [String: SourceKitValue]) {
    self.init(data: SwiftDocKey.syntaxMap(from: sourceKitResponse) ?? [])
  }

  /// Create a syntax map by sending an `editor.open` request for the given file
  ///
  /// - Parameters:
  ///   - file: The ``File`` to open in SourceKit.
  init(file: File) throws(Request.Error) {
    try self.init(sourceKitResponse: Request.editorOpen(file: file).send())
  }
}

// MARK: Support for enumerating doc-comment blocks

extension SyntaxToken {
  var isDocComment: Bool {
    SourceKitSyntaxKind.docComments.contains { $0.rawValue == type }
  }
}

extension SyntaxMap {
  /// Contiguous doc-comment byte ranges in the file
  var docCommentRanges: [ByteRange] {
    let docCommentBlocks = tokens.split { !$0.isDocComment }
    return docCommentBlocks.compactMap { block in
      guard let first = block.first, let last = block.last else { return nil }
      return ByteRange(
        location: first.offset,
        length: last.offset + last.length - first.offset,
      )
    }
  }

  /// Stateful helper that matches doc-comment ranges to declaration offsets in order
  final class DocCommentFinder {
    private var ranges: [ByteRange]
    private var previousOffset: ByteCount?

    init(syntaxMap: SyntaxMap) {
      ranges = syntaxMap.docCommentRanges
      previousOffset = nil
    }

    /// Return the doc-comment range immediately preceding the given declaration offset
    ///
    /// Must be called with monotonically increasing offsets.
    ///
    /// - Parameters:
    ///   - offset: The byte offset of the declaration.
    func getRangeForDeclaration(atOffset offset: ByteCount) -> ByteRange? {
      if let previousOffset {
        guard offset > previousOffset else { return nil }
      }

      let commentsBeforeDecl = ranges.prefix { $0.upperBound < offset }
      ranges.removeFirst(commentsBeforeDecl.count)
      previousOffset = offset
      return commentsBeforeDecl.last
    }
  }

  /// Create a ``DocCommentFinder`` initialized with this map's doc-comment ranges
  func createDocCommentFinder() -> DocCommentFinder {
    DocCommentFinder(syntaxMap: self)
  }
}

extension SyntaxMap: CustomStringConvertible {
  var description: String {
    toJSON(tokens)
  }
}
