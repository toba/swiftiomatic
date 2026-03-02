import SwiftSyntax

struct ForceUnwrappingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ForceUnwrappingConfiguration()
}

extension ForceUnwrappingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ForceUnwrappingRule {}

extension ForceUnwrappingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ForceUnwrapExprSyntax) {
      violations.append(node.exclamationMark.positionAfterSkippingLeadingTrivia)
    }
  }
}
