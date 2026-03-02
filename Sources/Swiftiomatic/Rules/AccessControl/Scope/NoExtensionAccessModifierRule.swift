import SwiftSyntax

struct NoExtensionAccessModifierRule {
  var options = SeverityConfiguration<Self>(.error)

  static let configuration = NoExtensionAccessModifierConfiguration()
}

extension NoExtensionAccessModifierRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension NoExtensionAccessModifierRule {}

extension NoExtensionAccessModifierRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .all
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
      let modifiers = node.modifiers
      if let accessLevelModifier = modifiers.accessLevelModifier {
        violations.append(accessLevelModifier.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
