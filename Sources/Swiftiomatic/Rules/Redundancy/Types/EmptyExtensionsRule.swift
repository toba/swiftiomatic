import SwiftSyntax

struct EmptyExtensionsRule {
    static let id = "empty_extensions"
    static let name = "Empty Extensions"
    static let summary = "Empty extensions that don't add protocol conformance should be removed"
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                extension String: Equatable {}
                """,
              ),
              Example(
                """
                extension Foo {
                  func bar() {}
                }
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                ↓extension String {}
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
