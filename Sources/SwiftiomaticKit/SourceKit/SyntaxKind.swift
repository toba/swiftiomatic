import SwiftiomaticSyntax

/// SourceKit syntax token kinds from `source.lang.swift.syntaxtype.*` UIDs
enum SourceKitSyntaxKind: String, CaseIterable {
  case argument = "source.lang.swift.syntaxtype.argument"
  case attributeBuiltin = "source.lang.swift.syntaxtype.attribute.builtin"
  case attributeID = "source.lang.swift.syntaxtype.attribute.id"
  case buildconfigID = "source.lang.swift.syntaxtype.buildconfig.id"
  case buildconfigKeyword = "source.lang.swift.syntaxtype.buildconfig.keyword"
  case comment = "source.lang.swift.syntaxtype.comment"
  case commentMark = "source.lang.swift.syntaxtype.comment.mark"
  case commentURL = "source.lang.swift.syntaxtype.comment.url"
  case docComment = "source.lang.swift.syntaxtype.doccomment"
  case docCommentField = "source.lang.swift.syntaxtype.doccomment.field"
  case identifier = "source.lang.swift.syntaxtype.identifier"
  case keyword = "source.lang.swift.syntaxtype.keyword"
  case number = "source.lang.swift.syntaxtype.number"
  case objectLiteral = "source.lang.swift.syntaxtype.objectliteral"
  case parameter = "source.lang.swift.syntaxtype.parameter"
  case placeholder = "source.lang.swift.syntaxtype.placeholder"
  case string = "source.lang.swift.syntaxtype.string"
  case stringInterpolationAnchor = "source.lang.swift.syntaxtype.string_interpolation_anchor"
  case typeidentifier = "source.lang.swift.syntaxtype.typeidentifier"
  case poundDirectiveKeyword = "source.lang.swift.syntaxtype.pounddirective.keyword"
  case `operator` = "source.lang.swift.syntaxtype.operator"

  /// Syntax kinds that represent documentation comment content
  static let docComments: [SourceKitSyntaxKind] = [.commentURL, .docComment, .docCommentField]
}
