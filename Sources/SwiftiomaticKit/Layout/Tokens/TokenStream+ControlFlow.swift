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
    func visitLabeledStmt(_ node: LabeledStmtSyntax) -> SyntaxVisitorContinueKind {
        after(node.colon, tokens: .space)
        return .visitChildren
    }

    func visitIfExpr(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        // Outer group around the conditions. With multiple conditions, use `.consistent` so once
        // any condition wraps, every condition wraps. With a single condition, fall back to the
        // historical `.inconsistent` group (just so breaks around/inside aren't forced).
        let conditionsGroupStyle: GroupBreakStyle = node.conditions.count > 1
            ? .consistent : .inconsistent
        before(
            node.conditions.firstToken(viewMode: .sourceAccurate),
            tokens: .open(conditionsGroupStyle)
        )
        after(node.conditions.lastToken(viewMode: .sourceAccurate), tokens: .close)

        after(node.ifKeyword, tokens: .space)

        // Add break groups, using open continuation breaks, around any conditions after the first
        // so that continuations inside of the conditions can stack in addition to continuations
        // between the conditions. There are no breaks around the first condition because
        // if-statements look better without a break between the "if" and the first condition.
        let ifBreakKind: OpenBreakKind = config[AlignWrappedConditions.self]
            ? .alignment(spaces: 3)
            : .continuation

        for condition in node.conditions.dropFirst() {
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: ifBreakKind), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

        if let elseKeyword = node.elseKeyword {
            // Add a token before the else keyword. Breaking before `else` is explicitly allowed
            // when there's a comment.
            if config[ElseCatchOnNewLine.self] {
                before(elseKeyword, tokens: .break(.same, newlines: .soft))
            } else if elseKeyword.hasPrecedingLineComment {
                before(elseKeyword, tokens: .break(.same, size: 1))
            } else {
                before(elseKeyword, tokens: .space)
            }

            // Breaks are only allowed after `else` when there's a comment; otherwise there
            // shouldn't be any newlines between `else` and the open brace or a following `if` .
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
        // If we have a `(try) await` or `unsafe` clause, allow breaking after the `for` so that the
        // modifiers can fall onto the next line if needed, and if multiple modifiers are present,
        // keep them together. Otherwise, keep `for` glued to the token after it so that we break
        // somewhere later on the line.
        let modifiers = [node.tryKeyword, node.awaitKeyword, node.unsafeKeyword].compactMap { $0 }

        if let first = modifiers.first, let last = modifiers.last {
            after(node.forKeyword, tokens: .break)

            if modifiers.count == 1 {
                after(first, tokens: .break)
            } else {
                before(first, tokens: .open)
                for modifier in modifiers.dropLast() { after(modifier, tokens: .break) }
                after(last, tokens: .close, .break)
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

        // Outer consistent group: once any condition wraps, every condition wraps. Only useful with
        // multiple conditions.
        if node.conditions.count > 1 {
            before(
                node.conditions.firstToken(viewMode: .sourceAccurate),
                tokens: .open(.consistent)
            )
            after(node.conditions.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        // Add break groups, using open continuation breaks, around any conditions after the first
        // so that continuations inside of the conditions can stack in addition to continuations
        // between the conditions. There are no breaks around the first condition because there was
        // historically not break after the while token and adding such a break would cause
        // excessive changes to previously formatted code. This has the side effect that the label +
        // `while` + tokens up to the first break in the first condition could be longer than the
        // column limit since there are no breaks between the label or while token.
        let whileBreakKind: OpenBreakKind = config[AlignWrappedConditions.self]
            ? .alignment(spaces: 6)
            : .continuation

        for condition in node.conditions.dropFirst() {
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: whileBreakKind), size: 0)
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

        if config[ElseCatchOnNewLine.self] {
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
        if node.throwsClause != nil { after(node.doKeyword, tokens: .break(.same, size: 1)) }
        arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
        return .visitChildren
    }

    func visitCatchClause(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
        let catchPrecedingBreak = config[ElseCatchOnNewLine.self]
            ? Token.break(.same, newlines: .soft)
            : Token.space
        before(node.catchKeyword, tokens: catchPrecedingBreak)

        // If there are multiple items in the `catch` clause, wrap each in open/close breaks so that
        // their internal breaks stack correctly. Otherwise, if there is only a single clause, use
        // the old (pre-SE-0276) behavior (a fixed space after the `catch` keyword).
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
        if let expression = node.expression { arrangeKeywordOperandBreak(expression: expression) }
        return .visitChildren
    }

    func visitThrowStmt(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        arrangeKeywordOperandBreak(expression: node.expression)
        return .visitChildren
    }

    /// Emits the break between a statement keyword ( `return` , `throw` ) and its operand. For
    /// member-access chains and compound expressions, bounds the break's chunk via `.open` /
    /// `.close` so inner operator/ `.` breaks fire first — matches `arrangeAssignmentBreaks` .
    private func arrangeKeywordOperandBreak(expression: ExprSyntax) {
        if leftmostMultilineStringLiteral(of: expression) != nil {
            before(expression.firstToken(viewMode: .sourceAccurate), tokens: .break(.open))
            after(
                expression.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false))
            )
            return
        }

        let isCompound = isCompoundExpression(expression)
        let hasMemberChain = isMemberAccessChain(expression)
        let canGroupBeforeBreak = (isCompound || hasMemberChain)
            && !hasLeadingLineComments(expression)

        if canGroupBeforeBreak {
            before(
                expression.firstToken(viewMode: .sourceAccurate),
                tokens: .open, .break(.continue, newlines: .elective(ignoresDiscretionary: true))
            )
            after(expression.lastToken(viewMode: .sourceAccurate), tokens: .close)
        } else {
            before(expression.firstToken(viewMode: .sourceAccurate), tokens: .break)
        }
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
            if config[SwitchCaseIndentation.self].style == .indented {
                before(ifConfigDecl.firstToken(viewMode: .sourceAccurate), tokens: .break(.open))
                after(
                    ifConfigDecl.lastToken(viewMode: .sourceAccurate),
                    tokens: .break(.close, size: 0)
                )
            } else {
                before(ifConfigDecl.firstToken(viewMode: .sourceAccurate), tokens: .break(.same))
            }
        }

        let newlines: NewlineBehavior = areBracesCompletelyEmpty(node, contentsKeyPath: \.cases)
            ? .elective
            : .soft
        before(node.rightBrace, tokens: .break(.same, size: 0, newlines: newlines))

        return .visitChildren
    }

    func visitSwitchCase(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
        // If switch/case labels were configured to be indented, use an `open` break; otherwise, use
        // the default `same` break.
        let openBreak: Token
        openBreak = config[SwitchCaseIndentation.self].style == .indented
            ? .break(.open, newlines: .elective)
            : .break(.same, newlines: .soft)
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

        if config[SwitchCaseIndentation.self].style == .indented {
            afterLastTokenTokens.append(.break(.close, size: 0))
        }

        // If the case contains statements, add the closing tokens after the last token of the case.
        // Otherwise, add the closing tokens before the next case (or the end of the switch) to have
        // the same effect. If instead the opening and closing tokens were omitted completely in the
        // absence of statements, comments within the empty case would be incorrectly indented to
        // the same level as the case label.
        if node.label.lastToken(
            viewMode: .sourceAccurate
        )
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

        // Outer consistent group around case items: once any item wraps, every item wraps. The
        // matching `.close` is `after` the LAST item's last token (before the colon), keeping the
        // colon outside this group's force-break scope.
        let caseItems = Array(node.caseItems)

        if caseItems.count > 1 {
            before(
                caseItems.first!.firstToken(viewMode: .sourceAccurate),
                tokens: .open(.consistent)
            )
            after(caseItems.last!.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        // Mirror upstream's per-item structure (per-item `.open` / `.close` group, `.break` between
        // items via `after(trailingComma, ...)` ). With `AlignWrappedConditions` , upgrade the
        // inter-item break to `.break(.open(.alignment(5)))` so wrapped items align under the first
        // pattern (after `case ` ). To keep only ONE alignment scope active at a time (and
        // therefore a single shared alignment column for all wrapped items), each alignment-open
        // break is closed by a `.break(.close)` enqueued just before the NEXT alignment-open break
        // (or, for the final item, after the colon — outside the case-keyword group, so the colon
        // stays glued to the last pattern).
        //
        // Disambiguation: if an item with a `where` clause follows an item without one, the
        // compiler warns. Enforce a soft newline between such items to avoid the warning,
        // especially after `NoCasesWithOnlyFallthrough` transforms that might merge cases.
        let useAlignment = config[AlignWrappedConditions.self]
        var hasOpenAlignmentBreak = false

        for (index, item) in caseItems.enumerated() {
            before(item.firstToken(viewMode: .sourceAccurate), tokens: .open)

            if let trailingComma = item.trailingComma {
                let nextItemHasWhereClause = index + 1 < caseItems.endIndex
                    && caseItems[index + 1].whereClause != nil
                let requiresNewline = item.whereClause == nil && nextItemHasWhereClause
                let newlines: NewlineBehavior = requiresNewline ? .soft : .elective

                if useAlignment {
                    var afterTokens: [Token] = [.close]  // close per-item

                    if hasOpenAlignmentBreak {
                        afterTokens.append(.break(.close(mustBreak: false), size: 0))
                    }
                    afterTokens.append(
                        .break(
                            .open(kind: .alignment(spaces: 5)),
                            size: 1,
                            newlines: newlines
                        ))
                    after(trailingComma, tokens: afterTokens)
                    hasOpenAlignmentBreak = true
                } else {
                    after(
                        trailingComma,
                        tokens: .close,
                        .break(.continue, size: 1, newlines: newlines)
                    )
                }
            } else {
                // Final item: close per-item group at its last token.
                after(item.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        }

        // Close the final alignment-open AFTER the last item but BEFORE the colon, so that the
        // break-close lives outside the consistent-group's force-break scope (its `.close` was
        // appended above on the last item's last token) and BEFORE the body's `.break(.open)`
        // (added by `visitSwitchCase` 's `after(node.label.lastToken)` ), keeping break depth
        // properly nested.
        if hasOpenAlignmentBreak {
            after(
                caseItems.last!.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }
        after(node.colon, tokens: .close)  // closes the outermost `.open` for caseKeyword
        closingDelimiterTokens.insert(node.colon)
        return .visitChildren
    }

    func visitYieldStmt(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind {
        // As of https://github.com/swiftlang/swift-syntax/pull/895, the token following a `yield`
        // keyword *must* be on the same line, so we cannot break here.
        after(node.yieldKeyword, tokens: .space)
        return .visitChildren
    }
}
