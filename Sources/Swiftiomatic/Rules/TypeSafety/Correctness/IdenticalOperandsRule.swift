import SwiftSyntax

struct IdenticalOperandsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = IdenticalOperandsConfiguration()
}

extension IdenticalOperandsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IdenticalOperandsRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension IdenticalOperandsRule {}

extension IdenticalOperandsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        IdenticalOperandsConfiguration.operators.contains(operatorNode.operator.text)
      else {
        return
      }

      if node.leftOperand.normalizedDescription == node.rightOperand.normalizedDescription {
        violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension ExprSyntax {
  fileprivate var normalizedDescription: String {
    debugDescription(includeTrivia: false)
  }
}
