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

import SwiftOperators
import SwiftSyntax

extension TokenStream {
    func extractLeadingTrivia(_ token: TokenSyntax) {
        var isStartOfFile: Bool
        let trivia: Trivia
        var position = token.position
        if let previousToken = token.previousToken(viewMode: .sourceAccurate) {
            isStartOfFile = false
            // Find the first non-whitespace in the previous token's trailing and peel those off.
            let (_, prevTrailingComments) = partitionTrailingTrivia(previousToken.trailingTrivia)
            let prevTrivia = Trivia(pieces: prevTrailingComments)
            trivia = prevTrivia + token.leadingTrivia
            position -= prevTrivia.sourceLength
        } else {
            isStartOfFile = true
            trivia = token.leadingTrivia
        }

        // If we're at the end of the file, determine at which index to stop checking trivia pieces to
        // prevent trailing newlines.
        var cutoffIndex: Int? = nil
        if token.tokenKind == TokenKind.endOfFile {
            cutoffIndex = 0
            for (index, piece) in trivia.enumerated() {
                switch piece {
                case .newlines(_), .carriageReturns(_), .carriageReturnLineFeeds(_):
                    continue
                default:
                    cutoffIndex = index + 1
                }
            }
        }

        // Updated throughout the loop to indicate whether the next newline *must* be honored (for
        // example, even if discretionary newlines are discarded). This is the case when the preceding
        // trivia was a line comment or garbage text.
        var requiresNextNewline = false
        // Tracking whether or not the last piece was leading indentation. A newline is considered
        // a 0-space indentation; used for nesting/un-nesting block comments during formatting.
        var leadingIndent: Indent? = nil

        for (index, piece) in trivia.enumerated() {
            if let cutoff = cutoffIndex, index == cutoff { break }

            switch piece {
            case .lineComment(let text):
                if index > 0 || isStartOfFile {
                    generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                    appendToken(
                        .comment(
                            Comment(kind: .line, leadingIndent: leadingIndent, text: text),
                            wasEndOfLine: false
                        )
                    )
                    generateDisableFormattingIfNecessary(position + piece.sourceLength)
                    appendNewlines(.soft)
                    isStartOfFile = false
                }
                requiresNextNewline = true
                leadingIndent = nil

            case .blockComment(let text):
                if index > 0 || isStartOfFile {
                    let isStandaloneLeadingComment = leadingIndent != nil || isStartOfFile
                    generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                    appendToken(
                        .comment(
                            Comment(kind: .block, leadingIndent: leadingIndent, text: text),
                            wasEndOfLine: false
                        )
                    )
                    generateDisableFormattingIfNecessary(position + piece.sourceLength)
                    // There is always a break after the comment to allow a discretionary newline after it.
                    var breakSize = 0
                    if index + 1 < trivia.endIndex {
                        let nextPiece = trivia[index + 1]
                        // The original number of spaces is intentionally discarded, but 1 space is allowed in
                        // case the comment is followed by another token instead of a newline.
                        if case .spaces = nextPiece { breakSize = 1 }
                    }
                    appendToken(.break(.same, size: breakSize))
                    isStartOfFile = false
                    requiresNextNewline = isStandaloneLeadingComment
                } else {
                    requiresNextNewline = false
                }
                leadingIndent = nil

            case .docLineComment(let text):
                generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                appendToken(
                    .comment(
                        Comment(kind: .docLine, leadingIndent: leadingIndent, text: text),
                        wasEndOfLine: false
                    )
                )
                generateDisableFormattingIfNecessary(position + piece.sourceLength)
                appendNewlines(.soft)
                isStartOfFile = false
                requiresNextNewline = true
                leadingIndent = nil

            case .docBlockComment(let text):
                generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                appendToken(
                    .comment(
                        Comment(kind: .docBlock, leadingIndent: leadingIndent, text: text),
                        wasEndOfLine: false
                    )
                )
                generateDisableFormattingIfNecessary(position + piece.sourceLength)
                appendNewlines(.soft)
                isStartOfFile = false
                requiresNextNewline = false
                leadingIndent = nil

            case .newlines(let count), .carriageReturns(let count),
                .carriageReturnLineFeeds(let count):
                if config[IndentBlankLines.self],
                    let leadingIndent, leadingIndent.count > 0
                {
                    requiresNextNewline = true
                }

                leadingIndent = .spaces(0)
                guard !isStartOfFile else { break }

                if requiresNextNewline
                    || (config[RespectsExistingLineBreaks.self]
                        && isDiscretionaryNewlineAllowed(before: token))
                {
                    appendNewlines(.soft(count: count, discretionary: true))
                } else {
                    // Even if discretionary line breaks are not being respected, we still respect multiple
                    // line breaks in order to keep blank separator lines that the user might want.
                    // TODO: It would be nice to restrict this to only allow multiple lines between statements
                    // and declarations; as currently implemented, multiple newlines will locally ignore the
                    // configuration setting.
                    if count > 1 {
                        appendNewlines(.soft(count: count, discretionary: true))
                    }
                }

            case .unexpectedText(let text):
                // Garbage text in leading trivia might be something meaningful that would be disruptive to
                // throw away when formatting the file, like a hashbang line or Unicode byte-order marker at
                // the beginning of a file, or source control conflict markers. Keep it as verbatim text so
                // that it is printed exactly as we got it.
                appendToken(.verbatim(Verbatim(text: text, indentingBehavior: .none)))

                // Unicode byte-order markers shouldn't allow leading newlines to otherwise appear in the
                // file, nor should they modify our detection of the beginning of the file.
                let isBOM = text == "\u{feff}"
                requiresNextNewline = !isBOM
                isStartOfFile = isStartOfFile && isBOM
                leadingIndent = nil

            case .backslashes, .formfeeds, .pounds, .verticalTabs:
                leadingIndent = nil

            case .spaces(let n):
                guard leadingIndent == .spaces(0) else { break }
                leadingIndent = .spaces(n)

            case .tabs(let n):
                guard leadingIndent == .spaces(0) else { break }
                leadingIndent = .tabs(n)
            }
            position += piece.sourceLength
        }
    }

