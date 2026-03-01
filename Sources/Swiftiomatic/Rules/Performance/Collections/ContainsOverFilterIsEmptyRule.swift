import SwiftSyntax

struct ContainsOverFilterIsEmptyRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "contains_over_filter_is_empty",
    name: "Contains over Filter is Empty",
    description: "Prefer `contains` over using `filter(where:).isEmpty`",
    isOptIn: true,
    nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
      [
        Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
        Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
      ]
    } + [
      Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = myList.contains(10)"),
    ],
    triggeringExamples: [
      Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
      Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
      Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty"),
      Example("let result = ↓myList.filter(where: someFunction).isEmpty"),
    ],
  )
}

extension ContainsOverFilterIsEmptyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ContainsOverFilterIsEmptyRule {}

extension ContainsOverFilterIsEmptyRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: MemberAccessExprSyntax) {
      guard
        node.declName.baseName.text == "isEmpty",
        let firstBase = node.base?.asFunctionCall,
        let firstBaseCalledExpression = firstBase.calledExpression
          .as(MemberAccessExprSyntax.self),
        firstBaseCalledExpression.declName.baseName.text == "filter"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
