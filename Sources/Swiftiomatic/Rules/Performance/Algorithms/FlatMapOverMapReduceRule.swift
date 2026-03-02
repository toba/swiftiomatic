import SwiftSyntax

struct FlatMapOverMapReduceRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = FlatMapOverMapReduceConfiguration()
}

extension FlatMapOverMapReduceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FlatMapOverMapReduceRule {}

extension FlatMapOverMapReduceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "reduce",
        node.arguments.count == 2,
        let firstArgument = node.arguments.first?.expression.as(ArrayExprSyntax.self),
        firstArgument.elements.isEmpty,
        let secondArgument = node.arguments.last?.expression
          .as(DeclReferenceExprSyntax.self),
        secondArgument.baseName.text == "+"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
