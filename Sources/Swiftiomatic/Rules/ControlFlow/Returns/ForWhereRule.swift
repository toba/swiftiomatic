import SwiftSyntax

struct ForWhereRule {
  var options = ForWhereOptions()

  static let configuration = ForWhereConfiguration()
}

extension ForWhereRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ForWhereRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ForStmtSyntax) {
      guard node.whereClause == nil,
        let onlyExprStmt = node.body.statements.onlyElement?.item
          .as(ExpressionStmtSyntax.self),
        let ifExpr = onlyExprStmt.expression.as(IfExprSyntax.self),
        ifExpr.elseBody == nil,
        !ifExpr.containsOptionalBinding,
        !ifExpr.containsPatternCondition,
        let condition = ifExpr.conditions.onlyElement,
        !condition.containsMultipleConditions
      else {
        return
      }

      if configuration.allowForAsFilter, ifExpr.containsReturnStatement {
        return
      }

      violations.append(ifExpr.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension IfExprSyntax {
  fileprivate var containsOptionalBinding: Bool {
    conditions.contains { element in
      element.condition.is(OptionalBindingConditionSyntax.self)
    }
  }

  fileprivate var containsPatternCondition: Bool {
    conditions.contains { element in
      element.condition.is(MatchingPatternConditionSyntax.self)
    }
  }

  fileprivate var containsReturnStatement: Bool {
    body.statements.contains { element in
      element.item.is(ReturnStmtSyntax.self)
    }
  }
}

extension ConditionElementSyntax {
  fileprivate var containsMultipleConditions: Bool {
    guard let condition = condition.as(SequenceExprSyntax.self) else {
      return false
    }

    return condition.elements.contains { expr in
      guard let binaryExpr = expr.as(BinaryOperatorExprSyntax.self) else {
        return false
      }

      let operators: Set = ["&&", "||"]
      return operators.contains(binaryExpr.operator.text)
    }
  }
}
