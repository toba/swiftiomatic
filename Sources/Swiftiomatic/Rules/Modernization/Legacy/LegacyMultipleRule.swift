import SwiftSyntax

struct LegacyMultipleRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyMultipleConfiguration()
}

extension LegacyMultipleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LegacyMultipleRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension LegacyMultipleRule {}

extension LegacyMultipleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        operatorNode.operator.tokenKind == .binaryOperator("%"),
        let parent = node.parent?.as(InfixOperatorExprSyntax.self),
        let parentOperatorNode = parent.operator.as(BinaryOperatorExprSyntax.self),
        parentOperatorNode.isEqualityOrInequalityOperator
      else {
        return
      }

      let isExprEqualTo0 = {
        parent.leftOperand.as(InfixOperatorExprSyntax.self) == node
          && parent.rightOperand.as(IntegerLiteralExprSyntax.self)?.isZero == true
      }

      let is0EqualToExpr = {
        parent.leftOperand.as(IntegerLiteralExprSyntax.self)?.isZero == true
          && parent.rightOperand.as(InfixOperatorExprSyntax.self) == node
      }

      guard isExprEqualTo0() || is0EqualToExpr() else {
        return
      }

      violations.append(node.operator.positionAfterSkippingLeadingTrivia)
    }
  }
}

extension BinaryOperatorExprSyntax {
  fileprivate var isEqualityOrInequalityOperator: Bool {
    `operator`.tokenKind == .binaryOperator("==")
      || `operator`
        .tokenKind == .binaryOperator("!=")
  }
}
