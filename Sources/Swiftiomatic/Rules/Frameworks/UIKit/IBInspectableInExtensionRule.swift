import SwiftSyntax

struct IBInspectableInExtensionRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "ibinspectable_in_extension",
    name: "IBInspectable in Extension",
    description: "Extensions shouldn't add @IBInspectable properties",
    kind: .lint,
    nonTriggeringExamples: [
      Example(
        """
        class Foo {
          @IBInspectable private var x: Int
        }
        """,
      )
    ],
    triggeringExamples: [
      Example(
        """
        extension Foo {
          ↓@IBInspectable private var x: Int
        }
        """,
      )
    ],
  )
}

extension IBInspectableInExtensionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension IBInspectableInExtensionRule: OptInRule {}

extension IBInspectableInExtensionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override var skippableDeclarations: [any DeclSyntaxProtocol.Type] {
      .allExcept(ExtensionDeclSyntax.self, VariableDeclSyntax.self)
    }

    override func visitPost(_ node: AttributeSyntax) {
      if node.attributeNameText == "IBInspectable" {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
