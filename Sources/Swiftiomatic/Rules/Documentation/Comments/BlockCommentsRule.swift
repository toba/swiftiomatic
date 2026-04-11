import SwiftSyntax

struct BlockCommentsRule {
    static let id = "block_comments"
    static let name = "Block Comments"
    static let summary = "Block comments (`/* */`) should be converted to line comments (`//`)"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
            Example(
                """
                // A comment
                // on multiple lines
                """,
            ).skipMultiByteOffsetTest(),
            Example(
                """
                /// A doc comment
                func foo() {}
                """,
            ).skipMultiByteOffsetTest(),
        ]
    }

    static var triggeringExamples: [Example] {
        [
            Example(
                """
                ↓/* A comment
                   on multiple lines */
                """,
            ).skipWrappingInCommentTest().skipWrappingInStringTest().skipMultiByteOffsetTest(),
        ]
    }

    var options = SeverityOption<Self>(.warning)
}

extension BlockCommentsRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
        Visitor(configuration: options, file: file)
    }
}

extension BlockCommentsRule {
    fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
        override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
            checkTrivia(node.leadingTrivia, at: node.position)
            return .visitChildren
        }

        private func checkTrivia(_ trivia: Trivia, at basePosition: AbsolutePosition) {
            var offset = basePosition
            for piece in trivia {
                switch piece {
                    case .blockComment:
                        violations.append(offset)
                    default:
                        break
                }
                offset = offset.advanced(by: piece.sourceLength.utf8Length)
            }
        }
    }
}
