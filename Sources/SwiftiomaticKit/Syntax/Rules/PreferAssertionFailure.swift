import SwiftSyntax

/// Replace `assert(false, ...)` with `assertionFailure(...)` and
/// `precondition(false, ...)` with `preconditionFailure(...)`.
///
/// The `Failure` variants more clearly express intent: the code path should never be reached.
/// They also have `Never` return type, enabling the compiler to prove exhaustiveness.
///
/// Lint: Using `assert(false, ...)` or `precondition(false, ...)` raises a warning.
///
/// Format: The call is replaced with the corresponding `Failure` variant, removing the
/// `false` argument.
final class PreferAssertionFailure: SyntaxFormatRule {

  override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self) else {
      return super.visit(node)
    }

    let name = callee.baseName.text
    let replacement: String
    switch name {
    case "assert": replacement = "assertionFailure"
    case "precondition": replacement = "preconditionFailure"
    default: return super.visit(node)
    }

    // First argument must be `false`
    guard let firstArg = node.arguments.first,
      firstArg.label == nil,
      let boolLiteral = firstArg.expression.as(BooleanLiteralExprSyntax.self),
      boolLiteral.literal.tokenKind == .keyword(.false)
    else {
      return super.visit(node)
    }

    diagnose(.useFailureVariant(name: name, replacement: replacement), on: callee.baseName)

    // Build new argument list without the `false` argument
    var newArguments = Array(node.arguments.dropFirst())

    // Fix up the first remaining argument: remove its label's leading trivia artifacts
    // and remove any leading comma trivia
    if !newArguments.isEmpty {
      newArguments[0] = newArguments[0]
        .with(\.leadingTrivia, firstArg.expression.leadingTrivia)
    }

    // Update trailing comma: the last argument should have no trailing comma
    if !newArguments.isEmpty {
      let lastIdx = newArguments.count - 1
      newArguments[lastIdx] = newArguments[lastIdx].with(\.trailingComma, nil)
    }

    let newCallee = callee.with(
      \.baseName, callee.baseName.with(\.tokenKind, .identifier(replacement))
    )
    var newNode = node
    newNode.calledExpression = ExprSyntax(newCallee)
    newNode.arguments = LabeledExprListSyntax(newArguments)
    return ExprSyntax(newNode)
  }
}

extension Finding.Message {
  fileprivate static func useFailureVariant(name: String, replacement: String) -> Finding.Message {
    "replace '\(name)(false, ...)' with '\(replacement)(...)'"
  }
}
