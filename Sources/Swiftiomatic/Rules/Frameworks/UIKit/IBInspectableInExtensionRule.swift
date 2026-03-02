import SwiftSyntax

struct IBInspectableInExtensionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = IBInspectableInExtensionConfiguration()
}

extension IBInspectableInExtensionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IBInspectableInExtensionRule {}

extension IBInspectableInExtensionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(ExtensionDeclSyntax.self, VariableDeclSyntax.self)
    }

    override func visitPost(_ node: AttributeSyntax) {
      if node.attributeNameText == "IBInspectable" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
