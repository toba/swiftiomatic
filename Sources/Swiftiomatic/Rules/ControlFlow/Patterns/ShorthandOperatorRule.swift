import SwiftSyntax

struct ShorthandOperatorRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = ShorthandOperatorConfiguration()

  fileprivate static let allOperators = ["-", "/", "+", "*"]
}

extension ShorthandOperatorRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ShorthandOperatorRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension ShorthandOperatorRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard node.operator.is(AssignmentExprSyntax.self),
        let rightExpr = node.rightOperand.as(InfixOperatorExprSyntax.self),
        let binaryOperatorExpr = rightExpr.operator.as(BinaryOperatorExprSyntax.self),
        ShorthandOperatorRule.allOperators.contains(binaryOperatorExpr.operator.text),
        node.leftOperand.trimmedDescription == rightExpr.leftOperand.trimmedDescription
      else {
        return
      }

      violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
      if let binaryOperator = node.name.binaryOperator,
        case let shorthandOperators = ShorthandOperatorRule.allOperators.map({ $0 + "=" }),
        shorthandOperators.contains(binaryOperator)
      {
        return .skipChildren
      }

      return .visitChildren
    }
  }
}

extension TokenSyntax {
  fileprivate var binaryOperator: String? {
    switch tokenKind {
    case .binaryOperator(let str):
      return str
    default:
      return nil
    }
  }
}
