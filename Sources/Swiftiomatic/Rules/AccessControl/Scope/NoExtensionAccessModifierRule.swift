import SwiftSyntax

struct NoExtensionAccessModifierRule {
    static let id = "no_extension_access_modifier"
    static let name = "No Extension Access Modifier"
    static let summary = "Prefer not to use extension access modifiers"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("extension String {}"),
              Example("\n\n extension String {}"),
              Example("nonisolated extension String {}"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓private extension String {}"),
              Example("↓public \n extension String {}"),
              Example("↓open extension String {}"),
              Example("↓internal extension String {}"),
              Example("↓fileprivate extension String {}"),
            ]
    }
  var options = SeverityConfiguration<Self>(.error)

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
