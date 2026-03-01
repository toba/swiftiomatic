import SwiftSyntax

struct ContainsOverFilterCountRule: Rule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "contains_over_filter_count",
    name: "Contains over Filter Count",
    description: "Prefer `contains` over comparing `filter(where:).count` to 0",
    nonTriggeringExamples: [">", "==", "!="].flatMap { operation in
      [
        Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 1"),
        Example("let result = myList.filter { $0 % 2 == 0 }.count \(operation) 1"),
        Example("let result = myList.filter(where: { $0 % 2 == 0 }).count \(operation) 01"),
      ]
    } + [
      Example("let result = myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = !myList.contains(where: { $0 % 2 == 0 })"),
      Example("let result = myList.contains(10)"),
    ],
    triggeringExamples: [">", "==", "!="].flatMap { operation in
      [
        Example("let result = ↓myList.filter(where: { $0 % 2 == 0 }).count \(operation) 0"),
        Example("let result = ↓myList.filter { $0 % 2 == 0 }.count \(operation) 0"),
        Example("let result = ↓myList.filter(where: someFunction).count \(operation) 0"),
      ]
    },
  )
}

extension ContainsOverFilterCountRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<ConfigurationType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension ContainsOverFilterCountRule: OptInRule {}

extension ContainsOverFilterCountRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<ConfigurationType> {
    override func visitPost(_ node: ExprListSyntax) {
      guard
        node.count == 3,
        let last = node.last?.as(IntegerLiteralExprSyntax.self),
        last.isZero,
        let second = node.dropFirst().first,
        second.firstToken(viewMode: .sourceAccurate)?.tokenKind.isZeroComparison == true,
        let first = node.first?.as(MemberAccessExprSyntax.self),
        first.declName.baseName.text == "count",
        let firstBase = first.base?.asFunctionCall,
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

extension TokenKind {
  fileprivate var isZeroComparison: Bool {
    self == .binaryOperator("==") || self == .binaryOperator("!=") || self == .binaryOperator(">")
  }
}
