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
import SwiftOperators

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

        // If we're at the end of the file, determine at which index to stop checking trivia pieces
        // to prevent trailing newlines.
        var cutoffIndex: Int?

        if token.tokenKind == TokenKind.endOfFile {
            cutoffIndex = 0

            for (index, piece) in trivia.enumerated() {
                switch piece {
                    case .newlines, .carriageReturns, .carriageReturnLineFeeds: continue
                    default: cutoffIndex = index + 1
                }
            }
        }

        // Updated throughout the loop to indicate whether the next newline *must* be honored (for
        // example, even if discretionary newlines are discarded). This is the case when the
        // preceding trivia was a line comment or garbage text.
        var requiresNextNewline = false

        // Tracking whether or not the last piece was leading indentation. A newline is considered a
        // 0-space indentation; used for nesting/un-nesting block comments during formatting.
        var leadingIndent: Indent?

        for (index, piece) in trivia.enumerated() {
            if let cutoff = cutoffIndex, index == cutoff { break }

            switch piece {
                case let .lineComment(text):
                    if index > 0 || isStartOfFile {
                        generateEnableFormattingIfNecessary(
                            position..<position + piece.sourceLength)
                        appendToken(
                            .comment(
                                Comment(kind: .line, leadingIndent: leadingIndent, text: text),
                                wasEndOfLine: false
                            ))
                        generateDisableFormattingIfNecessary(position + piece.sourceLength)
                        appendNewlines(.soft)
                        isStartOfFile = false
                    }
                    requiresNextNewline = true
                    leadingIndent = nil

                case let .blockComment(text):
                    if index > 0 || isStartOfFile {
                        let isStandaloneLeadingComment = leadingIndent != nil || isStartOfFile
                        generateEnableFormattingIfNecessary(
                            position..<position + piece.sourceLength)
                        appendToken(
                            .comment(
                                Comment(kind: .block, leadingIndent: leadingIndent, text: text),
                                wasEndOfLine: false
                            ))
                        generateDisableFormattingIfNecessary(position + piece.sourceLength)
                        // There is always a break after the comment to allow a discretionary
                        // newline after it.
                        var breakSize = 0

                        if index + 1 < trivia.endIndex {
                            let nextPiece = trivia[index + 1]
                            // The original number of spaces is intentionally discarded, but 1 space
                            // is allowed in case the comment is followed by another token instead
                            // of a newline.
                            if case .spaces = nextPiece { breakSize = 1 }
                        }
                        appendToken(.break(.same, size: breakSize))
                        isStartOfFile = false
                        requiresNextNewline = isStandaloneLeadingComment
                    } else {
                        requiresNextNewline = false
                    }
                    leadingIndent = nil

                case let .docLineComment(text):
                    generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                    appendToken(
                        .comment(
                            Comment(kind: .docLine, leadingIndent: leadingIndent, text: text),
                            wasEndOfLine: false
                        ))
                    generateDisableFormattingIfNecessary(position + piece.sourceLength)
                    appendNewlines(.soft)
                    isStartOfFile = false
                    requiresNextNewline = true
                    leadingIndent = nil

                case let .docBlockComment(text):
                    generateEnableFormattingIfNecessary(position..<position + piece.sourceLength)
                    appendToken(
                        .comment(
                            Comment(kind: .docBlock, leadingIndent: leadingIndent, text: text),
                            wasEndOfLine: false
                        ))
                    generateDisableFormattingIfNecessary(position + piece.sourceLength)
                    appendNewlines(.soft)
                    isStartOfFile = false
                    requiresNextNewline = false
                    leadingIndent = nil

                case let .newlines(count),
                     let .carriageReturns(count),
                     let .carriageReturnLineFeeds(count):
                    if config[IndentBlankLines.self],
                       let leadingIndent,
                       leadingIndent.count > 0
                    {
                        requiresNextNewline = true
                    }

                    leadingIndent = .spaces(0)
                    guard !isStartOfFile else { break }

                    if requiresNextNewline
                        || (config[RespectExistingLineBreaks.self]
                            && isDiscretionaryNewlineAllowed(before: token))
                    {
                        appendNewlines(.soft(count: count, discretionary: true))
                    } else {
                        // Even if discretionary line breaks are not being respected, we still respect multiple
                        // line breaks in order to keep blank separator lines that the user might want.
                        // TODO: It would be nice to restrict this to only allow multiple lines between statements
                        // and declarations; as currently implemented, multiple newlines will locally ignore the
                        // configuration setting.
                        if count > 1 { appendNewlines(.soft(count: count, discretionary: true)) }
                    }

                case let .unexpectedText(text):
                    // Garbage text in leading trivia might be something meaningful that would be
                    // disruptive to throw away when formatting the file, like a hashbang line or
                    // Unicode byte-order marker at the beginning of a file, or source control
                    // conflict markers. Keep it as verbatim text so that it is printed exactly as
                    // we got it.
                    appendToken(.verbatim(Verbatim(text: text, indentingBehavior: .none)))

                    // Unicode byte-order markers shouldn't allow leading newlines to otherwise
                    // appear in the file, nor should they modify our detection of the beginning of
                    // the file.
                    let isBOM = text == "\u{feff}"
                    requiresNextNewline = !isBOM
                    isStartOfFile = isStartOfFile && isBOM
                    leadingIndent = nil

                case .backslashes, .formfeeds, .pounds, .verticalTabs: leadingIndent = nil

                case let .spaces(n):
                    guard leadingIndent == .spaces(0) else { break }
                    leadingIndent = .spaces(n)

                case let .tabs(n):
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
        guard let lastBreakIndex else {
            // When there haven't been any breaks yet, there can't be any indentation to maintain so
            // a same break is safe here.
            appendToken(.break(.same, size: 0, newlines: newlines))
            return
        }

        let lastBreak = tokens[lastBreakIndex]
        // `lastBreakIndex` is internal bookkeeping maintained by `appendToken` ; reaching this
        // branch with a non-break token means the bookkeeping is broken (programmer error), not
        // malformed input. Skip silently in release.
        guard case let .break(kind, size, existingNewlines) = lastBreak else {
            assertionFailure("Found non-break token at lastBreakIndex. TokenStream is invalid.")
            return
        }

        guard !canMergeNewlinesIntoLastBreak else {
            tokens[lastBreakIndex] = .break(kind, size: size, newlines: existingNewlines + newlines)
            return
        }

        // Otherwise, create and insert a new break whose `kind` is compatible with last break.
        let compatibleKind: BreakKind

        switch kind {
            case .open, .close, .reset, .same: compatibleKind = .same
            case .continue, .contextual: compatibleKind = kind
        }
        appendToken(.break(compatibleKind, size: 0, newlines: newlines))
    }

    /// Appends a formatting token to the token stream.
    ///
    /// This function also handles collapsing neighboring tokens in situations where that is
    /// desired, like merging adjacent comments and newlines.
    func appendToken(_ token: Token) {
        func breakAllowsCommentMerge(_ breakKind: BreakKind) -> Bool {
            breakKind == .same || breakKind == .continue || breakKind == .contextual
        }

        if let last = tokens.last {
            switch (last, token) {
                case (.break(_, _, .escaped), _), (_, .break(_, _, .escaped)):
                    lastBreakIndex = tokens.endIndex
                    // Don't allow merging for .escaped breaks
                    canMergeNewlinesIntoLastBreak = false
                    tokens.append(token)
                    return
                case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
                    where breakAllowsCommentMerge(breakKind)
                    && (c2.kind == .docLine || c2.kind == .line):
                    // we are search for the pattern of [line comment] - [soft break 1] - [line
                    // comment] where the comment type is the same; these can be merged into a
                    // single comment
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
                                case .break: true
                                default: false
                            }
                        })
                        canMergeNewlinesIntoLastBreak = false

                        return
                    }

                // If we see a pair of spaces where one or both are flexible, combine them into a
                // new token with the maximum of their counts.
                case (.space(let first, let firstFlexible), .space(let second, let secondFlexible))
                    where firstFlexible || secondFlexible:
                    tokens[tokens.count - 1] = .space(size: max(first, second), flexible: true)
                    return

                default: break
            }
        }

        switch token {
            case .break:
                lastBreakIndex = tokens.endIndex
                canMergeNewlinesIntoLastBreak = true
            case .open,
                 .printerControl,
                 .contextualBreakingStart,
                 .enableFormatting,
                 .disableFormatting:
                break
            default: canMergeNewlinesIntoLastBreak = false
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

    /// Returns true if open/close breaks should be inserted around the entire function call
    /// argument list.
    func shouldGroupAroundArgumentList(_ arguments: LabeledExprListSyntax) -> Bool {
        let argumentCount = arguments.count

        // If there are no arguments, there's no reason to break.
        if argumentCount == 0 { return false }

        // If there is more than one argument, we must open/close break around the whole list.
        return argumentCount > 1 ? true : !isCompactSingleFunctionCallArgument(arguments)
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
        guard let parent = expr.parent,
              parent.is(MemberAccessExprSyntax.self) || parent.is(PostfixIfConfigExprSyntax.self)
        else { return false }

        let argumentList = expr[keyPath: argumentListPath]

        // When there's a single compact argument, there is no extra indentation for the argument
        // and the argument's own internal reset break will reset indentation.
        return !isCompactSingleFunctionCallArgument(argumentList)
    }

    /// Returns true if the argument list can be compacted, even if it spans multiple lines (where
    /// compact means that it can start immediately after the open parenthesis).
    ///
    /// This is true for any argument list that contains a single argument (labeled or unlabeled)
    /// that is an array, dictionary, or closure literal.
    func isCompactSingleFunctionCallArgument(_ argumentList: LabeledExprListSyntax) -> Bool {
        guard argumentList.count == 1 else { return false }

        let expression = argumentList.first!.expression
        return expression.is(ArrayExprSyntax.self) || expression.is(DictionaryExprSyntax.self)
            || expression.is(ClosureExprSyntax.self)
            || expression.is(FunctionCallExprSyntax.self)
    }

    /// Adds a grouping around certain subexpressions during `InfixOperatorExpr` visitation.
    ///
    /// Adding groups around these expressions allows them to prefer breaking onto a newline before
    /// the expression, keeping the entire expression together when possible, before breaking inside
    /// the expression. This is a hand-crafted list of expressions that generally look better when
    /// the break(s) before the expression fire before breaks inside of the expression.
    func maybeGroupAroundSubexpression(
        _ expr: ExprSyntax,
        combiningOperator operatorExpr: ExprSyntax? = nil
    ) {
        // For assignments, omit the surrounding group on member-access / subscript / function-call
        // RHS so the `=` break's chunk is bounded by the chain's first inner break. With the group
        // present, the `=` break sees the entire RHS as one chunk and fires prematurely instead of
        // letting the chain absorb the wrap (precedence: inner `.` > `=` ).
        let isAssignment = operatorExpr.map(isAssigningOperator) ?? false

        switch Syntax(expr).kind {
            case .memberAccessExpr, .subscriptCallExpr:
                if !isAssignment {
                    before(expr.firstToken(viewMode: .sourceAccurate), tokens: .open)
                    after(expr.lastToken(viewMode: .sourceAccurate), tokens: .close)
                }
            default: break
        }

        // When a function call expression is assigned to an lvalue, we omit the group around the
        // function call so that the callee and open parenthesis can remain on the same line, if
        // they fit. This is a frequent enough case that the outcome looks better with the exception
        // in place.
        if expr.is(FunctionCallExprSyntax.self), !isAssignment {
            before(expr.firstToken(viewMode: .sourceAccurate), tokens: .open)
            after(expr.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }
    }

    /// Returns whether the given expression consists of multiple subexpressions. Certain
    /// expressions that are known to wrap an expression, e.g. try expressions, are handled by
    /// checking the expression that they contain.
    func isCompoundExpression(_ expr: ExprSyntax) -> Bool {
        if let modifiedExpr = expr.asProtocol(KeywordModifiedExprSyntax.self) {
            return isCompoundExpression(modifiedExpr.expression)
        }
        switch Syntax(expr).as(SyntaxEnum.self) {
            case .infixOperatorExpr, .ternaryExpr, .isExpr, .asExpr: return true
            case let .tupleExpr(tupleExpr) where tupleExpr.elements.count == 1:
                return isCompoundExpression(tupleExpr.elements.first!.expression)
            default: return false
        }
    }

    /// Returns whether the given expression is or begins with a member access chain (e.g.
    /// `foo.bar(...)` , `foo.bar(...).baz(...)` ). Used to detect method-chaining RHS expressions
    /// in assignments so the formatter prefers breaking at dots rather than after `=` .
    func isMemberAccessChain(_ expr: ExprSyntax) -> Bool {
        if let callingExpr = expr.asProtocol(CallingExprSyntax.self) {
            return callingExpr.calledExpression.is(MemberAccessExprSyntax.self)
                || isMemberAccessChain(callingExpr.calledExpression)
        }
        return expr.is(MemberAccessExprSyntax.self)
    }

    /// Returns whether the given function call expression participates in an outer member-access
    /// chain — that is, walking up through transparent postfix wrappers ( `?` , `!` ), the eventual
    /// parent is a `MemberAccessExpr` that uses this call as its base. In that case, the call's
    /// `.calledExpression` (e.g. `base.method` ) should NOT be wrapped in a small open/close group,
    /// because doing so bounds the chunk of the contextual break before `.method` and prevents the
    /// outer chain break from firing per documented break precedence.
    func isPartOfOuterMemberAccessChain(_ call: FunctionCallExprSyntax) -> Bool {
        var current = Syntax(call)

        while let parent = current.parent {
            switch parent.kind {
                case .optionalChainingExpr,
                     .forceUnwrapExpr,
                     .postfixOperatorExpr,
                     .postfixIfConfigExpr:
                    current = parent
                case .memberAccessExpr:
                    if let memberAccess = parent.as(MemberAccessExprSyntax.self),
                       let base = memberAccess.base,
                       base.id == current.id
                    {
                        return true
                    }
                    return false
                default: return false
            }
        }
        return false
    }

    /// Whether an expression should use break precedence — `ignoresDiscretionary` + open/close
    /// grouping — so the formatter prefers inner operator breaks over the enclosing break position.
    /// Used for both assignment ( `=` ) and keyword ( `guard` ) breaks.
    func shouldApplyBreakPrecedence(_ expr: ExprSyntax) -> Bool {
        isCompoundExpression(expr)
            && leftmostMultilineStringLiteral(of: expr) == nil
            && !hasLeadingLineComments(expr)
    }

    /// Places break tokens after an assignment-style operator and matching close tokens around the
    /// RHS. Shared by `InfixOperatorExpr` (assigning operators) and `PatternBinding` (
    /// `let/var = …` ).
    ///
    /// Strategies, in priority order:
    /// - Ternary RHS: skips stacked indent so the engine prefers `?` / `:` breaks over `=` .
    /// - Stacked indent (parens, `&&` / `||` ): wraps the RHS scope with stacked continuation
    ///   indent.
    /// - Group-before-break (chains, binary operators): places `.open` before the break so inner
    ///   operator breaks get priority over the `=` break.
    /// - Otherwise: a simple continuation break.
    func arrangeAssignmentBreaks(
        afterEqualToken equal: TokenSyntax,
        rhs: ExprSyntax,
        operatorExpr: ExprSyntax? = nil
    ) {
        let isCompound = isCompoundExpression(rhs) && leftmostMultilineStringLiteral(of: rhs) == nil
        let hasMemberChain = isMemberAccessChain(rhs)
        let canGroupBeforeBreak = (isCompound || hasMemberChain) && !hasLeadingLineComments(rhs)
        let isTernaryRhs = rhs.is(TernaryExprSyntax.self)

        if isTernaryRhs {
            // Ternary RHS: bound the `=` break's chunk to the next inner break (the ternary `?` )
            // by NOT wrapping the RHS in an `.open` / `.close` group. That keeps the chunk small
            // enough that `=` only fires when the prefix `... = <condition>` itself overflows;
            // otherwise the inner `?` / `:` breaks fire and `=` stays glued.
            after(equal, tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true)))
        } else if let (unindentingNode, _, breakKind, shouldGroup) =
            stackedIndentationBehavior(after: operatorExpr, rhs: rhs)
        {
            var openTokens: [Token] = [
                .break(
                    .open(kind: breakKind),
                    newlines: .elective(ignoresDiscretionary: true)
                )
            ]
            if shouldGroup { openTokens.append(.open) }
            after(equal, tokens: openTokens)

            var closeTokens: [Token] = [.break(.close(mustBreak: false), size: 0)]
            if shouldGroup { closeTokens.append(.close) }
            after(unindentingNode.lastToken(viewMode: .sourceAccurate), tokens: closeTokens)

            if isCompound {
                before(rhs.firstToken(viewMode: .sourceAccurate), tokens: .open)
                after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        } else if canGroupBeforeBreak {
            after(
                equal,
                tokens: .open,
                .break(.continue, newlines: .elective(ignoresDiscretionary: true))
            )
            after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
        } else {
            after(equal, tokens: .break(.continue, newlines: .elective(ignoresDiscretionary: true)))

            if isCompound {
                before(rhs.firstToken(viewMode: .sourceAccurate), tokens: .open)
                after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
            }
        }
    }

    /// Returns whether the given expression has line or block comments in the leading trivia of its
    /// first token. When comments are present between `=` and the RHS expression, grouping the open
    /// before the break disrupts comment indentation.
    func hasLeadingLineComments(_ expr: ExprSyntax) -> Bool {
        guard let firstToken = expr.firstToken(viewMode: .sourceAccurate) else { return false }
        return firstToken.leadingTrivia.contains { piece in
            switch piece {
                case .lineComment, .blockComment, .docLineComment, .docBlockComment: true
                default: false
            }
        }
    }

    /// Returns whether the given operator behaves as an assignment, to assign a right-hand-side to
    /// a left-hand-side in a `InfixOperatorExpr` .
    ///
    /// Assignment is defined as either being an assignment operator (i.e. `=` ) or any operator
    /// that uses "assignment" precedence. Returns whether the given expression is the left-hand
    /// side of an assignment operator ( `=` , `+=` , `-=` , etc.). Used to suppress
    /// contextual-break insertion in LHS chains so a short member access target like
    /// `obj.member = …` is not split across multiple lines.
    func isAssignmentLHS(_ expr: ExprSyntax) -> Bool {
        guard let parent = expr.parent?.as(InfixOperatorExprSyntax.self),
              parent.leftOperand.id == expr.id else { return false }
        return isAssigningOperator(parent.operator)
    }

    func isAssigningOperator(_ operatorExpr: ExprSyntax) -> Bool {
        if operatorExpr.is(AssignmentExprSyntax.self) { return true }

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

    /// Returns whether the given operator uses `ComparisonPrecedence` ( `==` , `!=` , `<` , `>` ,
    /// `<=` , `>=` , `===` , `!==` , `~=` , and any user-defined operator opting into the same
    /// precedence group). Comparison operators get last-resort break precedence: their break chunk
    /// is bounded around the RHS so inner breaks (e.g. function-call argument lists) fire first.
    func isComparisonOperator(_ operatorExpr: ExprSyntax) -> Bool {
        guard let binOpExpr = operatorExpr.as(BinaryOperatorExprSyntax.self),
              let binOp = operatorTable.infixOperator(named: binOpExpr.operator.text),
              let precedenceGroup = binOp.precedenceGroup else { return false }
        return precedenceGroup == "ComparisonPrecedence"
    }

    /// Returns whether the expression syntactically contains a function-call or subscript with at
    /// least one argument — i.e. a place the formatter could wrap by breaking the argument list.
    /// Used to gate the comparison-operator break-precedence treatment so it only fires when there
    /// is actually an inner argument-list break to prefer over the comparison break.
    func containsCallOrSubscriptArgList(_ expr: ExprSyntax) -> Bool {
        var found = false

        for node in expr.children(viewMode: .sourceAccurate) {
            if found { break }

            if let call = node.as(FunctionCallExprSyntax.self), !call.arguments.isEmpty {
                found = true
                break
            }
            if let sub = node.as(SubscriptCallExprSyntax.self), !sub.arguments.isEmpty {
                found = true
                break
            }
            if let childExpr = node.as(ExprSyntax.self),
               containsCallOrSubscriptArgList(childExpr)
            {
                found = true
            }
        }
        if let call = expr.as(FunctionCallExprSyntax.self), !call.arguments.isEmpty { return true }
        if let sub = expr.as(SubscriptCallExprSyntax.self), !sub.arguments.isEmpty { return true }
        return found
    }

    /// Returns whether the given infix-operator expression appears (transitively) inside an `if` /
    /// `guard` / `while` condition list.
    func isInConditionList(_ node: InfixOperatorExprSyntax) -> Bool {
        var current: Syntax? = node.parent

        while let parent = current {
            if parent.is(ConditionElementSyntax.self) { return true }
            if parent.asProtocol(SyntaxProtocol.self) is StmtSyntaxProtocol { return false }
            if parent.asProtocol(SyntaxProtocol.self) is DeclSyntaxProtocol { return false }
            if parent.is(CodeBlockSyntax.self) { return false }
            if parent.is(CodeBlockItemSyntax.self) { return false }
            current = parent.parent
        }
        return false
    }

    /// Returns the `GroupBreakStyle` to use for the given function-call argument list. Forces
    /// `.consistent` when the surrounding context is a comparison-operator expression inside an
    /// `if` / `guard` / `while` condition: the comparison break's chunk is bounded by the RHS so it
    /// would otherwise win precedence over the call's myopic inconsistent inter-arg breaks and
    /// dangle the operator on its own line. With consistent grouping, once any arg breaks (the
    /// open-paren break must fire when the line doesn't fit), every arg breaks, keeping the
    /// operator glued to the closing `)` .
    func effectiveArgListConsistency(for arguments: LabeledExprListSyntax) -> GroupBreakStyle {
        let defaultConsistency = argumentListConsistency()
        guard defaultConsistency == .inconsistent else { return defaultConsistency }
        guard let call = arguments.parent?.as(FunctionCallExprSyntax.self) else {
            return defaultConsistency
        }
        guard let infix = call.parent?.as(InfixOperatorExprSyntax.self) else {
            return defaultConsistency
        }
        guard isComparisonOperator(infix.operator) else { return defaultConsistency }
        return isInConditionList(infix) ? .consistent : defaultConsistency
    }

    /// Walks the expression and returns the leftmost subexpression if it is parenthesized (which
    /// might be the expression itself).
    ///
    /// - Parameter expr: The expression whose parenthesized leftmost subexpression should be
    ///   returned.
    /// - Returns: The parenthesized leftmost subexpression, or nil if the leftmost subexpression
    ///   was not parenthesized.
    func parenthesizedLeftmostExpr(of expr: ExprSyntax) -> TupleExprSyntax? {
        switch Syntax(expr).as(SyntaxEnum.self) {
            case let .tupleExpr(tupleExpr) where tupleExpr.elements.count == 1: tupleExpr
            case let .infixOperatorExpr(infixOperatorExpr):
                parenthesizedLeftmostExpr(of: infixOperatorExpr.leftOperand)
            case let .ternaryExpr(ternaryExpr): parenthesizedLeftmostExpr(of: ternaryExpr.condition)
            default: nil
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
        if predicate(expr) { return expr }

        switch Syntax(expr).as(SyntaxEnum.self) {
            case let .infixOperatorExpr(infixOperatorExpr):
                return leftmostExpr(of: infixOperatorExpr.leftOperand, ifMatching: predicate)
            case let .asExpr(asExpr):
                return leftmostExpr(of: asExpr.expression, ifMatching: predicate)
            case let .isExpr(isExpr):
                return leftmostExpr(of: isExpr.expression, ifMatching: predicate)
            case let .forceUnwrapExpr(forcedValueExpr):
                return leftmostExpr(of: forcedValueExpr.expression, ifMatching: predicate)
            case let .optionalChainingExpr(optionalChainingExpr):
                return leftmostExpr(of: optionalChainingExpr.expression, ifMatching: predicate)
            case let .postfixOperatorExpr(postfixUnaryExpr):
                return leftmostExpr(of: postfixUnaryExpr.expression, ifMatching: predicate)
            case let .prefixOperatorExpr(prefixOperatorExpr):
                return leftmostExpr(of: prefixOperatorExpr.expression, ifMatching: predicate)
            case let .ternaryExpr(ternaryExpr):
                return leftmostExpr(of: ternaryExpr.condition, ifMatching: predicate)
            case let .functionCallExpr(functionCallExpr):
                return leftmostExpr(of: functionCallExpr.calledExpression, ifMatching: predicate)
            case let .subscriptCallExpr(subscriptExpr):
                return leftmostExpr(of: subscriptExpr.calledExpression, ifMatching: predicate)
            case let .memberAccessExpr(memberAccessExpr):
                return memberAccessExpr.base.flatMap { leftmostExpr(of: $0, ifMatching: predicate) }
            case let .postfixIfConfigExpr(postfixIfConfigExpr):
                return postfixIfConfigExpr.base.flatMap {
                    leftmostExpr(of: $0, ifMatching: predicate)
                }
            default: return nil
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
        leftmostExpr(of: expr) {
            $0.as(StringLiteralExprSyntax.self)?.openingQuote.tokenKind == .multilineStringQuote
        }?.as(StringLiteralExprSyntax.self)
    }

    /// Returns the outermost node enclosing the given node whose closing delimiter(s) must be kept
    /// alongside the last token of the given node. Any tokens between `node.lastToken` and the
    /// returned node's `lastToken` are delimiter tokens that shouldn't be preceded by a break.
    func outermostEnclosingNode(from node: Syntax) -> Syntax? {
        guard let afterToken = node.lastToken(viewMode: .sourceAccurate)?.nextToken(viewMode: .all),
              closingDelimiterTokens.contains(afterToken) else { return nil }
        var parenthesizedExpr = afterToken.parent
        while let nextToken = parenthesizedExpr?.lastToken(viewMode: .sourceAccurate)?.nextToken(
            viewMode: .all
        ),
              closingDelimiterTokens.contains(nextToken),
              let nextExpr = nextToken.parent
        { parenthesizedExpr = nextExpr }
        return parenthesizedExpr
    }

    /// Determines if indentation should be stacked around a subexpression to the right of the given
    /// operator, and, if so, returns the node after which indentation stacking should be closed,
    /// whether or not the continuation state should be reset as well, and whether or not a group
    /// should be placed around the operator and the expression.
    ///
    /// Stacking is applied around parenthesized expressions, but also for low-precedence operators
    /// that frequently occur in long chains, such as logical AND ( `&&` ) and OR ( `||` ) in
    /// conditional statements. In this case, the extra level of indentation helps to improve
    /// readability with the operators inside those conditions even when parentheses are not used.
    func stackedIndentationBehavior(
        after operatorExpr: ExprSyntax? = nil,
        rhs: ExprSyntax
    ) -> (unindentingNode: Syntax, shouldReset: Bool, breakKind: OpenBreakKind, shouldGroup: Bool)?
    {
        // Check for logical operators first, and if it's that kind of operator, stack indentation
        // around the entire right-hand-side. We have to do this check before checking the RHS for
        // parentheses because if the user writes something like `... && (foo) > bar || ...` , we
        // don't want the indentation stacking that starts before the `&&` to stop after the closing
        // parenthesis in `(foo)` .
        //
        // We also want to reset after undoing the stacked indentation so that we have a visual
        // indication that the subexpression has ended.
        if let binOpExpr = operatorExpr?.as(BinaryOperatorExprSyntax.self) {
            if let binOp = operatorTable.infixOperator(named: binOpExpr.operator.text),
               let precedenceGroup = binOp.precedenceGroup,
               precedenceGroup == "LogicalConjunctionPrecedence"
                   || precedenceGroup == "LogicalDisjunctionPrecedence"
            {
                // When `rhs` side is the last sequence in an enclosing parenthesized expression,
                // absorb the paren into the right hand side by unindenting after the final closing
                // paren. This glues the paren to the last token of `rhs` .
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
            // We don't try to absorb any parens in this case, because the condition of a ternary
            // cannot be grouped with any exprs outside of the condition.
            return (
                unindentingNode: Syntax(ternaryExpr.condition),
                shouldReset: false,
                breakKind: .continuation,
                shouldGroup: true
            )
        }

        // If the right-hand-side of the operator is or starts with a parenthesized expression,
        // stack indentation around the operator and those parentheses. We don't need to reset here
        // because the parentheses are sufficient to provide a visual indication of the nesting
        // relationship.
        if let parenthesizedExpr = parenthesizedLeftmostExpr(of: rhs) {
            // When `rhs` side is the last sequence in an enclosing parenthesized expression, absorb
            // the paren into the right hand side by unindenting after the final closing paren. This
            // glues the paren to the last token of `rhs` .
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
