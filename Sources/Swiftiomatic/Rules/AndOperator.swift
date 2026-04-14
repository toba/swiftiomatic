import SwiftSyntax

/// Prefer comma over `&&` in `if`, `guard`, and `while` conditions.
///
/// Swift condition lists use commas to separate independent boolean conditions,
/// which short-circuit identically to `&&` but read more naturally and enable
/// individual conditions to use optional binding or pattern matching.
///
/// This rule only fires when `&&` is the top-level operator in a condition element
/// (no `||` mixed in at the same precedence level, since that would change semantics).
///
/// Lint: Using `&&` in a condition list raises a warning.
///
/// Format: `&&` is replaced with commas, splitting the condition into separate
/// condition elements.
@_spi(Rules)
public final class AndOperator: SyntaxFormatRule {

  public override func visit(_ node: ConditionElementListSyntax) -> ConditionElementListSyntax {
    let visited = super.visit(node)

    // Check if any element has a top-level &&
    guard visited.contains(where: { elementHasTopLevelAnd($0) }) else {
      return visited
    }

    var newElements: [ConditionElementSyntax] = []

    for element in visited {
      guard elementHasTopLevelAnd(element),
        case .expression(let expr) = element.condition
      else {
        newElements.append(element)
        continue
      }

      // Diagnose on the first && token
      if let firstAnd = firstAndOperator(in: expr) {
        diagnose(.preferCommaOverAnd, on: firstAnd)
      }

      // Flatten the && chain into individual expressions
      var operands: [ExprSyntax] = []
      flattenAndChain(expr, into: &operands)

      for (i, operand) in operands.enumerated() {
        let isLastOperand = i == operands.count - 1
        let needsComma = !isLastOperand || element.trailingComma != nil

        var conditionExpr = operand
        if i > 0 {
          // Subsequent operands: normalize leading trivia to a single space
          conditionExpr = conditionExpr.with(\.leadingTrivia, .space)
        }
        if !isLastOperand {
          // Strip trailing trivia for non-last operands (comma handles spacing)
          conditionExpr = conditionExpr.with(\.trailingTrivia, [])
        }

        newElements.append(
          ConditionElementSyntax(
            condition: .expression(conditionExpr),
            trailingComma: needsComma
              ? TokenSyntax(.comma, presence: .present) : nil
          )
        )
      }
    }

    return ConditionElementListSyntax(newElements)
  }

  /// Returns `true` if the condition element has a top-level `&&` operator.
  private func elementHasTopLevelAnd(_ element: ConditionElementSyntax) -> Bool {
    guard case .expression(let expr) = element.condition else { return false }
    return hasTopLevelAnd(expr)
  }

  /// Returns `true` if the expression is an `&&` at the top level.
  private func hasTopLevelAnd(_ expr: ExprSyntax) -> Bool {
    guard let infix = expr.as(InfixOperatorExprSyntax.self),
      let binOp = infix.operator.as(BinaryOperatorExprSyntax.self)
    else {
      return false
    }
    return binOp.operator.text == "&&"
  }

  /// Recursively flattens an `&&` chain into individual operands.
  private func flattenAndChain(_ expr: ExprSyntax, into operands: inout [ExprSyntax]) {
    guard let infix = expr.as(InfixOperatorExprSyntax.self),
      let binOp = infix.operator.as(BinaryOperatorExprSyntax.self),
      binOp.operator.text == "&&"
    else {
      operands.append(expr)
      return
    }
    flattenAndChain(infix.leftOperand, into: &operands)
    flattenAndChain(infix.rightOperand, into: &operands)
  }

  /// Returns the first `&&` operator token in the expression tree.
  private func firstAndOperator(in expr: ExprSyntax) -> TokenSyntax? {
    guard let infix = expr.as(InfixOperatorExprSyntax.self),
      let binOp = infix.operator.as(BinaryOperatorExprSyntax.self),
      binOp.operator.text == "&&"
    else {
      return nil
    }
    return firstAndOperator(in: infix.leftOperand) ?? binOp.operator
  }
}

extension Finding.Message {
  fileprivate static let preferCommaOverAnd: Finding.Message =
    "prefer ',' over '&&' in condition list"
}
