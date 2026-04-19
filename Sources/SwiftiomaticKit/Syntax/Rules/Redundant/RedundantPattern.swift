import SwiftSyntax

/// Remove redundant pattern matching where all associated values are discarded.
///
/// When a case pattern matches an enum with associated values but all values are wildcards,
/// the entire argument list is redundant and can be removed.
///
/// Similarly, `let (_, _) = bar` can be simplified to `let _ = bar`.
///
/// Lint: If a redundant pattern is found, a finding is raised.
///
/// Format: The redundant pattern is removed.
final class RedundantPattern: RewriteSyntaxRule {
  override class var group: ConfigurationGroup? { .redundancies }

  // MARK: - Switch case items: case let .foo(_, _) → case .foo

  override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
    guard let simplified = simplifyEnumCasePattern(node.pattern) else {
      return node
    }
    var result = node
    result.pattern = simplified
    result.pattern.leadingTrivia = node.pattern.leadingTrivia
    return result
  }

  // MARK: - If/guard/while case: if case let .foo(_, _) = bar → if case .foo = bar

  override func visit(
    _ node: MatchingPatternConditionSyntax
  ) -> MatchingPatternConditionSyntax {
    guard let simplified = simplifyEnumCasePattern(node.pattern) else {
      return node
    }
    var result = node
    result.pattern = simplified
    result.pattern.leadingTrivia = node.pattern.leadingTrivia
    return result
  }

  // MARK: - Let/var bindings: let (_, _) = bar → let _ = bar

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    guard node.bindings.count == 1,
      let binding = node.bindings.first,
      let tuplePattern = binding.pattern.as(TuplePatternSyntax.self),
      binding.initializer != nil,
      allTupleElementsAreWildcards(tuplePattern.elements)
    else {
      return DeclSyntax(node)
    }

    diagnose(.redundantPatternBinding, on: tuplePattern)

    let wildcard = WildcardPatternSyntax(
      wildcard: .wildcardToken(
        leadingTrivia: tuplePattern.leadingTrivia,
        trailingTrivia: tuplePattern.trailingTrivia
      )
    )

    var newBinding = binding
    newBinding.pattern = PatternSyntax(wildcard)

    var result = node
    result.bindings = PatternBindingListSyntax([newBinding])
    return DeclSyntax(result)
  }

  // MARK: - Helpers

  /// Simplifies an enum case pattern that has all-wildcard arguments.
  /// Returns the simplified pattern, or nil if no simplification is possible.
  private func simplifyEnumCasePattern(_ pattern: PatternSyntax) -> PatternSyntax? {
    // Hoisted: case let .foo(_, _) → case .foo
    if let binding = pattern.as(ValueBindingPatternSyntax.self),
      let exprPattern = binding.pattern.as(ExpressionPatternSyntax.self),
      let call = exprPattern.expression.as(FunctionCallExprSyntax.self),
      call.calledExpression.is(MemberAccessExprSyntax.self),
      allCallArgumentsAreWildcards(call.arguments)
    {
      if let leftParen = call.leftParen {
        diagnose(.redundantPatternMatch, on: leftParen)
      } else {
        diagnose(.redundantPatternMatch, on: call.calledExpression)
      }

      let stripped = stripArguments(from: call)
      var newExprPattern = exprPattern
      newExprPattern.expression = ExprSyntax(stripped)
      return PatternSyntax(newExprPattern)
    }

    // Per-argument: case .foo(let _, let _) → case .foo
    if let exprPattern = pattern.as(ExpressionPatternSyntax.self),
      let call = exprPattern.expression.as(FunctionCallExprSyntax.self),
      call.calledExpression.is(MemberAccessExprSyntax.self),
      allCallArgumentsAreWildcards(call.arguments)
    {
      if let leftParen = call.leftParen {
        diagnose(.redundantPatternMatch, on: leftParen)
      } else {
        diagnose(.redundantPatternMatch, on: call.calledExpression)
      }

      let stripped = stripArguments(from: call)
      var newExprPattern = exprPattern
      newExprPattern.expression = ExprSyntax(stripped)
      return PatternSyntax(newExprPattern)
    }

    return nil
  }

  /// Checks if all arguments in a function call are wildcards (with optional let/var).
  /// Returns false for empty argument lists.
  private func allCallArgumentsAreWildcards(_ arguments: LabeledExprListSyntax) -> Bool {
    guard !arguments.isEmpty else { return false }
    for arg in arguments {
      if isWildcardArgument(arg) { continue }
      return false
    }
    return true
  }

  private func isWildcardArgument(_ arg: LabeledExprSyntax) -> Bool {
    // Real labels (with colon) mean named pattern matching, not redundant.
    if arg.label != nil, arg.colon != nil { return false }

    // Check argument text: the entire argument minus trivia/comma should be
    // just `_`, `let _`, or `var _`.
    let text = arg.expression.trimmedDescription
    // Direct wildcard: _ (as DiscardAssignmentExprSyntax or PatternExprSyntax)
    if text == "_" { return true }

    // Per-argument binding: the expression carries the full `let _` when
    // there's no label splitting.
    if text == "let _" || text == "var _" { return true }

    // Check via typed AST nodes
    let expr = arg.expression
    if expr.is(DiscardAssignmentExprSyntax.self) { return true }
    if let patternExpr = expr.as(PatternExprSyntax.self) {
      if patternExpr.pattern.is(WildcardPatternSyntax.self) { return true }
      if let binding = patternExpr.pattern.as(ValueBindingPatternSyntax.self),
        binding.pattern.is(WildcardPatternSyntax.self)
      { return true }
    }

    return false
  }

  /// Checks if an expression is a wildcard pattern (_, let _, var _).
  private func isWildcardExpression(_ expr: ExprSyntax) -> Bool {
    // Plain wildcard: _
    if expr.is(DiscardAssignmentExprSyntax.self) { return true }
    // Pattern wildcard: _ or let _ or var _
    if let patternExpr = expr.as(PatternExprSyntax.self) {
      if patternExpr.pattern.is(WildcardPatternSyntax.self) { return true }
      if let binding = patternExpr.pattern.as(ValueBindingPatternSyntax.self),
        binding.pattern.is(WildcardPatternSyntax.self)
      { return true }
    }
    return false
  }

  /// Checks if all elements in a tuple pattern are wildcards.
  private func allTupleElementsAreWildcards(_ elements: TuplePatternElementListSyntax) -> Bool {
    guard !elements.isEmpty else { return false }
    for element in elements {
      guard element.pattern.is(WildcardPatternSyntax.self) else { return false }
    }
    return true
  }

  /// Removes the argument list from a function call, keeping just the called expression.
  private func stripArguments(from call: FunctionCallExprSyntax) -> ExprSyntax {
    var result = call.calledExpression
    // Transfer trailing trivia from the closing paren
    if let rightParen = call.rightParen {
      result.trailingTrivia = rightParen.trailingTrivia
    }
    return result
  }
}

extension Finding.Message {
  fileprivate static let redundantPatternMatch: Finding.Message =
    "remove redundant pattern matching; all associated values are discarded"

  fileprivate static let redundantPatternBinding: Finding.Message =
    "replace tuple of wildcards with a single wildcard"
}
