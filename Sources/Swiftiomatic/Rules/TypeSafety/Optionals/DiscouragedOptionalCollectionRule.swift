import SwiftSyntax

struct DiscouragedOptionalCollectionRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = DiscouragedOptionalCollectionConfiguration()
}

extension DiscouragedOptionalCollectionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension DiscouragedOptionalCollectionRule {}

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
