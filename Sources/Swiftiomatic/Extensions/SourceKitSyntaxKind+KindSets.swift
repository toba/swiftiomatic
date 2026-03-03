extension SourceKitSyntaxKind {
    /// Creates a syntax kind from its short name (e.g. `"comment"` instead of the full raw value)
    ///
    /// - Parameters:
    ///   - shortName: The suffix after `source.lang.swift.syntaxtype.`, case-insensitive.
    init?(shortName: Swift.String) {
        guard
            let kind =
            SourceKitSyntaxKind(rawValue: "source.lang.swift.syntaxtype.\(shortName.lowercased())")
        else {
            return nil
        }
        self = kind
    }

    /// All comment kinds plus string literals
    static let commentAndStringKinds: Set<SourceKitSyntaxKind> = commentKinds.union([.string])

    /// All comment-related syntax kinds including doc comments
    static let commentKinds: Set<SourceKitSyntaxKind> = [
        .comment, .commentMark, .commentURL,
        .docComment, .docCommentField,
    ]

    /// Every known ``SourceKitSyntaxKind`` value
    static let allKinds: Set<SourceKitSyntaxKind> = [
        .argument, .attributeBuiltin, .attributeID, .buildconfigID,
        .buildconfigKeyword, .comment, .commentMark, .commentURL,
        .docComment, .docCommentField, .identifier, .keyword, .number,
        .objectLiteral, .parameter, .placeholder, .string,
        .stringInterpolationAnchor, .typeidentifier,
    ]

    /// Syntax kinds that don't have associated module info when getting their cursor info.
    static let kindsWithoutModuleInfo: Set<SourceKitSyntaxKind> = [
        .attributeBuiltin,
        .keyword,
        .number,
        .docComment,
        .string,
        .stringInterpolationAnchor,
        .attributeID,
        .buildconfigKeyword,
        .buildconfigID,
        .commentURL,
        .comment,
        .docCommentField,
    ]
}
