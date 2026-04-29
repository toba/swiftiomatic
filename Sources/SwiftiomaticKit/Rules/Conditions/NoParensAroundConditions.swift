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

/// Enforces rules around parentheses in conditions, matched expressions, return statements, and
/// initializer assignments.
///
/// Parentheses are not used around any condition of an `if`, `guard`, or `while` statement, around
/// the matched expression in a `switch` statement, around `return` values, or around initializer
/// values in variable/constant declarations.
///
/// Lint: If a top-most expression in a `switch`, `if`, `guard`, `while`, or `return` statement, or
///       in a variable initializer, is surrounded by parentheses, and it does not include a function
///       call with a trailing closure, a lint error is raised.
///
/// Rewrite: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.
///         Specifically, parentheses are allowed if and only if the expression contains a function
///         call with a trailing closure.
final class NoParensAroundConditions: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }

  // Diagnose against the pre-traversal node so finding source locations are
  // accurate. The compact-pipeline rewrite (in
  // `Rewrites/Stmts/NoParensAroundConditionsHelpers.swift`) handles the
  // rewrite without diagnose.
  static func willEnter(_ node: ConditionElementSyntax, context: Context) {
    guard case .expression(let expr) = node.condition else { return }
    _ = noParensMinimalSingleExpression(expr, context: context, diagnose: true)
  }

  static func willEnter(_ node: SwitchExprSyntax, context: Context) {
    _ = noParensMinimalSingleExpression(node.subject, context: context, diagnose: true)
  }

  static func willEnter(_ node: RepeatStmtSyntax, context: Context) {
    _ = noParensMinimalSingleExpression(node.condition, context: context, diagnose: true)
  }

  static func willEnter(_ node: ReturnStmtSyntax, context: Context) {
    if let expr = node.expression {
      _ = noParensMinimalSingleExpression(expr, context: context, diagnose: true)
    }
  }

  static func willEnter(_ node: InitializerClauseSyntax, context: Context) {
    _ = noParensMinimalSingleExpression(node.value, context: context, diagnose: true)
  }
}
