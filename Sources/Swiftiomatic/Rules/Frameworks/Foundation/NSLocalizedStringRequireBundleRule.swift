import SwiftSyntax

struct NSLocalizedStringRequireBundleRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = NSLocalizedStringRequireBundleConfiguration()
}

extension NSLocalizedStringRequireBundleRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NSLocalizedStringRequireBundleRule {}

extension NSLocalizedStringRequireBundleRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
        identifierExpr.baseName.tokenKind == .identifier("NSLocalizedString"),
        !node.arguments.containsArgument(named: "bundle")
      {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension LabeledExprListSyntax {
  fileprivate func containsArgument(named name: String) -> Bool {
    contains { arg in
      arg.label?.tokenKind == .identifier(name)
    }
  }
}
