import SwiftSyntax

struct PrivateOutletRule {
  var options = PrivateOutletOptions()

  static let configuration = PrivateOutletConfiguration()
}

extension PrivateOutletRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension PrivateOutletRule {}

extension PrivateOutletRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberBlockItemSyntax) {
      guard
        let decl = node.decl.as(VariableDeclSyntax.self),
        decl.attributes.contains(attributeNamed: "IBOutlet"),
        !decl.modifiers.containsPrivateOrFileprivate()
      else {
        return
      }

      if configuration.allowPrivateSet,
        decl.modifiers.containsPrivateOrFileprivate(setOnly: true)
      {
        return
      }

      violations.append(decl.bindingSpecifier.positionAfterSkippingLeadingTrivia)
    }
  }
}
