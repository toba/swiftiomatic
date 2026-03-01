import SwiftSyntax

struct SinglePropertyPerLineRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let configuration = SinglePropertyPerLineConfiguration()

  static let description = RuleDescription(
    identifier: "single_property_per_line",
    name: "Single Property Per Line",
    description: "Each variable declaration should declare only one property",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("let a: Int"),
      Example("var b = false"),
      Example(
        """
        let a: Int
        let b: Int
        """,
      ),
    ],
    triggeringExamples: [
      Example("↓let a, b, c: Int"),
      Example("↓var foo = 10, bar = false"),
    ],
  )
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
