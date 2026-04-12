import SwiftiomaticSyntax

/// A Swift file's syntax information with token kinds resolved to ``SourceKitSyntaxKind``
struct ResolvedSyntaxMap {
  /// The resolved syntax tokens for this map
  let tokens: [ResolvedSyntaxToken]

  /// Create a resolved syntax map from a raw SourceKit ``SyntaxMap``
  ///
  /// - Parameters:
  ///   - value: The raw ``SyntaxMap`` obtained from SourceKit.
  init(value: SyntaxMap) {
    tokens = value.tokens.map(ResolvedSyntaxToken.init)
  }

  /// Return syntax tokens that intersect with the given byte range
  ///
  /// Uses binary search to efficiently skip tokens before the range.
  ///
  /// - Parameters:
  ///   - byteRange: The byte range to test against.
  func tokens(inByteRange byteRange: ByteRange) -> [ResolvedSyntaxToken] {
    func intersect(_ token: ResolvedSyntaxToken) -> Bool {
      token.range.intersects(byteRange)
    }

    func intersectsOrAfter(_ token: ResolvedSyntaxToken) -> Bool {
      token.offset + token.length > byteRange.location
    }

    guard let startIndex = tokens.firstIndexAssumingSorted(where: intersectsOrAfter) else {
      return []
    }

    let tokensAfterFirstIntersection = tokens
      .lazy
      .suffix(from: startIndex)
      .prefix(while: { $0.offset < byteRange.upperBound })
      .filter(intersect)

    return Array(tokensAfterFirstIntersection)
  }

  /// Return the syntax kinds present in the given byte range
  ///
  /// - Parameters:
  ///   - byteRange: The byte range to query.
  func kinds(inByteRange byteRange: ByteRange) -> [SourceKitSyntaxKind] {
    tokens(inByteRange: byteRange).compactMap(\.kind)
  }
}
