
/// Represents a Swift file's syntax information with resolved token kinds.
struct ResolvedSyntaxMap {
    /// The syntax tokens for this syntax map.
    let tokens: [ResolvedSyntaxToken]

    /// Creates a resolved syntax map from the raw SourceKit `SyntaxMap`.
    ///
    /// - parameter value: The raw `SyntaxMap` obtained by SourceKit.
    init(value: SyntaxMap) {
        tokens = value.tokens.map(ResolvedSyntaxToken.init)
    }

    /// Returns array of syntax tokens intersecting with byte range.
    ///
    /// - parameter byteRange: Byte-based NSRange.
    ///
    /// - returns: The array of syntax tokens intersecting with byte range.
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

    /// Returns the syntax kinds in the specified byte range.
    ///
    /// - parameter byteRange: Byte range.
    ///
    /// - returns: The syntax kinds in the specified byte range.
    func kinds(inByteRange byteRange: ByteRange) -> [SourceKitSyntaxKind] {
        tokens(inByteRange: byteRange).compactMap(\.kind)
    }
}
