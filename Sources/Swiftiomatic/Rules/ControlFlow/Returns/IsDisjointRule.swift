import SwiftSyntax

struct IsDisjointRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = IsDisjointConfiguration()
}

extension IsDisjointRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IsDisjointRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "isEmpty",
        let firstBase = node.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "intersection"
      else {
        return
      }

      violations.append(
        firstBaseCalledExpression.declName.baseName.positionAfterSkippingLeadingTrivia,
      )
    }
  }
}
