import SwiftSyntax

struct EmptyExtensionsRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = EmptyExtensionsConfiguration()
}

extension EmptyExtensionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension EmptyExtensionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: ExtensionDeclSyntax) {
      // Skip if it has protocol conformances
      if let inheritanceClause = node.inheritanceClause,
        !inheritanceClause.inheritedTypes.isEmpty
      {
        return
      }

      // Skip if it has any members
      guard node.memberBlock.members.isEmpty else { return }

      // Skip if it has attributes (could be a macro)
      guard !node.attributes.contains(where: { _ in true }) else { return }

      violations.append(node.extensionKeyword.positionAfterSkippingLeadingTrivia)
    }
  }
}
