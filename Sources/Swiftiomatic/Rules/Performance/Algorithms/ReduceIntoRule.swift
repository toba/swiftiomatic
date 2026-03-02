import SwiftSyntax

struct ReduceIntoRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ReduceIntoConfiguration()
}

extension ReduceIntoRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ReduceIntoRule {}

extension ReduceIntoRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let name = node.nameToken,
        name.text == "reduce",
        node.arguments
          .count == 2 || (node.arguments.count == 1 && node.trailingClosure != nil),
        let firstArgument = node.arguments.first,
        // would otherwise equal "into"
        firstArgument.label == nil,
        firstArgument.expression.isCopyOnWriteType
      else {
        return
      }

      violations.append(name.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension FunctionCallExprSyntax {
  fileprivate var nameToken: TokenSyntax? {
    if let expr = calledExpression.as(MemberAccessExprSyntax.self) {
      return expr.declName.baseName
    }
    if let expr = calledExpression.as(DeclReferenceExprSyntax.self) {
      return expr.baseName
    }

    return nil
  }
}

extension ExprSyntax {
  fileprivate var isCopyOnWriteType: Bool {
    if `is`(StringLiteralExprSyntax.self) || `is`(DictionaryExprSyntax.self)
      || `is`(ArrayExprSyntax.self)
    {
      return true
    }

    if let expr = `as`(FunctionCallExprSyntax.self) {
      if let identifierExpr = expr.calledExpression.identifierExpr {
        return identifierExpr.isCopyOnWriteType
      }
      if let memberAccesExpr = expr.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccesExpr.declName.baseName.text == "init",
        let identifierExpr = memberAccesExpr.base?.identifierExpr
      {
        return identifierExpr.isCopyOnWriteType
      }
      if expr.calledExpression.isCopyOnWriteType {
        return true
      }
    }

    return false
  }

  fileprivate var identifierExpr: DeclReferenceExprSyntax? {
    if let identifierExpr = `as`(DeclReferenceExprSyntax.self) {
      return identifierExpr
    }
    if let specializeExpr = `as`(GenericSpecializationExprSyntax.self) {
      return specializeExpr.expression.identifierExpr
    }

    return nil
  }
}

extension DeclReferenceExprSyntax {
  private static let copyOnWriteTypes: Set = ["Array", "Dictionary", "Set"]

  fileprivate var isCopyOnWriteType: Bool {
    Self.copyOnWriteTypes.contains(baseName.text)
  }
}
