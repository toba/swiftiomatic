import SwiftSyntax

struct ConsecutiveSpacesRule {
    static let id = "consecutive_spaces"
    static let name = "Consecutive Spaces"
    static let summary = "Multiple consecutive spaces should be replaced with a single space"
    static let scope: Scope = .format
    static let isCorrectable = true
    static var nonTriggeringExamples: [Example] {
        [
            Example("let foo = 5"),
            Example("// comment with   multiple spaces"),
            Example("/* block   comment */"),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example("let↓  foo = 5"),
            Example("let foo =↓  5"),
        ]
    }

    static var corrections: [Example: Example] {
        [
            Example("let↓  foo = 5"): Example("let foo = 5"),
            Example("let foo =↓  5"): Example("let foo = 5"),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension ConsecutiveSpacesRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }

    func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
        Rewriter(configuration: options, file: file)
    }
}

extension ConsecutiveSpacesRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
            // Check leading trivia for consecutive spaces not after a linebreak
            checkTrivia(token.leadingTrivia, startPosition: token.position, afterLinebreak: true)
            // Check trailing trivia
            checkTrivia(
                token.trailingTrivia,
                startPosition: token.endPositionBeforeTrailingTrivia,
                afterLinebreak: false,
            )
            return .visitChildren
        }

        private func checkTrivia(
            _ trivia: Trivia, startPosition: AbsolutePosition, afterLinebreak: Bool,
        ) {
            var position = startPosition
            var afterLinebreak = afterLinebreak
            for piece in trivia {
                switch piece {
                    case let .spaces(count) where count > 1 && !afterLinebreak:
                        violations.append(position)
                    case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                        afterLinebreak = true
                    case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                        // Don't flag spaces inside comments
                        afterLinebreak = false
                    default:
                        if !piece.isWhitespace {
                            afterLinebreak = false
                        }
                }
                position = position.advanced(by: piece.sourceLength.utf8Length)
            }
        }
    }

    fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
        override func visit(_ token: TokenSyntax) -> TokenSyntax {
            let newLeading = collapseSpaces(token.leadingTrivia, afterLinebreak: true)
            let newTrailing = collapseSpaces(token.trailingTrivia, afterLinebreak: false)
            if newLeading != token.leadingTrivia || newTrailing != token.trailingTrivia {
                numberOfCorrections += 1
                return super.visit(
                    token.with(\.leadingTrivia, newLeading).with(\.trailingTrivia, newTrailing),
                )
            }
            return super.visit(token)
        }

        private func collapseSpaces(_ trivia: Trivia, afterLinebreak: Bool) -> Trivia {
            var pieces = [TriviaPiece]()
            var afterLinebreak = afterLinebreak
            var changed = false
            for piece in trivia {
                switch piece {
                    case let .spaces(count) where count > 1 && !afterLinebreak:
                        pieces.append(.spaces(1))
                        changed = true
                    case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                        afterLinebreak = true
                        pieces.append(piece)
                    case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                        afterLinebreak = false
                        pieces.append(piece)
                    default:
                        if !piece.isWhitespace {
                            afterLinebreak = false
                        }
                        pieces.append(piece)
                }
            }
            return changed ? Trivia(pieces: pieces) : trivia
        }
    }
}
