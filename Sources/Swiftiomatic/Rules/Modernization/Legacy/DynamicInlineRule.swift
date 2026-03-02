import SwiftSyntax

struct DynamicInlineRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = DynamicInlineConfiguration()
}

extension DynamicInlineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DynamicInlineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionDeclSyntax) {
      if node.modifiers.contains(where: { $0.name.text == "dynamic" }),
        node.attributes
          .contains(where: { $0.as(AttributeSyntax.self)?.isInlineAlways == true })
      {
        violations.append(node.funcKeyword.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension AttributeSyntax {
  fileprivate var isInlineAlways: Bool {
    attributeNameText == "inline"
      && arguments?.firstToken(viewMode: .sourceAccurate)?
        .tokenKind == .identifier("__always")
  }
}
