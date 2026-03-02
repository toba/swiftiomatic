import SwiftSyntax

struct ApplicationMainRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = ApplicationMainConfiguration()
}

extension ApplicationMainRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension ApplicationMainRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeSyntax) {
      let name = node.attributeName.trimmedDescription
      if name == "UIApplicationMain" || name == "NSApplicationMain" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
