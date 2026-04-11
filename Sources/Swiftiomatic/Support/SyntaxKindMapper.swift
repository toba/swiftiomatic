import SwiftIDEUtils
import SwiftSyntax

/// Maps ``SyntaxClassification`` values to ``SourceKitSyntaxKind``
///
/// Enables SwiftSyntax-based rules to perform kind filtering without
/// making any SourceKit calls.
enum SyntaxKindMapper {
  /// Converts a SwiftSyntax classification to the equivalent ``SourceKitSyntaxKind``
  ///
  /// - Parameters:
  ///   - classification: The SwiftSyntax classification to map.
  /// - Returns: The corresponding syntax kind, or `nil` for unmapped classifications.
  static func mapClassification(_ classification: SyntaxClassification) -> SourceKitSyntaxKind? {
    // sm:disable:previous cyclomatic_complexity
    switch classification {
    case .attribute:
      return .attributeID
    case .blockComment, .lineComment:
      return .comment
    case .docBlockComment, .docLineComment:
      return .docComment
    case .dollarIdentifier, .identifier:
      return .identifier
    case .editorPlaceholder:
      return .placeholder
    case .floatLiteral, .integerLiteral:
      return .number
    case .ifConfigDirective:
      return .poundDirectiveKeyword
    case .keyword:
      return .keyword
    case .none, .regexLiteral:
      return nil
    case .operator:
      return .operator
    case .stringLiteral:
      return .string
    case .type:
      return .typeidentifier
    case .argumentLabel:
      return .argument
    @unknown default:
      return nil
    }
  }

  /// Converts all syntax classifications in a ``SwiftSource`` file to ``ResolvedSyntaxToken`` values
  ///
  /// - Parameters:
  ///   - file: The source file whose classifications should be mapped.
  /// - Returns: An array of resolved syntax tokens with SourceKit-compatible kinds.
  static func sourceKitSyntaxKinds(for file: SwiftSource) -> [ResolvedSyntaxToken] {
    file.syntaxClassifications.compactMap { classifiedRange in
      guard let syntaxKind = mapClassification(classifiedRange.kind) else {
        return nil
      }

      let byteRange = classifiedRange.range.toSourceKitByteRange()
      let token = SyntaxToken(
        type: syntaxKind.rawValue,
        offset: byteRange.location,
        length: byteRange.length,
      )

      return ResolvedSyntaxToken(token: token)
    }
  }
}
