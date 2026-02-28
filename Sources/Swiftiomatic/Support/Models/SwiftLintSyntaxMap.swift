import SourceKittenFramework

/// Represents a Swift file's syntax information.
struct SwiftLintSyntaxMap {
    /// The SwiftLint-specific syntax tokens for this syntax map.
    let tokens: [SwiftLintSyntaxToken]

    /// Creates a `SwiftLintSyntaxMap` from the raw `SyntaxMap` obtained by SourceKitten.
    ///
    /// - parameter value: The raw `SyntaxMap` obtained by SourceKitten.
    init(value: SyntaxMap) {
        tokens = value.tokens.map(SwiftLintSyntaxToken.init)
    }

    /// Returns array of syntax tokens intersecting with byte range.
    ///
    /// - parameter byteRange: Byte-based NSRange.
    ///
    /// - returns: The array of syntax tokens intersecting with byte range.
    func tokens(inByteRange byteRange: ByteRange) -> [SwiftLintSyntaxToken] {
        func intersect(_ token: SwiftLintSyntaxToken) -> Bool {
            token.range.intersects(byteRange)
        }

        func intersectsOrAfter(_ token: SwiftLintSyntaxToken) -> Bool {
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

    /// Returns the syntax kinds in the specified byte range.
    ///
    /// - parameter byteRange: Byte range.
    ///
    /// - returns: The syntax kinds in the specified byte range.
    func kinds(inByteRange byteRange: ByteRange) -> [SyntaxKind] {
        tokens(inByteRange: byteRange).compactMap(\.kind)
    }
}
