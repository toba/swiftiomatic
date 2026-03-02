import SwiftSyntax

struct SinglePropertyPerLineRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SinglePropertyPerLineConfiguration()
}

extension SinglePropertyPerLineRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SinglePropertyPerLineRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: VariableDeclSyntax) {
      // Skip if only one binding
      guard node.bindings.count > 1 else { return }

      // Skip conditional bindings (if let, guard let, while let)
      if node.parent?.is(ConditionElementSyntax.self) == true {
        return
      }

      violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
    }
  }
}