    /// Appends the newlines to the token stream.
    ///
    /// The newlines will be inserted using one of the following approaches:
    /// - As a new break, whose kind is compatible with the most recent break.
    /// - Overwriting the newlines of the most recent break.
    /// - Appending to the newlines of the most recent break.
    func appendNewlines(_ newlines: NewlineBehavior) {
        guard let lastBreakIndex = lastBreakIndex else {
            // When there haven't been any breaks yet, there can't be any indentation to maintain so a
            // same break is safe here.
            appendToken(.break(.same, size: 0, newlines: newlines))
            return
        }

        let lastBreak = tokens[lastBreakIndex]
        guard case .break(let kind, let size, let existingNewlines) = lastBreak else {
            fatalError("Found non-break token at lastBreakIndex. TokenStream is invalid.")
        }

        guard !canMergeNewlinesIntoLastBreak else {
            tokens[lastBreakIndex] = .break(kind, size: size, newlines: existingNewlines + newlines)
            return
        }

        // Otherwise, create and insert a new break whose `kind` is compatible with last break.
        let compatibleKind: BreakKind
        switch kind {
        case .open, .close, .reset, .same:
            compatibleKind = .same
        case .continue, .contextual:
            compatibleKind = kind
        }
        appendToken(.break(compatibleKind, size: 0, newlines: newlines))
    }

    /// Appends a formatting token to the token stream.
    ///
    /// This function also handles collapsing neighboring tokens in situations where that is
    /// desired, like merging adjacent comments and newlines.
    func appendToken(_ token: Token) {
        func breakAllowsCommentMerge(_ breakKind: BreakKind) -> Bool {
            return breakKind == .same || breakKind == .continue || breakKind == .contextual
        }

        if let last = tokens.last {
            switch (last, token) {
            case (.break(_, _, .escaped), _), (_, .break(_, _, .escaped)):
                lastBreakIndex = tokens.endIndex
                // Don't allow merging for .escaped breaks
                canMergeNewlinesIntoLastBreak = false
                tokens.append(token)
                return
            case (.break(let breakKind, _, .soft(1, _)), .comment(let c2, _))
            where breakAllowsCommentMerge(breakKind) && (c2.kind == .docLine || c2.kind == .line):
                // we are search for the pattern of [line comment] - [soft break 1] - [line comment]
                // where the comment type is the same; these can be merged into a single comment
                if let nextToLast = tokens.dropLast().last,
                    case .comment(let c1, false) = nextToLast,
                    c1.kind == c2.kind
                {
                    var mergedComment = c1
                    mergedComment.addText(c2.text)
                    tokens.removeLast()  // remove the soft break
                    // replace the original comment with the merged one
                    tokens[tokens.count - 1] = .comment(mergedComment, wasEndOfLine: false)

                    // need to fix lastBreakIndex because we just removed the last break
                    lastBreakIndex = tokens.lastIndex(where: {
                        switch $0 {
                        case .break: return true
                        default: return false
                        }
                    })
                    canMergeNewlinesIntoLastBreak = false

                    return
                }

            // If we see a pair of spaces where one or both are flexible, combine them into a new token
            // with the maximum of their counts.
            case (.space(let first, let firstFlexible), .space(let second, let secondFlexible))
            where firstFlexible || secondFlexible:
                tokens[tokens.count - 1] = .space(size: max(first, second), flexible: true)
                return

            default:
                break
            }
        }

        switch token {
        case .break:
            lastBreakIndex = tokens.endIndex
            canMergeNewlinesIntoLastBreak = true
        case .open, .printerControl, .contextualBreakingStart, .enableFormatting,
            .disableFormatting:
            break
        default:
            canMergeNewlinesIntoLastBreak = false
        }
        tokens.append(token)
    }

