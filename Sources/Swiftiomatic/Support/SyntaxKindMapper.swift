import SwiftSyntax
import SwiftIDEUtils

/// Maps SwiftSyntax classifications to SourceKit syntax kinds.
/// This enables SwiftSyntax-based custom rules to work with kind filtering
/// without making any SourceKit calls.
enum SyntaxKindMapper {
    /// Map a SwiftSyntax classification to SourceKit syntax kind.
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

    /// Convert SwiftSyntax syntax classifications to SourceKit-compatible syntax tokens.
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
