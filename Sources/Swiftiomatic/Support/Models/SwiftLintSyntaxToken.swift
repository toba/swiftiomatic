
/// A SwiftLint-aware Swift syntax token.
struct SwiftLintSyntaxToken {
    /// The raw `SyntaxToken` obtained by SourceKit.
    let value: SyntaxToken

    /// The syntax kind associated with is token.
    let kind: SourceKitSyntaxKind?

    /// Creates a `SwiftLintSyntaxToken` from the raw `SyntaxToken` obtained by SourceKit.
    ///
    /// - parameter value: The raw `SyntaxToken` obtained by SourceKit.
    init(value: SyntaxToken) {
        self.value = value
        kind = SourceKitSyntaxKind(rawValue: value.type)
    }

    /// The byte range in a source file for this token.
    var range: ByteRange {
        value.range
    }

    /// The starting byte offset in a source file for this token.
    var offset: ByteCount {
        value.offset
    }

    /// The length in bytes for this token.
    var length: ByteCount {
        value.length
    }
}

extension [SwiftLintSyntaxToken] {
    /// The kinds for these tokens.
    var kinds: [SourceKitSyntaxKind] {
        compactMap(\.kind)
    }
}