    /// Returns true if the first token of the given node is an open delimiter that may desire
    /// special breaking behavior in some cases.
    func startsWithOpenDelimiter(_ node: Syntax) -> Bool {
        guard let token = node.firstToken(viewMode: .sourceAccurate) else { return false }
        switch token.tokenKind {
        case .leftBrace, .leftParen, .leftSquare: return true
        default: return false
        }
    }

    /// Returns true if open/close breaks should be inserted around the entire function call argument
    /// list.
    func shouldGroupAroundArgumentList(_ arguments: LabeledExprListSyntax) -> Bool {
        let argumentCount = arguments.count

        // If there are no arguments, there's no reason to break.
        if argumentCount == 0 { return false }

        // If there is more than one argument, we must open/close break around the whole list.
        if argumentCount > 1 { return true }

        return !isCompactSingleFunctionCallArgument(arguments)
    }

    /// Returns whether the `reset` break before an expression's closing delimiter must break when
    /// it's on a different line than the opening delimiter.
    /// - Parameters:
    ///   - expr: An expression that includes opening and closing delimiters and arguments.
    ///   - argumentListPath: A key path for accessing the expression's function call argument list.
    func mustBreakBeforeClosingDelimiter<T: ExprSyntaxProtocol>(
        of expr: T,
        argumentListPath: KeyPath<T, LabeledExprListSyntax>
    ) -> Bool {
        guard
            let parent = expr.parent,
            parent.is(MemberAccessExprSyntax.self) || parent.is(PostfixIfConfigExprSyntax.self)
        else { return false }

        let argumentList = expr[keyPath: argumentListPath]

        // When there's a single compact argument, there is no extra indentation for the argument and
        // the argument's own internal reset break will reset indentation.
        return !isCompactSingleFunctionCallArgument(argumentList)
    }

    /// Returns true if the argument list can be compacted, even if it spans multiple lines (where
    /// compact means that it can start immediately after the open parenthesis).
    ///
    /// This is true for any argument list that contains a single argument (labeled or unlabeled) that
    /// is an array, dictionary, or closure literal.
    func isCompactSingleFunctionCallArgument(_ argumentList: LabeledExprListSyntax) -> Bool {
        guard argumentList.count == 1 else { return false }

        let expression = argumentList.first!.expression
        return expression.is(ArrayExprSyntax.self) || expression.is(DictionaryExprSyntax.self)
            || expression.is(ClosureExprSyntax.self)
    }

