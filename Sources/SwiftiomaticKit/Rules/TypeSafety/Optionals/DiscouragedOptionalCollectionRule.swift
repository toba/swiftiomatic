import SwiftiomaticSyntax

struct DiscouragedOptionalCollectionRule {
  static let id = "discouraged_optional_collection"
  static let name = "Discouraged Optional Collection"
  static let summary = "Prefer empty collection over optional collection"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    DiscouragedOptionalCollectionExamples.nonTriggeringExamples
  }

  static var triggeringExamples: [Example] {
    DiscouragedOptionalCollectionExamples.triggeringExamples
  }

  var options = SeverityOption<Self>(.warning)
}

extension DiscouragedOptionalCollectionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedOptionalCollectionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
