import SwiftSyntax

struct UnusedOptionalBindingRule {
  var options = UnusedOptionalBindingOptions()

  static let configuration = UnusedOptionalBindingConfiguration()
}

extension UnusedOptionalBindingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension UnusedOptionalBindingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: OptionalBindingConditionSyntax) {
      guard let pattern = node.pattern.as(ExpressionPatternSyntax.self),
        pattern.expression.isDiscardExpression
      else {
        return
      }

      if configuration.ignoreOptionalTry,
        let tryExpr = node.initializer?.value.as(TryExprSyntax.self),
        tryExpr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark
      {
        return
      }

      violations.append(pattern.expression.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension ExprSyntax {
  fileprivate var isDiscardExpression: Bool {
    if `is`(DiscardAssignmentExprSyntax.self) {
      return true
    }
    if let tuple = `as`(TupleExprSyntax.self) {
      return tuple.elements.allSatisfy(\.expression.isDiscardExpression)
    }

    return false
  }
}
