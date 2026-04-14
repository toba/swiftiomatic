import SwiftSyntax

/// Prefer `isEmpty` over comparing `count` against zero.
///
/// Checking `count == 0` or `count != 0` (or `count > 0`) is less expressive and potentially less
/// efficient than using `isEmpty`. Collections conforming to `Collection` guarantee O(1) `isEmpty`
/// but `count` may be O(n) for some types (e.g. lazy sequences conforming to `Collection`).
///
/// When the receiver is optional (`foo?.count == 0`), the replacement uses explicit boolean
/// comparison (`foo?.isEmpty == true`) to preserve semantics.
///
/// This rule is opt-in because not every type with a `count` property also provides `isEmpty`.
///
/// Lint: Using `.count == 0`, `.count != 0`, or `.count > 0` raises a warning.
///
/// Format: The comparison is replaced with `.isEmpty` or `!.isEmpty`.
@_spi(Rules)
public final class IsEmpty: SyntaxFormatRule {
  public override class var isOptIn: Bool { true }

  public override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    let visited = super.visit(node)
    guard let infixNode = visited.as(InfixOperatorExprSyntax.self),
      let binOp = infixNode.operator.as(BinaryOperatorExprSyntax.self)
    else {
      return visited
    }

    let op = binOp.operator.text

    // Normal form: expr.count <op> 0
    if let memberAccess = infixNode.leftOperand.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.text == "count",
      isZeroLiteral(infixNode.rightOperand)
    {
      if let result = transformCountComparison(
        infixNode: infixNode, memberAccess: memberAccess, op: op)
      {
        return result
      }
    }

    // Yoda form: 0 <op> expr.count
    if let memberAccess = infixNode.rightOperand.as(MemberAccessExprSyntax.self),
      memberAccess.declName.baseName.text == "count",
      isZeroLiteral(infixNode.leftOperand)
    {
      // Flip the operator for yoda comparison
      let flippedOp: String
      switch op {
      case "==": flippedOp = "=="
      case "!=": flippedOp = "!="
      case "<": flippedOp = ">"  // 0 < count === count > 0
      default: return visited
      }
      if let result = transformCountComparison(
        infixNode: infixNode, memberAccess: memberAccess, op: flippedOp)
      {
        return result
      }
    }

    return visited
  }

  /// Transforms a `.count` comparison into an `.isEmpty` expression.
  private func transformCountComparison(
    infixNode: InfixOperatorExprSyntax,
    memberAccess: MemberAccessExprSyntax,
    op: String
  ) -> ExprSyntax? {
    let wantIsEmpty: Bool
    switch op {
    case "==": wantIsEmpty = true
    case "!=", ">": wantIsEmpty = false
    default: return nil
    }

    let isOptionalChain = hasOptionalChaining(memberAccess)

    // Diagnostic message
    let replacement: String
    if wantIsEmpty {
      replacement = isOptionalChain ? ".isEmpty == true" : ".isEmpty"
    } else {
      replacement = isOptionalChain ? ".isEmpty != true" : "!.isEmpty"
    }
    diagnose(.useIsEmpty(replacement: replacement), on: memberAccess.declName)

    // Build .isEmpty member access, replacing .count
    let isEmptyAccess = memberAccess.with(
      \.declName, DeclReferenceExprSyntax(baseName: .identifier("isEmpty"))
    )

    if isOptionalChain {
      // foo?.isEmpty == true / foo?.isEmpty != true
      let compOp = wantIsEmpty ? "==" : "!="
      let newBinOp = BinaryOperatorExprSyntax(
        operator: .binaryOperator(
          compOp, leadingTrivia: .space, trailingTrivia: .space)
      )
      let trueExpr = BooleanLiteralExprSyntax(literal: .keyword(.true))
      let result = InfixOperatorExprSyntax(
        leftOperand: ExprSyntax(isEmptyAccess),
        operator: ExprSyntax(newBinOp),
        rightOperand: ExprSyntax(trueExpr)
      )
      var expr = ExprSyntax(result)
      expr.leadingTrivia = infixNode.leadingTrivia
      expr.trailingTrivia = infixNode.trailingTrivia
      return expr
    } else if wantIsEmpty {
      // foo.isEmpty
      var result = ExprSyntax(isEmptyAccess)
      result.leadingTrivia = infixNode.leadingTrivia
      result.trailingTrivia = infixNode.trailingTrivia
      return result
    } else {
      // !foo.isEmpty
      var isEmptyExpr = ExprSyntax(isEmptyAccess)
      isEmptyExpr.leadingTrivia = []
      isEmptyExpr.trailingTrivia = infixNode.trailingTrivia

      let bangToken = TokenSyntax(
        .prefixOperator("!"),
        leadingTrivia: infixNode.leadingTrivia,
        trailingTrivia: [],
        presence: .present
      )
      let prefixExpr = PrefixOperatorExprSyntax(
        operator: bangToken,
        expression: isEmptyExpr
      )
      return ExprSyntax(prefixExpr)
    }
  }

  /// Returns `true` if the expression is the integer literal `0`.
  private func isZeroLiteral(_ expr: ExprSyntax) -> Bool {
    guard let literal = expr.as(IntegerLiteralExprSyntax.self) else {
      return false
    }
    return literal.literal.text == "0"
  }

  /// Returns `true` if the member access chain contains optional chaining (`?`).
  private func hasOptionalChaining(_ memberAccess: MemberAccessExprSyntax) -> Bool {
    var current: ExprSyntax? = memberAccess.base
    while let expr = current {
      if expr.is(OptionalChainingExprSyntax.self) {
        return true
      }
      if let nested = expr.as(MemberAccessExprSyntax.self) {
        current = nested.base
      } else {
        break
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static func useIsEmpty(replacement: String) -> Finding.Message {
    "prefer '\(replacement)' over comparing 'count' to zero"
  }
}
