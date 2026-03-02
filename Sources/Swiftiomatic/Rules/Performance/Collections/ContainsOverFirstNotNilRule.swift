import SwiftSyntax

struct ContainsOverFirstNotNilRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ContainsOverFirstNotNilConfiguration()
}

extension ContainsOverFirstNotNilRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContainsOverFirstNotNilRule {
  func preprocess(file: SwiftSource) -> SourceFileSyntax? {
    file.foldedSyntaxTree
  }
}

extension ContainsOverFirstNotNilRule {}

extension ContainsOverFirstNotNilRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: InfixOperatorExprSyntax) {
      guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
        operatorNode.operator.tokenKind.isEqualityComparison,
        node.rightOperand.is(NilLiteralExprSyntax.self),
        let first = node.leftOperand.asFunctionCall,
        let calledExpression = first.calledExpression.as(MemberAccessExprSyntax.self),
        ["first", "firstIndex"].contains(calledExpression.declName.baseName.text)
      else {
        return
      }

      let violation = SyntaxViolation(
        position: first.positionAfterSkippingLeadingTrivia,
        reason:
          "Prefer `contains` over `\(calledExpression.declName.baseName.text)(where:) != nil`",
      )
      violations.append(violation)
    }
  }
}
