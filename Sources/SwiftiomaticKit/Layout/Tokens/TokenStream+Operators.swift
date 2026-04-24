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
    func visitInfixOperatorExpr(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        let binOp = node.operator
        if binOp.is(ArrowExprSyntax.self) {
            // `ArrowExprSyntax` nodes occur when a function type is written in an expression context;
            // for example, `let x = [(Int) throws -> Void]()`. We want to treat those consistently like
            // we do other function return clauses and not treat them as regular binary operators, so
            // handle that behavior there instead.
            return .visitChildren
        }

        let rhs = node.rightOperand
        maybeGroupAroundSubexpression(rhs, combiningOperator: binOp)

        let wrapsBeforeOperator = !isAssigningOperator(binOp)

        if shouldRequireWhitespace(around: binOp) {
            if isAssigningOperator(binOp) {
                var beforeTokens: [Token]

                // If the rhs starts with a parenthesized expression, stack indentation around it.
                // Otherwise, use regular continuation breaks.
                if let (unindentingNode, _, breakKind, shouldGroup) =
                    stackedIndentationBehavior(after: binOp, rhs: rhs)
                {
                    beforeTokens = [
                        .break(
                            .open(kind: breakKind),
                            newlines: .elective(ignoresDiscretionary: true)
                        ),
                    ]
                    var afterTokens: [Token] = [.break(.close(mustBreak: false), size: 0)]
                    if shouldGroup {
                        beforeTokens.append(.open)
                        afterTokens.append(.close)
                    }
                    after(
                        unindentingNode.lastToken(viewMode: .sourceAccurate),
                        tokens: afterTokens
                    )
                } else {
                    beforeTokens = [
                        .break(.continue, newlines: .elective(ignoresDiscretionary: true)),
                    ]
                }

                // When the RHS is a simple expression, even if is requires multiple lines, we don't add a
                // group so that as much of the expression as possible can stay on the same line as the
                // operator token.
                if isCompoundExpression(rhs) && leftmostMultilineStringLiteral(of: rhs) == nil {
                    beforeTokens.append(.open)
                    after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
                }

                after(binOp.lastToken(viewMode: .sourceAccurate), tokens: beforeTokens)
            } else if let (unindentingNode, shouldReset, breakKind, shouldGroup) =
                stackedIndentationBehavior(after: binOp, rhs: rhs)
            {
                // For parenthesized expressions and for unparenthesized usages of `&&` and `||`, we don't
                // want to treat all continue breaks the same. If we did, then all operators would line up
                // at the same alignment regardless of whether they were, for example, `&&` or something
                // between a pair of `&&`. To make long expressions/conditionals format more cleanly, we
                // use open-continuation/close pairs around such operators and their right-hand sides so
                // that the continuation breaks inside those scopes "stack", instead of receiving the
                // usual single-level "continuation line or not" behavior.
                var openBreakTokens: [Token] = [.break(.open(kind: breakKind))]
                if shouldGroup {
                    openBreakTokens.append(.open)
                }
                if wrapsBeforeOperator {
                    before(binOp.firstToken(viewMode: .sourceAccurate), tokens: openBreakTokens)
                } else {
                    after(binOp.lastToken(viewMode: .sourceAccurate), tokens: openBreakTokens)
                }

                var closeBreakTokens: [Token] =
                    (shouldReset ? [.break(.reset, size: 0)] : [])
                    + [.break(.close(mustBreak: false), size: 0)]
                if shouldGroup {
                    closeBreakTokens.append(.close)
                }
                after(
                    unindentingNode.lastToken(viewMode: .sourceAccurate),
                    tokens: closeBreakTokens
                )
            } else {
                if wrapsBeforeOperator {
                    before(binOp.firstToken(viewMode: .sourceAccurate), tokens: .break(.continue))
                } else {
                    after(binOp.lastToken(viewMode: .sourceAccurate), tokens: .break(.continue))
                }
            }

            if wrapsBeforeOperator {
                after(binOp.lastToken(viewMode: .sourceAccurate), tokens: .space)
            } else {
                before(binOp.firstToken(viewMode: .sourceAccurate), tokens: .space)
            }
        }

        return .visitChildren
    }

    func visitPrefixOperatorExpr(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitPostfixOperatorExpr(_ node: PostfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }

    func visitAsExpr(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.asKeyword, tokens: .break(.continue), .open)
        before(node.type.firstToken(viewMode: .sourceAccurate), tokens: .space)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitIsExpr(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.isKeyword, tokens: .break(.continue), .open)
        before(node.type.firstToken(viewMode: .sourceAccurate), tokens: .space)
        after(node.lastToken(viewMode: .sourceAccurate), tokens: .close)
        return .visitChildren
    }

    func visitSequenceExpr(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        preconditionFailure(
            """
            SequenceExpr should have already been folded; found at byte offsets \
            \(node.position.utf8Offset)..<\(node.endPosition.utf8Offset)
            """
        )
    }

    func visitAssignmentExpr(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        // Breaks and spaces are inserted at the `InfixOperatorExpr` level.
        return .visitChildren
    }

    func visitBinaryOperatorExpr(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        // Breaks and spaces are inserted at the `InfixOperatorExpr` level.
        return .visitChildren
    }

    func visitArrowExpr(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.arrow, tokens: .break)
        after(node.arrow, tokens: .space)
        return .visitChildren
    }

    func visitSuperExpr(_ node: SuperExprSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }
}
