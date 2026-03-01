import SwiftSyntax

struct FlatMapOverMapReduceRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "flatmap_over_map_reduce",
    name: "Flat Map over Map Reduce",
    description: "Prefer `flatMap` over `map` followed by `reduce([], +)`",
    isOptIn: true,
    nonTriggeringExamples: [
      Example("let foo = bar.map { $0.count }.reduce(0, +)"),
      Example("let foo = bar.flatMap { $0.array }"),
    ],
    triggeringExamples: [
      Example("let foo = ↓bar.map { $0.array }.reduce([], +)")
    ],
  )
}

extension FlatMapOverMapReduceRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }
}

extension FlatMapOverMapReduceRule {}

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
