import SwiftSyntax

struct LegacyHashingRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = LegacyHashingConfiguration()
}

extension LegacyHashingRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension LegacyHashingRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      guard
        node.parent?.is(MemberBlockItemSyntax.self) == true,
        node.bindingSpecifier.tokenKind == .keyword(.var),
        let binding = node.bindings.onlyElement,
        let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
        identifier.identifier.text == "hashValue",
        let returnType = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self),
        returnType.name.text == "Int"
      else {
        return
      }

      violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
    }
  }
}
