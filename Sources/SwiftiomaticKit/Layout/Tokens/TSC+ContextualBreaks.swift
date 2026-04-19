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

extension TokenStreamCreator {
    /// Returns a value indicating whether whitespace should be required around the given operator,
    /// for the given configuration.
    ///
    /// If spaces are not required (for example, range operators), then the formatter will also forbid
    /// breaks around the operator. This is to prevent situations where a break could occur before an
    /// unspaced operator (e.g., turning `0...10` into `0<newline>...10`), which would be a breaking
    /// change because it would treat it as a prefix operator `...10` instead of an infix operator.
    func shouldRequireWhitespace(around operatorExpr: ExprSyntax) -> Bool {
        // Note that we look at the operator itself to make this determination, not the token kind.
        // The token kind (spaced or unspaced operator) represents how the *user* wrote it, and we want
        // to ignore that and apply our own rules.
        if let binaryOperator = operatorExpr.as(BinaryOperatorExprSyntax.self) {
            let token = binaryOperator.operator
            if !config[SpacesAroundRangeFormationOperators.self],
                let binOp = operatorTable.infixOperator(named: token.text),
                let precedenceGroup = binOp.precedenceGroup,
                precedenceGroup == "RangeFormationPrecedence"
            {
                // We want to omit whitespace around range formation operators if possible. We can't do this
                // if the token is either preceded by a postfix operator, followed by a prefix operator, or
                // followed by a dot (for example, in an implicit member reference)---removing the spaces in
                // those situations would cause the parser to greedily treat the combined sequence of
                // operator characters as a single operator.
                if case .postfixOperator? = token.previousToken(viewMode: .all)?.tokenKind {
                    return true
                }

                switch token.nextToken(viewMode: .all)?.tokenKind {
                case .prefixOperator?, .period?: return true
                default: return false
                }
            }
        }

        // For all other operators, we want to require whitespace on each side. That's always safe, so
        // we don't need to be concerned about neighboring operator tokens. For example, we don't need
        // to be concerned about the user writing "4+-5" when they meant "4 + -5", because Swift would
        // always parse the former as "4 +- 5".
        return true
    }

    /// Appends the given node to the token stream without applying any formatting or printing tokens.
    ///
    /// - Parameter node: A node that is ignored by the formatter.
    func appendFormatterIgnored(node: Syntax) {
        // The first line of text in the `verbatim` token is printed with correct indentation, based on
        // the previous tokens. The leading trivia of the first token needs to be excluded from the
        // `verbatim` token in order for the first token to be printed with correct indentation. All
        // following lines in the ignored node are printed as-is with no changes to indentation.
        var nodeText = node.description
        if let firstToken = node.firstToken(viewMode: .sourceAccurate) {
            extractLeadingTrivia(firstToken)
            let leadingTriviaText = firstToken.leadingTrivia.reduce(into: "") { $1.write(to: &$0) }
            nodeText = String(nodeText.dropFirst(leadingTriviaText.count))
        }

        // The leading trivia of the next token, after the ignored node, may contain content that
        // belongs with the ignored node. The trivia extraction that is performed for `lastToken` later
        // excludes that content so it needs to be extracted and added to the token stream here.
        if let next = node.lastToken(viewMode: .sourceAccurate)?.nextToken(viewMode: .all),
            let trivia = next.leadingTrivia.first
        {
            switch trivia {
            case .lineComment, .blockComment:
                trivia.write(to: &nodeText)
                break
            default:
                // All other kinds of trivia are inserted into the token stream by `extractLeadingTrivia`
                // when the relevant token is visited.
                break
            }
        }

        appendToken(.verbatim(Verbatim(text: nodeText, indentingBehavior: .firstLine)))

        // Add this break so that trivia parsing will allow discretionary newlines after the node.
        appendToken(.break(.same, size: 0))
    }

    /// Cleans up state related to inserting contextual breaks throughout expressions during
    /// `visitPost` for an expression that is the root of an expression tree.
    func clearContextualBreakState<T: ExprSyntaxProtocol>(_ expr: T) {
        let exprID = expr.id
        if rootExprs.remove(exprID) != nil {
            preVisitedExprs.removeAll()
        }
    }

    /// Visits the given expression node and all of the nested expression nodes, inserting tokens
    /// necessary for contextual breaking throughout the expression. Records the nodes that were
    /// visited so that they can be skipped later.
    func preVisitInsertingContextualBreaks<T: ExprSyntaxProtocol & Equatable>(_ expr: T) {
        let exprID = expr.id
        if !preVisitedExprs.contains(exprID) {
            rootExprs.insert(exprID)
            insertContextualBreaks(ExprSyntax(expr), isTopLevel: true)
        }
    }

