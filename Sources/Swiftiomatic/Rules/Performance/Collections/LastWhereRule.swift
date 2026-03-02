import SwiftSyntax

struct LastWhereRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LastWhereConfiguration()
}

extension LastWhereRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LastWhereRule {}

extension LastWhereRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "last",
        let functionCall = node.base?.asFunctionCall,
        let calledExpression = functionCall.calledExpression
          .as(MemberAccessExprSyntax.self),
        calledExpression.declName.baseName.text == "filter",
        !functionCall.arguments.contains(where: \.expression.shouldSkip)
      else {
        return
      }

      violations.append(functionCall.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension ExprSyntax {
  fileprivate var shouldSkip: Bool {
    if `is`(StringLiteralExprSyntax.self) {
      return true
    }
    if let functionCall = `as`(FunctionCallExprSyntax.self),
      let calledExpression = functionCall.calledExpression.as(DeclReferenceExprSyntax.self),
      calledExpression.baseName.text == "NSPredicate"
    {
      return true
    }
    return false
  }
}
