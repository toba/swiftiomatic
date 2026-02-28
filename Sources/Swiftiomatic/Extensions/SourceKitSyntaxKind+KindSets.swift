extension SourceKitSyntaxKind {
  init?(shortName: Swift.String) {
    guard
      let kind =
        SourceKitSyntaxKind(rawValue: "source.lang.swift.syntaxtype.\(shortName.lowercased())")
    else {
      return nil
    }
    self = kind
  }

  static let commentAndStringKinds: Set<SourceKitSyntaxKind> = commentKinds.union([.string])

  static let commentKinds: Set<SourceKitSyntaxKind> = [
    .comment, .commentMark, .commentURL,
    .docComment, .docCommentField,
  ]

  static let allKinds: Set<SourceKitSyntaxKind> = [
    .argument, .attributeBuiltin, .attributeID, .buildconfigID,
    .buildconfigKeyword, .comment, .commentMark, .commentURL,
    .docComment, .docCommentField, .identifier, .keyword, .number,
    .objectLiteral, .parameter, .placeholder, .string,
    .stringInterpolationAnchor, .typeidentifier,
  ]

  /// Syntax kinds that don't have associated module info when getting their cursor info.
  static var kindsWithoutModuleInfo: Set<SourceKitSyntaxKind> {
    [
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
}
