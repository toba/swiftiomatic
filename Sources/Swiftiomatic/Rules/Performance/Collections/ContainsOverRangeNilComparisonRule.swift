import SwiftSyntax

struct ContainsOverRangeNilComparisonRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ContainsOverRangeNilComparisonConfiguration()
}

extension ContainsOverRangeNilComparisonRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContainsOverRangeNilComparisonRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension ContainsOverRangeNilComparisonRule {}

extension ContainsOverRangeNilComparisonRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard
        let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        operatorNode.operator.tokenKind.isEqualityComparison,
        node.rightOperand.is(NilLiteralExprSyntax.self),
        let first = node.leftOperand.asFunctionCall,
        first.arguments.onlyElement?.label?.text == "of",
        let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
        calledExpression.declName.baseName.text == "range"
      else {
        return
      }

      violations.append(first.positionAfterSkippingLeadingTrivia)
    }
  }
}
