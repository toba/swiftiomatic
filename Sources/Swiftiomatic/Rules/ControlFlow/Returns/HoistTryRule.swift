import SwiftSyntax

struct HoistTryRule {
  var options = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "hoist_try",
    name: "Hoist Try",
    description:
      "Move `try` keyword to the outermost expression instead of nesting it inside arguments",
    scope: .format,
    nonTriggeringExamples: [
      Example("let result = try foo(bar)"),
      Example("let result = try foo(bar, baz)"),
      Example("try foo()"),
    ],
    triggeringExamples: [
      Example("let result = foo(↓try bar())"),
      Example("let result = foo(↓try bar(), baz)"),
      Example("let result = [↓try foo(), ↓try bar()]"),
    ],
    corrections: [
      Example("let result = foo(↓try bar())"): Example("let result = try foo(bar())")
    ],
  )
}

extension HoistTryRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension HoistTryRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard !node.isAlreadyWrappedInTry else { return }
      for arg in node.arguments {
        if let tryExpr = arg.expression.as(TryExprSyntax.self),
          tryExpr.questionOrExclamationMark == nil
        {
          violations.append(tryExpr.tryKeyword.positionAfterSkippingLeadingTrivia)
        }
      }
    }

    override func visitPost(_ node: ArrayExprSyntax) {
      guard !node.isAlreadyWrappedInTry else { return }
      for element in node.elements {
        if let tryExpr = element.expression.as(TryExprSyntax.self),
          tryExpr.questionOrExclamationMark == nil
        {
          violations.append(tryExpr.tryKeyword.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard !node.isAlreadyWrappedInTry else { return super.visit(node) }

      let hasTryArgs = node.arguments.contains { arg in
        arg.expression.as(TryExprSyntax.self)?.questionOrExclamationMark == nil
      }
      guard hasTryArgs else { return super.visit(node) }

      numberOfCorrections += 1

      // Remove try from arguments
      let newArgs = LabeledExprListSyntax(
        node.arguments.map { arg in
          guard let tryExpr = arg.expression.as(TryExprSyntax.self),
            tryExpr.questionOrExclamationMark == nil
          else {
            return arg
          }
          return arg.with(
            \.expression, tryExpr.expression.with(\.leadingTrivia, arg.expression.leadingTrivia))
        },
      )

      let newCall = node.with(\.arguments, newArgs)
      // Wrap the whole call in try
      let tryExpr = TryExprSyntax(
        leadingTrivia: newCall.leadingTrivia,
        expression: ExprSyntax(newCall.with(\.leadingTrivia, .space)),
      )
      return super.visit(ExprSyntax(tryExpr))
    }
  }
}

extension SyntaxProtocol {
  fileprivate var isAlreadyWrappedInTry: Bool {
    parent?.as(TryExprSyntax.self) != nil
  }
}
