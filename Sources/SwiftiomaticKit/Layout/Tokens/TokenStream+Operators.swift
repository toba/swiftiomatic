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
        if binOp.is(ArrowExprSyntax.self) { return .visitChildren }

        let rhs = node.rightOperand
        maybeGroupAroundSubexpression(rhs, combiningOperator: binOp)

        let wrapsBeforeOperator = !isAssigningOperator(binOp)

        if shouldRequireWhitespace(around: binOp) {
            if isAssigningOperator(binOp) {
                // Wrap a member-access / subscript LHS chain in `.open/.close` so its contextual
                // breaks have their break-chunk bounded by the LHS group instead of extending
                // across the `=` and consuming the entire RHS. Without this bound, the LHS's first
                // contextual break sees the whole assignment as its chunk and fires prematurely,
                // splitting `obj.member = value` across multiple lines.
                let lhs = node.leftOperand

                if isMemberAccessChain(lhs),
                   let lhsFirst = lhs.firstToken(viewMode: .sourceAccurate),
                   let lhsLast = lhs.lastToken(viewMode: .sourceAccurate)
                {
                    before(lhsFirst, tokens: .open)
                    after(lhsLast, tokens: .close)
                }
                if let equal = binOp.lastToken(viewMode: .sourceAccurate) {
                    arrangeAssignmentBreaks(
                        afterEqualToken: equal,
                        rhs: rhs,
                        operatorExpr: binOp
                    )
                }
            } else if let (unindentingNode, shouldReset, breakKind, shouldGroup) =
                stackedIndentationBehavior(after: binOp, rhs: rhs)
            {
                // For parenthesized expressions and for unparenthesized usages of `&&` and `||` ,
                // we don't want to treat all continue breaks the same. If we did, then all
                // operators would line up at the same alignment regardless of whether they were,
                // for example, `&&` or something between a pair of `&&` . To make long
                // expressions/conditionals format more cleanly, we use open-continuation/close
                // pairs around such operators and their right-hand sides so that the continuation
                // breaks inside those scopes "stack", instead of receiving the usual single-level
                // "continuation line or not" behavior.
                var openBreakTokens: [Token] = [.break(.open(kind: breakKind))]
                if shouldGroup { openBreakTokens.append(.open) }

                if wrapsBeforeOperator {
                    before(binOp.firstToken(viewMode: .sourceAccurate), tokens: openBreakTokens)
                } else {
                    after(binOp.lastToken(viewMode: .sourceAccurate), tokens: openBreakTokens)
                }

                var closeBreakTokens: [Token] = (shouldReset ? [.break(.reset, size: 0)] : [])
                    + [.break(.close(mustBreak: false), size: 0)]
                if shouldGroup { closeBreakTokens.append(.close) }
                after(
                    unindentingNode.lastToken(viewMode: .sourceAccurate),
                    tokens: closeBreakTokens
                )
            } else if isComparisonOperator(binOp),
               containsCallOrSubscriptArgList(node.leftOperand)
                   || containsCallOrSubscriptArgList(rhs)
            {
                // Bound the comparison-operator break's chunk to the RHS so any inner break (e.g. a
                // function-call argument-list break in either operand) fires first. Mirrors the
                // assignment precedence treatment in `arrangeAssignmentBreaks` (
                // `canGroupBeforeBreak` branch). Gated on the presence of a call/subscript arg list
                // so simple comparisons like `mod.detail == nil` are not affected.
                if wrapsBeforeOperator {
                    before(
                        binOp.firstToken(viewMode: .sourceAccurate),
                        tokens: .open, .break(.continue)
                    )
                    after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
                } else {
                    after(
                        binOp.lastToken(viewMode: .sourceAccurate),
                        tokens: .open, .break(.continue)
                    )
                    after(rhs.lastToken(viewMode: .sourceAccurate), tokens: .close)
                }
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

    func visitPrefixOperatorExpr(_: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitPostfixOperatorExpr(_: PostfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
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

    func visitAssignmentExpr(_: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitBinaryOperatorExpr(_: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
        .visitChildren
    }

    func visitArrowExpr(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
        before(node.arrow, tokens: .break)
        after(node.arrow, tokens: .space)
        return .visitChildren
    }

    func visitSuperExpr(_: SuperExprSyntax) -> SyntaxVisitorContinueKind { .visitChildren }
}
