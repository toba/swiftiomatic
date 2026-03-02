import SwiftSyntax

struct AndOperatorRule {
    static let id = "and_operator"
    static let name = "And Operator"
    static let summary = "Prefer comma over `&&` in `if`, `guard`, or `while` conditions"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example("if a, b {}"),
              Example("guard a, b else { return }"),
              Example("if a || b {}"),
              Example("let x = a && b"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("if a ↓&& b {}"),
              Example("guard a ↓&& b else { return }"),
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension AndOperatorRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension AndOperatorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ConditionElementSyntax) {
      // Check if this condition element contains a && operator
      // that could be replaced with a comma
      checkForAndOperator(in: node.condition)
    }

    private func checkForAndOperator(in syntax: some SyntaxProtocol) {
      // Look for infix && in condition expressions
      for child in syntax.children(viewMode: .sourceAccurate) {
        if let infixOp = child.as(InfixOperatorExprSyntax.self),
          let op = infixOp.operator.as(BinaryOperatorExprSyntax.self),
          op.operator.text == "&&"
        {
          // Skip if the expression also contains ||
          if containsOrOperator(infixOp) { continue }
          violations.append(op.operator.positionAfterSkippingLeadingTrivia)
        }
      }
    }

    private func containsOrOperator(_ node: some SyntaxProtocol) -> Bool {
      for descendant in node.children(viewMode: .sourceAccurate) {
        if let infixOp = descendant.as(InfixOperatorExprSyntax.self),
          let op = infixOp.operator.as(BinaryOperatorExprSyntax.self),
          op.operator.text == "||"
        {
          return true
        }
        if containsOrOperator(descendant) { return true }
      }
      return false
    }
  }
}
