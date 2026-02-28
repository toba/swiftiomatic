
/// A syntax token wrapper with resolved kind information.
struct ResolvedSyntaxToken {
    /// The raw `SyntaxToken` obtained by SourceKit.
    let value: SyntaxToken

    /// The syntax kind associated with is token.
    let kind: SourceKitSyntaxKind?

    /// Creates a syntax token from the raw SourceKit `SyntaxToken`.
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

extension [ResolvedSyntaxToken] {
    /// The kinds for these tokens.
    var kinds: [SourceKitSyntaxKind] {
        compactMap(\.kind)
    }
}
