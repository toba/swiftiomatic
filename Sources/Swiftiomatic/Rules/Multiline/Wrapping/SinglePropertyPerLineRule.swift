import SwiftSyntax

struct SinglePropertyPerLineRule {
    static let id = "single_property_per_line"
    static let name = "Single Property Per Line"
    static let summary = "Each variable declaration should declare only one property"
    static let scope: Scope = .suggest
    static var nonTriggeringExamples: [Example] {
        [
              Example("let a: Int"),
              Example("var b = false"),
              Example(
                """
                let a: Int
                let b: Int
                """,
              ),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example("↓let a, b, c: Int"),
              Example("↓var foo = 10, bar = false"),
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

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
