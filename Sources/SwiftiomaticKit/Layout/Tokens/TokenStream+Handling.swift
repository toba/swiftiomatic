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

extension TokenStream {
    func visitToken(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
        // Arrange the tokens and trivia such that before tokens that start a new "scope" (which may
        // increase indentation) are inserted in the stream *before* the leading trivia, but tokens
        // that end an existing "scope" (which may reduce indentation) are inserted *after* the
        // leading trivia. In general, comments before a token should included in the same scope as
        // the token.
        let (openScopeTokens, closeScopeTokens) = splitScopingBeforeTokens(of: token)
        openScopeTokens.forEach(appendToken)
        extractLeadingTrivia(token)
        closeScopeTokens.forEach(appendToken)

        generateEnableFormattingIfNecessary(
            token.positionAfterSkippingLeadingTrivia..<token.endPositionBeforeTrailingTrivia
        )

        if !ignoredTokens.contains(token) {
            appendToken(.syntax(token.presence == .present ? token.text : ""))
        }

        generateDisableFormattingIfNecessary(token.endPositionBeforeTrailingTrivia)

        appendTrailingTrivia(token)
        appendAfterTokensAndTrailingComments(token)

        // It doesn't matter what we return here, tokens do not have children.
        return .skipChildren
    }

    func generateEnableFormattingIfNecessary(_ range: Range<AbsolutePosition>) {
        if case .infinite = selection { return }

        if !isInsideSelection, selection.overlapsOrTouches(range) {
            appendToken(.enableFormatting(range.lowerBound))
            isInsideSelection = true
        }
    }

    func generateDisableFormattingIfNecessary(_ position: AbsolutePosition) {
        if case .infinite = selection { return }

        if isInsideSelection, !selection.contains(position) {
            appendToken(.disableFormatting(position))
            isInsideSelection = false
        }
    }

    /// Appends the before-tokens of the given syntax token to the token stream.
    func appendBeforeTokens(_ token: TokenSyntax) {
        if let before = beforeMap.removeValue(forKey: token) { before.forEach(appendToken) }
    }

    /// Handle trailing trivia that might contain garbage text that we don't want to
    /// indiscriminantly discard.
    ///
    /// In syntactically valid code, trailing trivia will only contain spaces or tabs, so we can
    /// usually ignore it entirely. If there is garbage text after a token, however, then we
    /// preserve it (and any whitespace immediately before it) and "glue" it to the end of the
    /// preceding token using a `verbatim` formatting token. Any whitespace following the last
    /// garbage text in the trailing trivia will be discarded, with the assumption that the
    /// formatter will have inserted some kind of break there that would be more appropriate (and we
    /// want to avoid inserting trailing whitespace on a line).
    ///
    /// The choices above are admittedly somewhat arbitrary, but given that garbage text in trailing
    /// trivia represents a malformed input (as opposed to garbage text in leading trivia, which has
    /// some legitimate uses), this is a reasonable compromise to keep the garbage text roughly in
    /// the same place but still let surrounding formatting occur somewhat as expected.
    func appendTrailingTrivia(_ token: TokenSyntax, forced: Bool = false) {
        let trailingTrivia = Array(partitionTrailingTrivia(token.trailingTrivia).0)
        let lastIndex: Array<Trivia>.Index

        if forced {
            lastIndex = trailingTrivia.index(before: trailingTrivia.endIndex)
        } else {
            guard let lastUnexpectedIndex = trailingTrivia.lastIndex(where: { $0.isUnexpectedText })
            else { return }
            lastIndex = lastUnexpectedIndex
        }

        var verbatimText = ""

        for piece in trailingTrivia[...lastIndex] {
            switch piece {
                case .unexpectedText, .spaces, .tabs, .formfeeds, .verticalTabs:
                    piece.write(to: &verbatimText)
                default: break
            }
        }

        appendToken(.verbatim(Verbatim(text: verbatimText, indentingBehavior: .none)))
    }

    /// Appends the after-tokens and trailing comments (if present) of the given syntax token to the
    /// token stream.
    ///
    /// After-tokens require special care because the location of trailing comments (being in the
    /// trivia of the *next* token) sometimes can interfere with the ordering of formatting tokens
    /// being enqueued during visitation. Specifically:
    ///
    /// * If the trailing comment is a block comment, we append it first to the stream before any
    ///   other formatting tokens. This keeps the comment closely bound to the syntax token
    ///   preceding it; for example, if the comment occurs after the last token in a group, it will
    ///   stay inside the group.
    ///
    /// * If the trailing comment is a line comment, we first append any enqueued after-tokens that
    ///   are *not* related to breaks or newlines (e.g. includes print control tokens), then we
    ///   append the comment, and then the remaining after-tokens. Due to visitation ordering, this
    ///   ensures that a trailing line comment is not incorrectly inserted into the token stream
    ///   *after* a break or newline.
    func appendAfterTokensAndTrailingComments(_ token: TokenSyntax) {
        let (wasLineComment, trailingCommentTokens) = afterTokensForTrailingComment(token)
        let afterGroups = afterMap.removeValue(forKey: token) ?? []
        var hasAppendedTrailingComment = false

        if !wasLineComment { trailingCommentTokens.forEach(appendToken) }

        for after in afterGroups.reversed() {
            for afterToken in after {
                var shouldExtractTrailingComment = false

                if wasLineComment, !hasAppendedTrailingComment {
                    switch afterToken {
                        case .break(let kind, _, _):
                            if case let .close(mustBreak) = kind {
                                shouldExtractTrailingComment = mustBreak
                            } else {
                                shouldExtractTrailingComment = true
                            }
                        case .printerControl: shouldExtractTrailingComment = true
                        default: break
                    }
                }
                if shouldExtractTrailingComment {
                    trailingCommentTokens.forEach(appendToken)
                    hasAppendedTrailingComment = true
                }
                appendToken(afterToken)
            }
        }

        if wasLineComment, !hasAppendedTrailingComment {
            trailingCommentTokens.forEach(appendToken)
        }
    }
}
