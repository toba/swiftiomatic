import SwiftSyntax

struct IBInspectableInExtensionRule {
    static let id = "ibinspectable_in_extension"
    static let name = "IBInspectable in Extension"
    static let summary = "Extensions shouldn't add @IBInspectable properties"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example(
                """
                class Foo {
                  @IBInspectable private var x: Int
                }
                """,
              )
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                extension Foo {
                  ↓@IBInspectable private var x: Int
                }
                """,
              )
            ]
    }
  var options = SeverityOption<Self>(.warning)

}

extension IBInspectableInExtensionRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension IBInspectableInExtensionRule {}

extension IBInspectableInExtensionRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
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
