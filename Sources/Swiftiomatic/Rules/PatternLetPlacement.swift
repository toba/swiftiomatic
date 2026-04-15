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

/// Enforce consistent placement of `let`/`var` in case patterns.
///
/// Controlled by `Configuration.patternLet.placement`:
///
/// - `eachBinding` (default): Each variable has its own `let`/`var`:
///   `case .foo(let x, let y)`.
/// - `outerPattern`: The `let`/`var` is hoisted to the pattern level:
///   `case let .foo(x, y)`.
///
/// Lint: Using the non-preferred placement yields a lint error.
///
/// Format: The `let`/`var` is repositioned to match the configured placement.
@_spi(Rules)
public final class PatternLetPlacement: SyntaxFormatRule {

  // MARK: - Visitors

  public override func visit(_ node: MatchingPatternConditionSyntax) -> MatchingPatternConditionSyntax {
    switch context.configuration.patternLet.placement {
    case .eachBinding:
      if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
        diagnose(.distributeLetInBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        return result
      }
    case .outerPattern:
      if let (replacement, specifier) = hoistLetVarFromPattern(node.pattern) {
        diagnose(.hoistLetFromBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        return result
      }
    }
    return super.visit(node)
  }

  public override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
    switch context.configuration.patternLet.placement {
    case .eachBinding:
      if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
        diagnose(.distributeLetInBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        result.leadingTrivia = node.leadingTrivia
        return result
      }
    case .outerPattern:
      if let (replacement, specifier) = hoistLetVarFromPattern(node.pattern) {
        diagnose(.hoistLetFromBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        result.leadingTrivia = node.leadingTrivia
        return result
      }
    }
    return super.visit(node)
  }

  public override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    guard node.caseKeyword != nil else {
      return super.visit(node)
    }

    switch context.configuration.patternLet.placement {
    case .eachBinding:
      if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
        diagnose(.distributeLetInBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        return StmtSyntax(result)
      }
    case .outerPattern:
      if let (replacement, specifier) = hoistLetVarFromPattern(node.pattern) {
        diagnose(.hoistLetFromBoundCaseVariables(specifier), on: node.pattern)
        var result = node
        result.pattern = PatternSyntax(replacement)
        return StmtSyntax(result)
      }
    }
    return super.visit(node)
  }
}

// MARK: - Distribute (eachBinding mode)

extension PatternLetPlacement {
  private enum OptionalPatternKind {
    case chained
    case forced
  }

  /// Wraps the given expression in the optional chaining and/or force
  /// unwrapping expressions, as described by the specified stack.
  private func restoreOptionalChainingAndForcing(
    _ expr: ExprSyntax,
    patternStack: [(OptionalPatternKind, Trivia)]
  ) -> ExprSyntax {
    var patternStack = patternStack
    var result = expr

    // As we unwind the stack, wrap the expression in optional chaining
    // or force unwrap expressions.
    while let (kind, trivia) = patternStack.popLast() {
      if kind == .chained {
        result = ExprSyntax(
          OptionalChainingExprSyntax(
            expression: result,
            trailingTrivia: trivia
          )
        )
      } else {
        result = ExprSyntax(
          ForceUnwrapExprSyntax(
            expression: result,
            trailingTrivia: trivia
          )
        )
      }
    }

    return result
  }

  /// Returns a rewritten version of the given pattern if bindings can be moved
  /// into bound cases.
  private func distributeLetVarThroughPattern(
    _ pattern: PatternSyntax
  ) -> (ExpressionPatternSyntax, TokenSyntax)? {
    guard let bindingPattern = pattern.as(ValueBindingPatternSyntax.self),
      let exprPattern = bindingPattern.pattern.as(ExpressionPatternSyntax.self)
    else { return nil }

    // Grab the `let` or `var` used in the binding pattern.
    var specifier = bindingPattern.bindingSpecifier
    specifier.leadingTrivia = []
    let identifierBinder = BindIdentifiersRewriter(bindingSpecifier: specifier)

    // Drill down into any optional patterns that we encounter (e.g., `case let .foo(x)?`).
    var patternStack: [(OptionalPatternKind, Trivia)] = []
    var expression = exprPattern.expression
    while true {
      if let optionalExpr = expression.as(OptionalChainingExprSyntax.self) {
        expression = optionalExpr.expression
        patternStack.append((.chained, optionalExpr.questionMark.trailingTrivia))
      } else if let forcedExpr = expression.as(ForceUnwrapExprSyntax.self) {
        expression = forcedExpr.expression
        patternStack.append((.forced, forcedExpr.exclamationMark.trailingTrivia))
      } else {
        break
      }
    }

    // Enum cases are written as function calls on member access expressions. The arguments
    // are the associated values, so the `let/var` can be distributed into those.
    if var functionCall = expression.as(FunctionCallExprSyntax.self),
      functionCall.calledExpression.is(MemberAccessExprSyntax.self)
    {
      var result = exprPattern
      let newArguments = identifierBinder.rewrite(functionCall.arguments)
      functionCall.arguments = newArguments.as(LabeledExprListSyntax.self)!
      result.expression = restoreOptionalChainingAndForcing(
        ExprSyntax(functionCall),
        patternStack: patternStack
      )
      return (result, specifier)
    }

    // A tuple expression can have the `let/var` distributed into the elements.
    if var tupleExpr = expression.as(TupleExprSyntax.self) {
      var result = exprPattern
      let newElements = identifierBinder.rewrite(tupleExpr.elements)
      tupleExpr.elements = newElements.as(LabeledExprListSyntax.self)!
      result.expression = restoreOptionalChainingAndForcing(
        ExprSyntax(tupleExpr),
        patternStack: patternStack
      )
      return (result, specifier)
    }

    // Otherwise, we're not sure this is a pattern we can distribute through.
    return nil
  }
}