    /// Recursively visits nested expressions from the given expression inserting contextual breaking
    /// tokens. When visiting an expression node, `preVisitInsertingContextualBreaks(_:)` should be
    /// called instead of this helper.
    @discardableResult
    func insertContextualBreaks(
        _ expr: ExprSyntax,
        isTopLevel: Bool
    ) -> (hasCompoundExpression: Bool, hasMemberAccess: Bool) {
        preVisitedExprs.insert(expr.id)
        if let memberAccessExpr = expr.as(MemberAccessExprSyntax.self) {
            // When the member access is part of a calling expression, the break before the dot is
            // inserted when visiting the parent node instead so that the break is inserted before any
            // scoping tokens (e.g. `contextualBreakingStart`, `open`).
            if memberAccessExpr.base != nil
                && expr.parent?.isProtocol(CallingExprSyntax.self) != true
            {
                before(memberAccessExpr.period, tokens: .break(.contextual, size: 0))
            }
            var hasCompoundExpression = false
            if let base = memberAccessExpr.base {
                (hasCompoundExpression, _) = insertContextualBreaks(base, isTopLevel: false)
            }
            if isTopLevel {
                before(expr.firstToken(viewMode: .sourceAccurate), tokens: .contextualBreakingStart)
                after(expr.lastToken(viewMode: .sourceAccurate), tokens: .contextualBreakingEnd)
            }
            return (hasCompoundExpression, true)
        } else if let postfixIfExpr = expr.as(PostfixIfConfigExprSyntax.self),
            let base = postfixIfExpr.base
        {
            // For postfix-if expressions with bases (i.e., they aren't the first `#if` nested inside
            // another `#if`), add contextual breaks before the top-level clauses (and the terminating
            // `#endif`) so that they nest or line-up properly based on the preceding node. We don't do
            // this for initial nested `#if`s because they will already get open/close breaks to control
            // their indentation from their parent clause.
            before(
                postfixIfExpr.firstToken(viewMode: .sourceAccurate),
                tokens: .contextualBreakingStart
            )
            after(
                postfixIfExpr.lastToken(viewMode: .sourceAccurate),
                tokens: .contextualBreakingEnd
            )

            for clause in postfixIfExpr.config.clauses {
                before(clause.poundKeyword, tokens: .break(.contextual, size: 0))
            }
            before(postfixIfExpr.config.poundEndif, tokens: .break(.contextual, size: 0))
            after(postfixIfExpr.config.poundEndif, tokens: .break(.same, size: 0))

            return insertContextualBreaks(base, isTopLevel: false)
        } else if let callingExpr = expr.asProtocol(CallingExprSyntax.self) {
            let calledExpression = callingExpr.calledExpression
            let (hasCompoundExpression, hasMemberAccess) =
                insertContextualBreaks(calledExpression, isTopLevel: false)

            let shouldGroup =
                hasMemberAccess && (hasCompoundExpression || !isTopLevel)
                && config[AroundMultilineExpressionChainComponents.self]
            let beforeTokens: [Token] =
                shouldGroup ? [.contextualBreakingStart, .open] : [.contextualBreakingStart]
            let afterTokens: [Token] =
                shouldGroup ? [.contextualBreakingEnd, .close] : [.contextualBreakingEnd]

            if let calledMemberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
                if calledMemberAccessExpr.base != nil {
                    if isNestedInPostfixIfConfig(node: Syntax(calledMemberAccessExpr)) {
                        before(calledMemberAccessExpr.period, tokens: [.break(.same, size: 0)])
                    } else {
                        before(
                            calledMemberAccessExpr.period,
                            tokens: [.break(.contextual, size: 0)]
                        )
                    }
                }
                before(calledMemberAccessExpr.period, tokens: beforeTokens)
                after(expr.lastToken(viewMode: .sourceAccurate), tokens: afterTokens)
                if isTopLevel {
                    before(
                        expr.firstToken(viewMode: .sourceAccurate),
                        tokens: .contextualBreakingStart
                    )
                    after(expr.lastToken(viewMode: .sourceAccurate), tokens: .contextualBreakingEnd)
                }
            } else {
                before(expr.firstToken(viewMode: .sourceAccurate), tokens: beforeTokens)
                after(expr.lastToken(viewMode: .sourceAccurate), tokens: afterTokens)
            }
            return (true, hasMemberAccess)
        }

        // Otherwise, it's an expression that isn't calling another expression (e.g. array or
        // dictionary, identifier, etc.). Wrap it in a breaking context but don't try to pre-visit
        // children nodes.
        before(expr.firstToken(viewMode: .sourceAccurate), tokens: .contextualBreakingStart)
        after(expr.lastToken(viewMode: .sourceAccurate), tokens: .contextualBreakingEnd)
        let hasCompoundExpression = !expr.is(DeclReferenceExprSyntax.self)
        return (hasCompoundExpression, false)
    }

    /// Marks a comma-delimited region for the given list, inserting start/end tokens
    /// and recording the last element’s trailing comma (if any) to be ignored.
    ///
    /// - Parameters:
    ///   - node: The comma-separated list syntax node.
    ///   - isCollectionLiteral: Indicates whether the list should be treated as a collection literal during formatting.
    ///     If `true`, the list is affected by the `multiElementCollectionTrailingCommas` configuration.
    func markCommaDelimitedRegion<Node: CommaSeparatedListSyntax>(
        _ node: Node,
        isCollectionLiteral: Bool
    ) {
        if let lastElement = node.last {
            if let trailingComma = lastElement.trailingComma {
                ignoredTokens.insert(trailingComma)
            }
            before(
                node.first?.firstToken(viewMode: .sourceAccurate),
                tokens: .commaDelimitedRegionStart
            )
            let endToken =
                Token.commaDelimitedRegionEnd(
                    isCollection: isCollectionLiteral,
                    hasTrailingComma: lastElement.trailingComma != nil,
                    isSingleElement: node.first == lastElement
                )
            after(
                node.lastNodeForTrailingComma?.lastToken(viewMode: .sourceAccurate),
                tokens: [endToken]
            )
        }
    }
}
