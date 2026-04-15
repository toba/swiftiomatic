import SwiftSyntax

/// Multiline conditional assignment expressions are wrapped after the
/// assignment operator.
///
/// When assigning an `if` or `switch` expression that spans multiple lines,
/// the `=` should be on the same line as the property, and a line break
/// should follow `=` before the `if`/`switch` keyword.
///
/// Lint: A multiline `if`/`switch` expression on the same line as `=` raises
///       a warning.
///
/// Format: A line break is inserted after `=`.
@_spi(Rules)
public final class WrapConditionalAssignment: SyntaxFormatRule {

  public override class var isOptIn: Bool { true }

  // MARK: - let/var declarations

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard let initializer = node.initializer else { return node }
    let value = initializer.value
    guard value.is(IfExprSyntax.self) || value.is(SwitchExprSyntax.self) else { return node }
    guard isMultiline(value) else { return node }

    let equal = initializer.equal
    let valueFirstToken = value.firstToken(viewMode: .sourceAccurate)!

    // Case 1: `=` is on a different line from the property — move it up
    if equal.leadingTrivia.containsNewlines {
      diagnose(.wrapAfterAssignment, on: equal)
      var result = node
      var newInit = initializer
      // Move `=`'s leading trivia (comments, newlines) to the if/switch keyword
      let movedTrivia = equal.leadingTrivia
      newInit.equal = equal
        .with(\.leadingTrivia, .space)
        .with(\.trailingTrivia, [])
      var newValue = value
      newValue.leadingTrivia = movedTrivia + valueFirstToken.leadingTrivia
      newInit.value = newValue
      result.initializer = newInit
      return result
    }

    // Case 2: No line break between `=` and `if`/`switch` — add one
    if !valueFirstToken.leadingTrivia.containsNewlines {
      diagnose(.wrapAfterAssignment, on: equal)
      var result = node
      var newInit = initializer
      newInit.equal = equal.with(\.trailingTrivia, [])
      var newValue = value
      newValue.leadingTrivia = .newline + valueFirstToken.leadingTrivia
      newInit.value = newValue
      result.initializer = newInit
      return result
    }

    return node
  }

  // MARK: - Reassignments (x = if/switch ...)

  public override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    guard let assignment = node.operator.as(AssignmentExprSyntax.self) else {
      return ExprSyntax(node)
    }
    let rhs = node.rightOperand
    guard rhs.is(IfExprSyntax.self) || rhs.is(SwitchExprSyntax.self) else {
      return ExprSyntax(node)
    }
    guard isMultiline(rhs) else { return ExprSyntax(node) }

    let equal = assignment.equal
    let rhsFirstToken = rhs.firstToken(viewMode: .sourceAccurate)!

    // Case 1: `=` is on a different line from the LHS — move it up
    if equal.leadingTrivia.containsNewlines {
      diagnose(.wrapAfterAssignment, on: equal)
      var result = node
      let movedTrivia = equal.leadingTrivia
      var newAssignment = assignment
      newAssignment.equal = equal
        .with(\.leadingTrivia, .space)
        .with(\.trailingTrivia, [])
      result.operator = ExprSyntax(newAssignment)
      var newRHS = rhs
      newRHS.leadingTrivia = movedTrivia + rhsFirstToken.leadingTrivia
      result.rightOperand = newRHS
      return ExprSyntax(result)
    }

    // Case 2: No line break between `=` and `if`/`switch` — add one
    if !rhsFirstToken.leadingTrivia.containsNewlines {
      diagnose(.wrapAfterAssignment, on: equal)
      var result = node
      var newAssignment = assignment
      newAssignment.equal = equal.with(\.trailingTrivia, [])
      result.operator = ExprSyntax(newAssignment)
      var newRHS = rhs
      newRHS.leadingTrivia = .newline + rhsFirstToken.leadingTrivia
      result.rightOperand = newRHS
      return ExprSyntax(result)
    }

    return ExprSyntax(node)
  }

  // MARK: - Helpers

  /// Returns `true` if the expression spans multiple lines (has internal
  /// newlines after the first token).
  private func isMultiline(_ node: some SyntaxProtocol) -> Bool {
    var tokens = node.tokens(viewMode: .sourceAccurate).makeIterator()
    _ = tokens.next()  // skip first token
    while let token = tokens.next() {
      if token.leadingTrivia.containsNewlines { return true }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let wrapAfterAssignment: Finding.Message =
    "wrap multiline conditional assignment after '='"
}
