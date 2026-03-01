import SwiftSyntax

struct EmptyExtensionsRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "empty_extensions",
    name: "Empty Extensions",
    description: "Empty extensions that don't add protocol conformance should be removed",
    scope: .lint,
    nonTriggeringExamples: [
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
    ],
    triggeringExamples: [
      Example(
        """
        ↓extension String {}
        """,
      )
    ],
  )
}

extension EmptyExtensionsRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension EmptyExtensionsRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
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
