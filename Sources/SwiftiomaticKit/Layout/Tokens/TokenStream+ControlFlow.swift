//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension TokenStream {
    func visitLabeledStmt(_ node: LabeledStmtSyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .space)
        return .visitChildren
    }

    func visitIfExpr(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        // There may be a consistent breaking group around this node, see `CodeBlockItemSyntax`. This
        // group is necessary so that breaks around and inside of the conditions aren't forced to break
        // when the if-stmt spans multiple lines.
        before(node.conditions.firstToken(viewMode: .sourceAccurate), tokens: .open)
        after(node.conditions.lastToken(viewMode: .sourceAccurate), tokens: .close)

        after(node.ifKeyword, tokens: .space)

        // Add break groups, using open continuation breaks, around any conditions after the first so
        // that continuations inside of the conditions can stack in addition to continuations between
        // the conditions. There are no breaks around the first condition because if-statements look
        // better without a break between the "if" and the first condition.
        for condition in node.conditions.dropFirst() {
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: .continuation), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        if let elseKeyword = node.elseKeyword {
            // Add a token before the else keyword. Breaking before `else` is explicitly allowed when
            // there's a comment.
            if config[BeforeControlFlowKeywords.self] {
                before(elseKeyword, tokens: .break(.same, newlines: .soft))
            } else if elseKeyword.hasPrecedingLineComment {
                before(elseKeyword, tokens: .break(.same, size: 1))
            } else {
                before(elseKeyword, tokens: .space)
            }

            // Breaks are only allowed after `else` when there's a comment; otherwise there shouldn't be
            // any newlines between `else` and the open brace or a following `if`.
            if let tokenAfterElse = elseKeyword.nextToken(viewMode: .all),
                tokenAfterElse.hasPrecedingLineComment
            {
                after(node.elseKeyword, tokens: .break(.same, size: 1))
            } else if let elseBody = node.elseBody, elseBody.is(IfExprSyntax.self) {
                after(node.elseKeyword, tokens: .space)
            }
        }

        arrangeBracesAndContents(
            of: node.elseBody?.as(CodeBlockSyntax.self),
            contentsKeyPath: \.statements
        )

        return .visitChildren
    }

    func visitForStmt(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        // If we have a `(try) await` clause, allow breaking after the `for` so that the `(try) await`
        // can fall onto the next line if needed, and if both `try await` are present, keep them
        // together. Otherwise, keep `for` glued to the token after it so that we break somewhere later
        // on the line.
        if let awaitKeyword = node.awaitKeyword {
            after(node.forKeyword, tokens: .break)
            if let tryKeyword = node.tryKeyword {
                before(tryKeyword, tokens: .open)
                after(tryKeyword, tokens: .break)
                after(awaitKeyword, tokens: .close, .break)
            } else {
                after(awaitKeyword, tokens: .break)
            }
        } else {
            after(node.forKeyword, tokens: .space)
        }

        after(node.caseKeyword, tokens: .space)
        before(node.inKeyword, tokens: .break)
        after(node.inKeyword, tokens: .space)

        if let typeAnnotation = node.typeAnnotation {
            after(
                typeAnnotation.colon,
                tokens: .break(
                    .open(kind: .continuation),
                    newlines: .elective(ignoresDiscretionary: true)
                )
            )
            after(
                typeAnnotation.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        return .visitChildren
    }

    func visitWhileStmt(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        after(node.whileKeyword, tokens: .space)

        // Add break groups, using open continuation breaks, around any conditions after the first so
        // that continuations inside of the conditions can stack in addition to continuations between
        // the conditions. There are no breaks around the first condition because there was historically
        // not break after the while token and adding such a break would cause excessive changes to
        // previously formatted code.
        // This has the side effect that the label + `while` + tokens up to the first break in the first
        // condition could be longer than the column limit since there are no breaks between the label
        // or while token.
        for condition in node.conditions.dropFirst() {
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: .continuation), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        return .visitChildren
    }

    func visitRepeatStmt(_ node: RepeatStmtSyntax) -> SyntaxVisitorContinueKind {
        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        if config[BeforeControlFlowKeywords.self] {
            before(node.whileKeyword, tokens: .break(.same), .open)
            after(node.condition.lastToken(viewMode: .sourceAccurate), tokens: .close)
        } else {
            // The length of the condition needs to force the breaks around the braces of the repeat
            // stmt's body, so that there's always a break before the right brace when the while &
            // condition is too long to be on one line.
            before(node.whileKeyword, tokens: .space)
            // The `open` token occurs after the ending tokens for the braced `body` node.
            before(node.body.rightBrace, tokens: .open)
            after(node.condition.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
        after(node.whileKeyword, tokens: .space)
        return .visitChildren
    }

    func visitDoStmt(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        if node.throwsClause != nil {
            after(node.doKeyword, tokens: .break(.same, size: 1))
        }
        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
        return .visitChildren
    }

    func visitCatchClause(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        let catchPrecedingBreak =
            config[BeforeControlFlowKeywords.self]
            ? Token.break(.same, newlines: .soft) : Token.space
        before(node.catchKeyword, tokens: catchPrecedingBreak)

        // If there are multiple items in the `catch` clause, wrap each in open/close breaks so that
        // their internal breaks stack correctly. Otherwise, if there is only a single clause, use the
        // old (pre-SE-0276) behavior (a fixed space after the `catch` keyword).
        if node.catchItems.count > 1 {
            for catchItem in node.catchItems {
                before(
                    catchItem.firstToken(viewMode: .sourceAccurate),
                    tokens: .break(.open(kind: .continuation))
                )
                after(
                    catchItem.lastToken(viewMode: .sourceAccurate),
                    tokens: .break(.close(mustBreak: false), size: 0)
                )
            }
        } else {
            before(node.catchItems.firstToken(viewMode: .sourceAccurate), tokens: .space)
        }

        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        return .visitChildren
    }

    func visitDeferStmt(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
        return .visitChildren
    }

    func visitBreakStmt(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
        before(node.label, tokens: .break)
        return .visitChildren
    }

    func visitReturnStmt(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        if let expression = node.expression {
            if leftmostMultilineStringLiteral(of: expression) != nil {
                before(expression.firstToken(viewMode: .sourceAccurate), tokens: .break(.open))
                after(
                    expression.lastToken(viewMode: .sourceAccurate),
                    tokens: .break(.close(mustBreak: false))
                )
            } else {
                before(expression.firstToken(viewMode: .sourceAccurate), tokens: .break)
            }
        }
        return .visitChildren
    }

    func visitThrowStmt(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        before(node.expression.firstToken(viewMode: .sourceAccurate), tokens: .break)
        return .visitChildren
    }

    func visitContinueStmt(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
        before(node.label, tokens: .break)
        return .visitChildren
    }

    func visitSwitchExpr(_ node: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.switchKeyword, tokens: .open)
        after(node.switchKeyword, tokens: .space)
        before(node.leftBrace, tokens: .break(.reset))
        after(node.leftBrace, tokens: .close)

        // An if-configuration clause around a switch-case encloses the case's node, so an
        // if-configuration clause requires a break here in order to be allowed on a new line.
        for ifConfigDecl in node.cases where ifConfigDecl.is(IfConfigDeclSyntax.self) {
            if config[SwitchCaseIndentationConfiguration.self].style == .indented {
                before(ifConfigDecl.firstToken(viewMode: .sourceAccurate), tokens: .break(.open))
                after(
                    ifConfigDecl.lastToken(viewMode: .sourceAccurate),
                    tokens: .break(.close, size: 0)
                )
            } else {
                before(ifConfigDecl.firstToken(viewMode: .sourceAccurate), tokens: .break(.same))
            }
        }

        let newlines: NewlineBehavior =
            areBracesCompletelyEmpty(node, contentsKeyPath: \.cases) ? .elective : .soft
        before(node.rightBrace, tokens: .break(.same, size: 0, newlines: newlines))

        return .visitChildren
    }

    func visitSwitchCase(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        // If switch/case labels were configured to be indented, use an `open` break; otherwise, use
        // the default `same` break.
        let openBreak: Token
        if config[SwitchCaseIndentationConfiguration.self].style == .indented {
            openBreak = .break(.open, newlines: .elective)
        } else {
            openBreak = .break(.same, newlines: .soft)
        }
        before(node.firstToken(viewMode: .sourceAccurate), tokens: openBreak)

        after(node.attribute?.lastToken(viewMode: .sourceAccurate), tokens: .space)
        after(
            node.label.lastToken(viewMode: .sourceAccurate),
            tokens: .break(.reset, size: 0),
            .break(.open),
            .open
        )

        // If switch/case labels were configured to be indented, insert an extra `close` break after
        // the case body to match the `open` break above
        var afterLastTokenTokens: [Token] = [.break(.close, size: 0), .close]
        if config[SwitchCaseIndentationConfiguration.self].style == .indented {
            afterLastTokenTokens.append(.break(.close, size: 0))
        }

        // If the case contains statements, add the closing tokens after the last token of the case.
        // Otherwise, add the closing tokens before the next case (or the end of the switch) to have the
        // same effect. If instead the opening and closing tokens were omitted completely in the absence
        // of statements, comments within the empty case would be incorrectly indented to the same level
        // as the case label.
        if node.label.lastToken(viewMode: .sourceAccurate)
            != node.lastToken(viewMode: .sourceAccurate)
        {
            after(node.lastToken(viewMode: .sourceAccurate), tokens: afterLastTokenTokens)
        } else {
            before(node.nextToken(viewMode: .sourceAccurate), tokens: afterLastTokenTokens)
        }

        return .visitChildren
    }

    func visitSwitchCaseLabel(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
        before(node.caseKeyword, tokens: .open)
        after(node.caseKeyword, tokens: .space)

        // If an item with a `where` clause follows an item without a `where` clause, the compiler emits
        // a warning telling the user that they should insert a newline between them to disambiguate
        // their appearance. We enforce that "requirement" here to avoid spurious warnings, especially
        // following a `NoCasesWithOnlyFallthrough` transformation that might merge cases.
        let caseItems = Array(node.caseItems)
        for (index, item) in caseItems.enumerated() {
            before(item.firstToken(viewMode: .sourceAccurate), tokens: .open)
            if let trailingComma = item.trailingComma {
                // Insert a newline before the next item if it has a where clause and this item doesn't.
                let nextItemHasWhereClause =
                    index + 1 < caseItems.endIndex && caseItems[index + 1].whereClause != nil
                let requiresNewline = item.whereClause == nil && nextItemHasWhereClause
                let newlines: NewlineBehavior = requiresNewline ? .soft : .elective
                after(trailingComma, tokens: .close, .break(.continue, size: 1, newlines: newlines))
            } else {
                after(item.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        }

        after(node.colon, tokens: .close)
        closingDelimiterTokens.insert(node.colon)
        return .visitChildren
    }

    func visitYieldStmt(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind {
        // As of https://github.com/swiftlang/swift-syntax/pull/895, the token following a `yield` keyword
        // *must* be on the same line, so we cannot break here.
        after(node.yieldKeyword, tokens: .space)
        return .visitChildren
    }
}
