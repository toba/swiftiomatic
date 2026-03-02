import SwiftSyntax

struct LegacyRandomRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyRandomConfiguration()
}

extension LegacyRandomRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LegacyRandomRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private static let legacyRandomFunctions: Set<String> = [
      "arc4random",
      "arc4random_uniform",
      "drand48",
    ]

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let function = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
        Self.legacyRandomFunctions.contains(function)
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
