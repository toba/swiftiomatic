import SwiftSyntax

struct FlatMapOverMapReduceRule {
  static let id = "flatmap_over_map_reduce"
  static let name = "Flat Map over Map Reduce"
  static let summary = "Prefer `flatMap` over `map` followed by `reduce([], +)`"
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let foo = bar.map { $0.count }.reduce(0, +)"),
      Example("let foo = bar.flatMap { $0.array }"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension FlatMapOverMapReduceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FlatMapOverMapReduceRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard
        let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
        memberAccess.declName.baseName.text == "reduce",
        node.arguments.count == 2,
        let firstArgument = node.arguments.first?.expression.as(ArrayExprSyntax.self),
        firstArgument.elements.isEmpty,
        let secondArgument = node.arguments.last?.expression
          .as(DeclReferenceExprSyntax.self),
        secondArgument.baseName.text == "+"
      else {
        return
      }

      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }
}
