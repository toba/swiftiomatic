/// A syntax token wrapper with resolved kind information.
struct ResolvedSyntaxToken {
    /// The raw `SyntaxToken` obtained by SourceKit.
    let token: SyntaxToken

    /// The syntax kind associated with is token.
    let kind: SourceKitSyntaxKind?

    /// Creates a syntax token from the raw SourceKit `SyntaxToken`.
    ///
    /// - parameter token: The raw `SyntaxToken` obtained by SourceKit.
    init(token: SyntaxToken) {
        self.token = token
        kind = SourceKitSyntaxKind(rawValue: token.type)
    }

    /// The byte range in a source file for this token.
    var range: ByteRange {
        token.range
    }

    /// The starting byte offset in a source file for this token.
    var offset: ByteCount {
        token.offset
    }

    /// The length in bytes for this token.
    var length: ByteCount {
        token.length
    }
}

extension [ResolvedSyntaxToken] {
    /// The kinds for these tokens.
    var kinds: [SourceKitSyntaxKind] {
        compactMap(\.kind)
    }
}