// MARK: - Hoist (outerPattern mode)

extension PatternLetPlacement {

  /// Returns a rewritten version of the given pattern if bindings can be hoisted
  /// to the outer pattern level.
  private func hoistLetVarFromPattern(
    _ pattern: PatternSyntax
  ) -> (ValueBindingPatternSyntax, TokenSyntax)? {
    // Already hoisted — nothing to do.
    if pattern.is(ValueBindingPatternSyntax.self) { return nil }

    guard let exprPattern = pattern.as(ExpressionPatternSyntax.self) else { return nil }

    let expression = exprPattern.expression

    // Enum case: .foo(let x, let y)
    if let functionCall = expression.as(FunctionCallExprSyntax.self),
      functionCall.calledExpression.is(MemberAccessExprSyntax.self)
    {
      return hoistFromArguments(functionCall.arguments, exprPattern: exprPattern)
    }

    // Tuple: (let x, let y)
    if let tupleExpr = expression.as(TupleExprSyntax.self) {
      return hoistFromArguments(tupleExpr.elements, exprPattern: exprPattern)
    }

    return nil
  }

  /// Checks if all arguments have the same binding specifier and returns a hoisted pattern.
  private func hoistFromArguments(
    _ arguments: LabeledExprListSyntax,
    exprPattern: ExpressionPatternSyntax
  ) -> (ValueBindingPatternSyntax, TokenSyntax)? {
    var commonSpecifier: TokenSyntax?
    var hasAtLeastOneBinding = false

    for argument in arguments {
      guard let patternExpr = argument.expression.as(PatternExprSyntax.self) else {
        return nil
      }

      if let binding = patternExpr.pattern.as(ValueBindingPatternSyntax.self) {
        hasAtLeastOneBinding = true
        if let existing = commonSpecifier {
          guard existing.tokenKind == binding.bindingSpecifier.tokenKind else {
            return nil  // Mixed let/var
          }
        } else {
          commonSpecifier = binding.bindingSpecifier
        }
      } else if patternExpr.pattern.is(WildcardPatternSyntax.self) {
        // Wildcards are fine — they don't need bindings.
      } else {
        // Literal match or other non-binding pattern — can't hoist.
        return nil
      }
    }

    guard hasAtLeastOneBinding, let specifier = commonSpecifier else { return nil }

    // Remove ValueBindingPatternSyntax from each argument.
    let unbinder = UnbindIdentifiersRewriter()
    let newArguments = unbinder.rewrite(arguments).as(LabeledExprListSyntax.self)!

    // Rebuild the expression with unbound arguments.
    var cleanExprPattern = exprPattern
    if var functionCall = exprPattern.expression.as(FunctionCallExprSyntax.self) {
      functionCall.arguments = newArguments
      cleanExprPattern.expression = ExprSyntax(functionCall)
    } else if var tupleExpr = exprPattern.expression.as(TupleExprSyntax.self) {
      tupleExpr.elements = newArguments
      cleanExprPattern.expression = ExprSyntax(tupleExpr)
    }

    // Wrap in ValueBindingPatternSyntax with the specifier before the pattern.
    var hoistedSpecifier = specifier
    hoistedSpecifier.leadingTrivia = cleanExprPattern.leadingTrivia
    hoistedSpecifier.trailingTrivia = [.spaces(1)]
    cleanExprPattern.leadingTrivia = []

    let hoisted = ValueBindingPatternSyntax(
      bindingSpecifier: hoistedSpecifier,
      pattern: PatternSyntax(cleanExprPattern)
    )

    return (hoisted, specifier)
  }
}

extension Finding.Message {
  fileprivate static func distributeLetInBoundCaseVariables(
    _ specifier: TokenSyntax
  ) -> Finding.Message {
    "move this '\(specifier.text)' keyword inside the 'case' pattern, before each of the bound variables"
  }

  fileprivate static func hoistLetFromBoundCaseVariables(
    _ specifier: TokenSyntax
  ) -> Finding.Message {
    "move '\(specifier.text)' keyword to precede the 'case' pattern"
  }
}

/// A syntax rewriter that converts identifier patterns to bindings
/// with the given specifier.
private final class BindIdentifiersRewriter: SyntaxRewriter {
  var bindingSpecifier: TokenSyntax

  init(bindingSpecifier: TokenSyntax) {
    self.bindingSpecifier = bindingSpecifier
  }

  override func visit(_ node: PatternExprSyntax) -> ExprSyntax {
    guard let identifier = node.pattern.as(IdentifierPatternSyntax.self) else {
      return super.visit(node)
    }

    let binding = ValueBindingPatternSyntax(
      bindingSpecifier: bindingSpecifier,
      pattern: identifier
    )
    var result = node
    result.pattern = PatternSyntax(binding)
    return ExprSyntax(result)
  }
}

/// A syntax rewriter that removes ValueBindingPatternSyntax wrappers,
/// leaving just the inner pattern.
private final class UnbindIdentifiersRewriter: SyntaxRewriter {
  override func visit(_ node: PatternExprSyntax) -> ExprSyntax {
    guard let binding = node.pattern.as(ValueBindingPatternSyntax.self) else {
      return ExprSyntax(node)
    }
    var result = node
    result.pattern = binding.pattern
    return ExprSyntax(result)
  }
}
