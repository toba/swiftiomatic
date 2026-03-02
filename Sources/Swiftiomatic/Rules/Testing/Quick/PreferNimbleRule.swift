import SwiftSyntax

struct PreferNimbleRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = PreferNimbleConfiguration()
}

extension PreferNimbleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PreferNimbleRule {}

extension PreferNimbleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let expr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        expr.baseName.text.starts(with: "XCTAssert")
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
