import SwiftSyntax

struct NoExtensionAccessModifierRule {
  var options = SeverityConfiguration<Self>(.error)

  static let description = RuleDescription(
    identifier: "no_extension_access_modifier",
    name: "No Extension Access Modifier",
    description: "Prefer not to use extension access modifiers",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("extension String {}"),
      Example("\n\n extension String {}"),
      Example("nonisolated extension String {}"),
    ],
    triggeringExamples: [
      Example("↓private extension String {}"),
      Example("↓public \n extension String {}"),
      Example("↓open extension String {}"),
      Example("↓internal extension String {}"),
      Example("↓fileprivate extension String {}"),
    ],
  )
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
