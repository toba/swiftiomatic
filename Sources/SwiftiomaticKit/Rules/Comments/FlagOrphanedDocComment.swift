import SwiftSyntax

/// Documentation comments must be attached to a declaration.
///
/// A `///` or `/** */` doc comment that is followed by a regular `//` or `/* */` comment instead of
/// a declaration is "orphaned" — the doc comment is detached from any code construct it could
/// document.
///
/// File-header style comments ( `////` and `/***` ) are excluded.
///
/// Lint: If a doc comment is orphaned, a lint warning is raised.
final class FlagOrphanedDocComment: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override static var key: String { "flagOrphanedDocComment" }
    override static var group: ConfigurationGroup? { .comments }

    override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        let pieces = token.leadingTrivia.pieces
        var iterator = pieces.enumerated().makeIterator()

        while let (index, piece) = iterator.next() {
            switch piece {
                case let .docLineComment(text), let .docBlockComment(text):
                    if text.hasPrefix("////") || text.hasPrefix("/***") { continue }

                    if Self.isOrphaned(after: &iterator) {
                        diagnose(.flagOrphanedDocComment, on: token, anchor: .leadingTrivia(index))
                    }
                default: continue
            }
        }
        return .visitChildren
    }

    private static func isOrphaned(
        after iterator: inout some IteratorProtocol<(offset: Int, element: TriviaPiece)>
    ) -> Bool {
        while let (_, piece) = iterator.next() {
            switch piece {
                case .docLineComment,
                     .docBlockComment,
                     .newlines,
                     .carriageReturns,
                     .carriageReturnLineFeeds,
                     .spaces,
                     .tabs:
                    continue
                case .lineComment, .blockComment: return true
                default: return false
            }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let flagOrphanedDocComment: Finding.Message = "doc comment is not attached to a declaration"
}
