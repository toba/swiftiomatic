import SwiftiomaticSyntax

/// A ``SyntaxToken`` wrapper with its kind resolved to a ``SourceKitSyntaxKind``
struct ResolvedSyntaxToken {
  /// The raw ``SyntaxToken`` obtained from SourceKit
  let token: SyntaxToken

  /// The resolved syntax kind, or `nil` if the raw type string is unrecognized
  let kind: SourceKitSyntaxKind?

  /// Create a resolved token from a raw SourceKit ``SyntaxToken``
  ///
  /// - Parameters:
  ///   - token: The raw ``SyntaxToken`` obtained from SourceKit.
  init(token: SyntaxToken) {
    self.token = token
    kind = SourceKitSyntaxKind(rawValue: token.type)
  }

  /// The byte range in the source file for this token
  var range: ByteRange {
    token.range
  }

  /// The starting byte offset in the source file for this token
  var offset: ByteCount {
    token.offset
  }

  /// The length in bytes of this token
  var length: ByteCount {
    token.length
  }
}

extension [ResolvedSyntaxToken] {
  /// The resolved ``SourceKitSyntaxKind`` values, dropping unrecognized tokens
  var kinds: [SourceKitSyntaxKind] {
    compactMap(\.kind)
  }
}
