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

/// Function calls with no arguments and a trailing closure should not have empty parentheses.
///
/// Lint: If a function call with a trailing closure has an empty argument list with parentheses, a
/// lint error is raised.
///
/// Rewrite: Empty parentheses in function calls with trailing closures will be removed.
final class NoTrailingClosureParens: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }

    // Diagnose against the pre-traversal node so finding source locations
    // are accurate. The compact-pipeline rewrite (applyNoTrailingClosureParens
    // in Rewrites/Exprs/FunctionCallExpr.swift) handles the rewrite only.
    static func willEnter(_ node: FunctionCallExprSyntax, context: Context) {
        guard node.arguments.isEmpty,
              node.trailingClosure != nil,
              let leftParen = node.leftParen,
              let rightParen = node.rightParen,
              !leftParen.trailingTrivia.hasAnyComments,
              !rightParen.leadingTrivia.hasAnyComments,
              let name = node.calledExpression.lastToken(viewMode: .sourceAccurate),
              !node.calledExpression.is(FunctionCallExprSyntax.self),
              !node.calledExpression.is(SubscriptCallExprSyntax.self)
        else { return }
        Self.diagnose(
            .removeEmptyTrailingParentheses(name: "\(name.trimmedDescription)"),
            on: leftParen,
            context: context
        )
    }

}

fileprivate extension Finding.Message {
    static func removeEmptyTrailingParentheses(name: String) -> Finding.Message {
        "remove the empty parentheses following '\(name)'"
    }
}
