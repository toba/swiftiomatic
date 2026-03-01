import SwiftSyntax

struct DiscouragedOptionalCollectionRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "discouraged_optional_collection",
    name: "Discouraged Optional Collection",
    description: "Prefer empty collection over optional collection",
    nonTriggeringExamples: DiscouragedOptionalCollectionExamples.nonTriggeringExamples,
    triggeringExamples: DiscouragedOptionalCollectionExamples.triggeringExamples,
  )
}

extension DiscouragedOptionalCollectionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension DiscouragedOptionalCollectionRule: OptInRule {}

extension DiscouragedOptionalCollectionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: OptionalTypeSyntax) {
      if node.wrappedType.isCollectionType {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}

extension SyntaxProtocol {
  fileprivate var isCollectionType: Bool {
    `is`(ArrayTypeSyntax.self) || `is`(DictionaryTypeSyntax.self)
      || `as`(IdentifierTypeSyntax.self)?.isCollectionType == true
  }
}

extension IdentifierTypeSyntax {
  fileprivate var isCollectionType: Bool {
    ["Array", "Dictionary", "Set"].contains(name.text)
  }
}
