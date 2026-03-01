import SwiftSyntax

struct SortTypealiasesRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "sort_typealiases",
    name: "Sort Typealiases",
    description: "Protocol composition typealiases should be sorted alphabetically",
    scope: .suggest,
    nonTriggeringExamples: [
      Example("typealias Dependencies = Bar & Foo & Quux"),
      Example("typealias Foo = Int"),
    ],
    triggeringExamples: [
      Example("typealias Dependencies = ↓Foo & Bar & Quux")
    ],
  )
}

extension SortTypealiasesRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension SortTypealiasesRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: TypeAliasDeclSyntax) {
      guard let composition = node.initializer.value.as(CompositionTypeSyntax.self),
        composition.elements.count > 1
      else { return }

      let names = composition.elements.map { element in
        // Strip `any` prefix for comparison
        let name = element.type.trimmedDescription
        return name.hasPrefix("any ") ? String(name.dropFirst(4)) : name
      }

      let sorted = names.sorted { $0.lexicographicallyPrecedes($1) }
      if names != sorted {
        violations.append(composition.elements.first!.positionAfterSkippingLeadingTrivia)
      }
    }
  }
}
