import Foundation
import SwiftSyntax

struct ColonRule {
    static let id = "colon"
    static let name = "Colon Spacing"
    static let summary = ""
    static let isCorrectable = true
    var options = ColonOptions()
}

extension ColonRule: SwiftSyntaxCorrectableRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        private var positionsToSkip: Set<AbsolutePosition> = []
        private var dictionaryPositions: Set<AbsolutePosition> = []
        private var caseStatementPositions: Set<AbsolutePosition> = []

        // MARK: - Collect positions to skip (pre-order so they're available when tokens are visited)

        override func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
            positionsToSkip.insert(node.colon.position)
            return .visitChildren
        }

        override func visit(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind {
            for token in node.tokens(viewMode: .sourceAccurate) where token.tokenKind == .colon {
                positionsToSkip.insert(token.position)
            }
            return .visitChildren
        }

        override func visit(_ node: ObjCSelectorPieceSyntax) -> SyntaxVisitorContinueKind {
            if let colon = node.colon {
                positionsToSkip.insert(colon.position)
            }
            return .visitChildren
        }

        override func visit(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind {
            positionsToSkip.insert(node.colon.position)
            return .visitChildren
        }

        override func visit(_ node: UnresolvedTernaryExprSyntax) -> SyntaxVisitorContinueKind {
            positionsToSkip.insert(node.colon.position)
            return .visitChildren
        }

        override func visit(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind {
            dictionaryPositions.insert(node.colon.position)
            return .visitChildren
        }

        override func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
            caseStatementPositions.insert(node.colon.position)
            return .visitChildren
        }

        override func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
            caseStatementPositions.insert(node.colon.position)
            return .visitChildren
        }

        // MARK: - Check colon tokens

        override func visitPost(_ token: TokenSyntax) {
            guard token.tokenKind == .colon else { return }

            if positionsToSkip.contains(token.position) { return }
            if !configuration.applyToDictionaries,
               dictionaryPositions.contains(token.position)
            {
                return
            }

            guard let previous = token.previousToken(viewMode: .sourceAccurate),
                  let next = token.nextToken(viewMode: .sourceAccurate)
            else { return }

            // [:] — empty dictionary literal
            if previous.tokenKind == .leftSquare,
               next.tokenKind == .rightSquare,
               previous.trailingTrivia.isEmpty,
               token.leadingTrivia.isEmpty,
               token.trailingTrivia.isEmpty,
               next.leadingTrivia.isEmpty
            {
                return
            }

            // Space before colon: previous token has trailing trivia (but not block comments)
            if previous.trailingTrivia.isNotEmpty,
               !previous.trailingTrivia.containsBlockComments()
            {
                let start = previous.endPositionBeforeTrailingTrivia
                let end = token.endPosition
                violations.append(
                    SyntaxViolation(
                        position: start,
                        severity: configuration.severity,
                        correction: .init(start: start, end: end, replacement: ": "),
                    ),
                )
                return
            }

            // Wrong or missing space after colon
            if token.trailingTrivia != [.spaces(1)],
               !next.leadingTrivia.containsNewlines()
            {
                if case .spaces(1) = token.trailingTrivia.first {
                    return
                }

                let flexibleRightSpacing =
                    configuration.flexibleRightSpacing
                        || caseStatementPositions.contains(token.position)
                if flexibleRightSpacing, token.trailingTrivia.isNotEmpty {
                    return
                }

                let extraBytes: Int
                if case let .spaces(spaces) = token.trailingTrivia.first {
                    extraBytes = spaces
                } else {
                    extraBytes = 0
                }

                let start = token.position
                let end = AbsolutePosition(utf8Offset: token.position.utf8Offset + 1 + extraBytes)
                violations.append(
                    SyntaxViolation(
                        position: token.position,
                        severity: configuration.severity,
                        correction: .init(start: start, end: end, replacement: ": "),
                    ),
                )
            }
        }
    }
}

extension Trivia {
    fileprivate func containsBlockComments() -> Bool {
        contains { piece in
            if case .blockComment = piece {
                return true
            }
            return false
        }
    }
}
