import SourceKittenFramework

/// A SwiftLint-aware Swift syntax token.
struct SwiftLintSyntaxToken {
    /// The raw `SyntaxToken` obtained by SourceKitten.
    let value: SyntaxToken

    /// The syntax kind associated with is token.
    let kind: SyntaxKind?

    /// Creates a `SwiftLintSyntaxToken` from the raw `SyntaxToken` obtained by SourceKitten.
    ///
    /// - parameter value: The raw `SyntaxToken` obtained by SourceKitten.
    init(value: SyntaxToken) {
        self.value = value
        kind = SyntaxKind(rawValue: value.type)
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

extension Array where Element == SwiftLintSyntaxToken {
    /// The kinds for these tokens.
    var kinds: [SyntaxKind] {
        compactMap(\.kind)
    }
}
