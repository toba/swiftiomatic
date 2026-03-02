import SwiftSyntax

struct ContainsOverFilterIsEmptyRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ContainsOverFilterIsEmptyConfiguration()
}

extension ContainsOverFilterIsEmptyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ContainsOverFilterIsEmptyRule {}

extension ContainsOverFilterIsEmptyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "isEmpty",
        let firstBase = node.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "filter"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