    /// Adds a grouping around certain subexpressions during `InfixOperatorExpr` visitation.
    ///
    /// Adding groups around these expressions allows them to prefer breaking onto a newline before
    /// the expression, keeping the entire expression together when possible, before breaking inside
    /// the expression. This is a hand-crafted list of expressions that generally look better when the
    /// break(s) before the expression fire before breaks inside of the expression.
    func maybeGroupAroundSubexpression(
        _ expr: ExprSyntax,
        combiningOperator operatorExpr: ExprSyntax? = nil
    ) {
        switch Syntax(expr).kind {
        case .memberAccessExpr, .subscriptCallExpr:
            before(expr.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(expr.lastToken(viewMode: .sourceAccurate), tokens: .close)
        default:
            break
        }

        // When a function call expression is assigned to an lvalue, we omit the group around the
        // function call so that the callee and open parenthesis can remain on the same line, if they
        // fit. This is a frequent enough case that the outcome looks better with the exception in
        // place.
        if expr.is(FunctionCallExprSyntax.self),
            let operatorExpr = operatorExpr, !isAssigningOperator(operatorExpr)
        {
            before(expr.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(expr.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
    }

    /// Returns whether the given expression consists of multiple subexpressions. Certain expressions
    /// that are known to wrap an expression, e.g. try expressions, are handled by checking the
    /// expression that they contain.
    func isCompoundExpression(_ expr: ExprSyntax) -> Bool {
        if let modifiedExpr = expr.asProtocol(KeywordModifiedExprSyntax.self) {
            return isCompoundExpression(modifiedExpr.expression)
        }
        switch Syntax(expr).as(SyntaxEnum.self) {
        case .infixOperatorExpr, .ternaryExpr, .isExpr, .asExpr:
            return true
        case .tupleExpr(let tupleExpr) where tupleExpr.elements.count == 1:
            return isCompoundExpression(tupleExpr.elements.first!.expression)
        default:
            return false
        }
    }

    /// Returns whether the given expression is or begins with a member access chain (e.g.
    /// `foo.bar(...)`, `foo.bar(...).baz(...)`). Used to detect method-chaining RHS expressions
    /// in assignments so the formatter prefers breaking at dots rather than after `=`.
    func isMemberAccessChain(_ expr: ExprSyntax) -> Bool {
        if let callingExpr = expr.asProtocol(CallingExprSyntax.self) {
            return callingExpr.calledExpression.is(MemberAccessExprSyntax.self)
                || isMemberAccessChain(callingExpr.calledExpression)
        }
        return expr.is(MemberAccessExprSyntax.self)
    }

    /// Whether an expression should use break precedence — `ignoresDiscretionary` + open/close
    /// grouping — so the formatter prefers inner operator breaks over the enclosing break position.
    /// Used for both assignment (`=`) and keyword (`guard`) breaks.
    func shouldApplyBreakPrecedence(_ expr: ExprSyntax) -> Bool {
        isCompoundExpression(expr)
            && leftmostMultilineStringLiteral(of: expr) == nil
            && !hasLeadingLineComments(expr)
    }

    /// Returns whether the given expression has line or block comments in the leading trivia of its
    /// first token. When comments are present between `=` and the RHS expression, grouping the open
    /// before the break disrupts comment indentation.
    func hasLeadingLineComments(_ expr: ExprSyntax) -> Bool {
        guard let firstToken = expr.firstToken(viewMode: .sourceAccurate) else { return false }
        return firstToken.leadingTrivia.contains { piece in
            switch piece {
            case .lineComment, .blockComment, .docLineComment, .docBlockComment:
                return true
            default:
                return false
            }
        }
    }

    /// Returns whether the given operator behaves as an assignment, to assign a right-hand-side to a
    /// left-hand-side in a `InfixOperatorExpr`.
    ///
    /// Assignment is defined as either being an assignment operator (i.e. `=`) or any operator that
    /// uses "assignment" precedence.
    func isAssigningOperator(_ operatorExpr: ExprSyntax) -> Bool {
        if operatorExpr.is(AssignmentExprSyntax.self) {
            return true
        }
        if let binOpExpr = operatorExpr.as(BinaryOperatorExprSyntax.self) {
            if let binOp = operatorTable.infixOperator(named: binOpExpr.operator.text),
                let precedenceGroup = binOp.precedenceGroup,
                precedenceGroup == "AssignmentPrecedence"
            {
                return true
            }
        }
        return false
    }

    /// Walks the expression and returns the leftmost subexpression if it is parenthesized (which
    /// might be the expression itself).
    ///
    /// - Parameter expr: The expression whose parenthesized leftmost subexpression should be
    ///   returned.
    /// - Returns: The parenthesized leftmost subexpression, or nil if the leftmost subexpression was
    ///   not parenthesized.
    func parenthesizedLeftmostExpr(of expr: ExprSyntax) -> TupleExprSyntax? {
        switch Syntax(expr).as(SyntaxEnum.self) {
        case .tupleExpr(let tupleExpr) where tupleExpr.elements.count == 1:
            return tupleExpr
        case .infixOperatorExpr(let infixOperatorExpr):
            return parenthesizedLeftmostExpr(of: infixOperatorExpr.leftOperand)
        case .ternaryExpr(let ternaryExpr):
            return parenthesizedLeftmostExpr(of: ternaryExpr.condition)
        default:
            return nil
        }
    }

    /// Walks the expression and returns the leftmost subexpression (which might be the expression
    /// itself) if the leftmost child is a node of the given type or if it is a unary operation
    /// applied to a node of the given type.
    ///
    /// - Parameter expr: The expression whose leftmost matching subexpression should be returned.
    /// - Returns: The leftmost subexpression, or nil if the leftmost subexpression was not the
    ///   desired type.
    func leftmostExpr(
        of expr: ExprSyntax,
        ifMatching predicate: (ExprSyntax) -> Bool
    ) -> ExprSyntax? {
        if predicate(expr) {
            return expr
        }
        switch Syntax(expr).as(SyntaxEnum.self) {
        case .infixOperatorExpr(let infixOperatorExpr):
            return leftmostExpr(of: infixOperatorExpr.leftOperand, ifMatching: predicate)
        case .asExpr(let asExpr):
            return leftmostExpr(of: asExpr.expression, ifMatching: predicate)
        case .isExpr(let isExpr):
            return leftmostExpr(of: isExpr.expression, ifMatching: predicate)
        case .forceUnwrapExpr(let forcedValueExpr):
            return leftmostExpr(of: forcedValueExpr.expression, ifMatching: predicate)
        case .optionalChainingExpr(let optionalChainingExpr):
            return leftmostExpr(of: optionalChainingExpr.expression, ifMatching: predicate)
        case .postfixOperatorExpr(let postfixUnaryExpr):
            return leftmostExpr(of: postfixUnaryExpr.expression, ifMatching: predicate)
        case .prefixOperatorExpr(let prefixOperatorExpr):
            return leftmostExpr(of: prefixOperatorExpr.expression, ifMatching: predicate)
        case .ternaryExpr(let ternaryExpr):
            return leftmostExpr(of: ternaryExpr.condition, ifMatching: predicate)
        case .functionCallExpr(let functionCallExpr):
            return leftmostExpr(of: functionCallExpr.calledExpression, ifMatching: predicate)
        case .subscriptCallExpr(let subscriptExpr):
            return leftmostExpr(of: subscriptExpr.calledExpression, ifMatching: predicate)
        case .memberAccessExpr(let memberAccessExpr):
            return memberAccessExpr.base.flatMap { leftmostExpr(of: $0, ifMatching: predicate) }
        case .postfixIfConfigExpr(let postfixIfConfigExpr):
            return postfixIfConfigExpr.base.flatMap { leftmostExpr(of: $0, ifMatching: predicate) }
        default:
            return nil
        }
    }

    /// Walks the expression and returns the leftmost multiline string literal (which might be the
    /// expression itself) if the leftmost child is a multiline string literal or if it is a unary
    /// operation applied to a multiline string literal.
    ///
    /// - Parameter expr: The expression whose leftmost multiline string literal should be returned.
    /// - Returns: The leftmost multiline string literal, or nil if the leftmost subexpression was
    ///   not a multiline string literal.
    func leftmostMultilineStringLiteral(of expr: ExprSyntax) -> StringLiteralExprSyntax? {
        return leftmostExpr(of: expr) {
            $0.as(StringLiteralExprSyntax.self)?.openingQuote.tokenKind == .multilineStringQuote
        }?.as(StringLiteralExprSyntax.self)
    }

    /// Returns the outermost node enclosing the given node whose closing delimiter(s) must be kept
    /// alongside the last token of the given node. Any tokens between `node.lastToken` and the
    /// returned node's `lastToken` are delimiter tokens that shouldn't be preceded by a break.
    func outermostEnclosingNode(from node: Syntax) -> Syntax? {
        guard let afterToken = node.lastToken(viewMode: .sourceAccurate)?.nextToken(viewMode: .all),
            closingDelimiterTokens.contains(afterToken)
        else {
            return nil
        }
        var parenthesizedExpr = afterToken.parent
        while let nextToken = parenthesizedExpr?.lastToken(viewMode: .sourceAccurate)?.nextToken(
            viewMode: .all
        ),
            closingDelimiterTokens.contains(nextToken),
            let nextExpr = nextToken.parent
        {
            parenthesizedExpr = nextExpr
        }
        return parenthesizedExpr
    }

    /// Determines if indentation should be stacked around a subexpression to the right of the given
    /// operator, and, if so, returns the node after which indentation stacking should be closed,
    /// whether or not the continuation state should be reset as well, and whether or not a group
    /// should be placed around the operator and the expression.
    ///
    /// Stacking is applied around parenthesized expressions, but also for low-precedence operators
    /// that frequently occur in long chains, such as logical AND (`&&`) and OR (`||`) in conditional
    /// statements. In this case, the extra level of indentation helps to improve readability with the
    /// operators inside those conditions even when parentheses are not used.
    func stackedIndentationBehavior(
        after operatorExpr: ExprSyntax? = nil,
        rhs: ExprSyntax
    ) -> (unindentingNode: Syntax, shouldReset: Bool, breakKind: OpenBreakKind, shouldGroup: Bool)?
    {
        // Check for logical operators first, and if it's that kind of operator, stack indentation
        // around the entire right-hand-side. We have to do this check before checking the RHS for
        // parentheses because if the user writes something like `... && (foo) > bar || ...`, we don't
        // want the indentation stacking that starts before the `&&` to stop after the closing
        // parenthesis in `(foo)`.
        //
        // We also want to reset after undoing the stacked indentation so that we have a visual
        // indication that the subexpression has ended.
        if let binOpExpr = operatorExpr?.as(BinaryOperatorExprSyntax.self) {
            if let binOp = operatorTable.infixOperator(named: binOpExpr.operator.text),
                let precedenceGroup = binOp.precedenceGroup,
                precedenceGroup == "LogicalConjunctionPrecedence"
                    || precedenceGroup == "LogicalDisjunctionPrecedence"
            {
                // When `rhs` side is the last sequence in an enclosing parenthesized expression, absorb the
                // paren into the right hand side by unindenting after the final closing paren. This glues
                // the paren to the last token of `rhs`.
                if let unindentingParenExpr = outermostEnclosingNode(from: Syntax(rhs)) {
                    return (
                        unindentingNode: unindentingParenExpr,
                        shouldReset: true,
                        breakKind: .continuation,
                        shouldGroup: true
                    )
                }
                return (
                    unindentingNode: Syntax(rhs),
                    shouldReset: true,
                    breakKind: .continuation,
                    shouldGroup: true
                )
            }
        }

        // If the right-hand-side is a ternary expression, stack indentation around the condition so
        // that it is indented relative to the `?` and `:` tokens.
        if let ternaryExpr = rhs.as(TernaryExprSyntax.self) {
            // We don't try to absorb any parens in this case, because the condition of a ternary cannot
            // be grouped with any exprs outside of the condition.
            return (
                unindentingNode: Syntax(ternaryExpr.condition),
                shouldReset: false,
                breakKind: .continuation,
                shouldGroup: true
            )
        }

        // If the right-hand-side of the operator is or starts with a parenthesized expression, stack
        // indentation around the operator and those parentheses. We don't need to reset here because
        // the parentheses are sufficient to provide a visual indication of the nesting relationship.
        if let parenthesizedExpr = parenthesizedLeftmostExpr(of: rhs) {
            // When `rhs` side is the last sequence in an enclosing parenthesized expression, absorb the
            // paren into the right hand side by unindenting after the final closing paren. This glues the
            // paren to the last token of `rhs`.
            if let unindentingParenExpr = outermostEnclosingNode(from: Syntax(rhs)) {
                return (
                    unindentingNode: unindentingParenExpr,
                    shouldReset: true,
                    breakKind: .continuation,
                    shouldGroup: false
                )
            }

            if let innerExpr = parenthesizedExpr.elements.first?.expression,
                let stringLiteralExpr = innerExpr.as(StringLiteralExprSyntax.self),
                stringLiteralExpr.openingQuote.tokenKind == .multilineStringQuote
            {
                pendingMultilineStringBreakKinds[stringLiteralExpr] = .continue
                return nil
            }

            return (
                unindentingNode: Syntax(parenthesizedExpr),
                shouldReset: false,
                breakKind: .continuation,
                shouldGroup: false
            )
        }

        // If the expression is a multiline string that is unparenthesized, create a block-based
        // indentation scope and have the segments aligned inside it.
        if let stringLiteralExpr = leftmostMultilineStringLiteral(of: rhs) {
            pendingMultilineStringBreakKinds[stringLiteralExpr] = .same
            return (
                unindentingNode: Syntax(stringLiteralExpr),
                shouldReset: false,
                breakKind: .block,
                shouldGroup: false
            )
        }

        if let leftmostExpr = leftmostExpr(
            of: rhs,
            ifMatching: {
                $0.is(IfExprSyntax.self) || $0.is(SwitchExprSyntax.self)
            }
        ) {
            return (
                unindentingNode: Syntax(leftmostExpr),
                shouldReset: false,
                breakKind: .block,
                shouldGroup: true
            )
        }

        // Otherwise, don't stack--use regular continuation breaks instead.
        return nil
    }

}
