// ===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors Licensed under Apache License
// v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information See https://swift.org/CONTRIBUTORS.txt
// for the list of Swift project authors
//
// ===----------------------------------------------------------------------===//

import SwiftSyntax

func isNestedInPostfixIfConfig(node: Syntax) -> Bool {
    var this: Syntax? = node

    while this?.parent != nil {
        // This guard handles the situation where a type with its own modifiers is nested inside of
        // an if config. That type should not count as being in a postfix if config because its
        // entire body is inside the if config.
        if this?.is(LabeledExprSyntax.self) == true { return false }

        if this?.is(IfConfigDeclSyntax.self) == true,
           this?.parent?.is(PostfixIfConfigExprSyntax.self) == true
        {
            return true
        }

        this = this?.parent
    }

    return false
}

/// Rewriter that relocates comment trivia around nodes where comments are known to be better
/// formatted when placed before or after the node.
///
/// For example, comments after binary operators are relocated to be before the operator, which
/// results in fewer line breaks with the comment closer to the relevant tokens.
final class CommentMovingRewriter: SyntaxRewriter {
    init(selection: Selection = .infinite) { self.selection = selection }

    private let selection: Selection

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        shouldFormatterIgnore(file: node) ? node : super.visit(node)
    }

    override func visit(_ node: CodeBlockItemSyntax) -> CodeBlockItemSyntax {
        shouldFormatterIgnore(node: Syntax(node)) || !Syntax(node).isInsideSelection(selection)
            ? node
            : super.visit(node)
    }

    override func visit(_ node: MemberBlockItemSyntax) -> MemberBlockItemSyntax {
        shouldFormatterIgnore(node: Syntax(node)) || !Syntax(node).isInsideSelection(selection)
            ? node
            : super.visit(node)
    }

    override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
        var node = super.visit(node).as(InfixOperatorExprSyntax.self)!
        guard node.rightOperand.hasAnyPrecedingComment else { return ExprSyntax(node) }

        // Rearrange the comments around the operators to make it easier to break properly later.
        // Since we break on the left of operators (except for assignment), line comments between an
        // operator and the right-hand-side of an expression should be moved to the left of the
        // operator. Block comments can remain where they're originally located since they don't
        // force breaks.
        let operatorLeading = node.operator.leadingTrivia
        var operatorTrailing = node.operator.trailingTrivia
        let rhsLeading = node.rightOperand.leadingTrivia

        let operatorTrailingLineComment: Trivia

        if operatorTrailing.hasLineComment {
            operatorTrailingLineComment = [operatorTrailing.pieces.last!]
            operatorTrailing = Trivia(pieces: operatorTrailing.dropLast())
        } else {
            operatorTrailingLineComment = []
        }

        if operatorLeading.containsNewlines {
            node.operator.leadingTrivia = operatorLeading + operatorTrailingLineComment + rhsLeading
            node.operator.trailingTrivia = operatorTrailing
        } else {
            node.leftOperand.trailingTrivia += operatorTrailingLineComment
            node.operator.leadingTrivia = rhsLeading
            node.operator.trailingTrivia = operatorTrailing
        }
        node.rightOperand.leadingTrivia = []

        return ExprSyntax(node)
    }

    /// Extracts trivia containing and related to line comments from `token` 's leading trivia.
    /// Returns 2 trivia collections: the trivia that wasn't extracted and should remain in `token`
    /// 's leading trivia and the trivia that meets the criteria for extraction.
    /// - Parameter token: A token whose leading trivia should be split to extract line comments.
    private func extractLineCommentTrivia(
        from token: TokenSyntax
    ) -> (remainingTrivia: Trivia, extractedTrivia: Trivia) {
        var pendingPieces = [TriviaPiece]()
        var keepWithTokenPieces = [TriviaPiece]()
        var extractingPieces = [TriviaPiece]()

        // Line comments and adjacent newlines are extracted so they can be moved to a different
        // token's leading trivia, while all other kinds of tokens are left as-is.
        var lastPiece: TriviaPiece?

        for piece in token.leadingTrivia {
            defer { lastPiece = piece }

            switch piece {
                case .lineComment:
                    extractingPieces.append(contentsOf: pendingPieces)
                    pendingPieces.removeAll()
                    extractingPieces.append(piece)
                case .blockComment, .docLineComment, .docBlockComment:
                    keepWithTokenPieces.append(contentsOf: pendingPieces)
                    pendingPieces.removeAll()
                    keepWithTokenPieces.append(piece)
                case .newlines, .carriageReturns, .carriageReturnLineFeeds:
                    if case .lineComment = lastPiece {
                        extractingPieces.append(piece)
                    } else {
                        pendingPieces.append(piece)
                    }
                default: pendingPieces.append(piece)
            }
        }
        keepWithTokenPieces.append(contentsOf: pendingPieces)
        return (Trivia(pieces: keepWithTokenPieces), Trivia(pieces: extractingPieces))
    }
}

/// Returns whether the given trivia includes a directive to ignore formatting for the next node.
///
/// - Parameter trivia: Leading trivia for a node that the formatter supports ignoring.
/// - Returns: Whether the trivia contains a `sm:ignore` directive.
func isFormatterIgnorePresent(inTrivia trivia: Trivia) -> Bool {
    func isFormatterIgnore(in commentText: String, prefix: String, suffix: String) -> Bool {
        let trimmed = commentText.dropFirst(prefix.count)
            .dropLast(suffix.count)
            .trimmingCharacters(in: .whitespaces)
        return trimmed == "sm:ignore"
    }

    for piece in trivia {
        switch piece {
            case let .lineComment(text):
                if isFormatterIgnore(in: text, prefix: "//", suffix: "") { return true }
            case let .blockComment(text):
                if isFormatterIgnore(in: text, prefix: "/*", suffix: "*/") { return true }
            default: break
        }
    }
    return false
}

/// Returns whether the formatter should ignore the given node by printing it without changing the
/// node's internal text representation (i.e. print all text inside of the node as it was in the
/// original source).
///
/// - Note: The caller is responsible for ensuring that the given node is a type of node that can
/// be safely ignored.
///
/// - Parameter node: A node that can be safely ignored.
func shouldFormatterIgnore(node: Syntax) -> Bool {
    isFormatterIgnorePresent(inTrivia: node.allPrecedingTrivia)
}

/// Returns whether the formatter should ignore the given file by printing it without changing the
/// any if its nodes' internal text representation (i.e. print all text inside of the file as it was
/// in the original source).
///
/// - Parameter file: The root syntax node for a source file.
func shouldFormatterIgnore(file: SourceFileSyntax) -> Bool {
    isFormatterIgnorePresent(inTrivia: file.allPrecedingTrivia)
}
