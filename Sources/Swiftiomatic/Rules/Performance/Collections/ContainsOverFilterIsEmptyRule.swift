import SwiftSyntax

struct ContainsOverFilterIsEmptyRule {
  static let id = "contains_over_filter_is_empty"
  static let name = "Contains over Filter is Empty"
  static let summary = "Prefer `contains` over using `filter(where:).isEmpty`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [">", "==", "!="].flatMap { operation in
      [
        Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
        Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
      ]
    } + [
      Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = myList.contains(10)"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
      Example("let result = !↓myList.filter(where: { $0 % 2 == 0 }).isEmpty"),
      Example("let result = ↓myList.filter { $0 % 2 == 0 }.isEmpty"),
      Example("let result = ↓myList.filter(where: someFunction).isEmpty"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension ContainsOverFilterIsEmptyRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

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
