import SwiftSyntax

struct HoistAwaitRule {
  var configuration = SeverityConfiguration<Self>(.warning)

  static let description = RuleDescription(
    identifier: "hoist_await",
    name: "Hoist Await",
    description:
      "Move `await` keyword to the outermost expression instead of nesting it inside arguments",
    scope: .format,
    minSwiftVersion: .v6,
    nonTriggeringExamples: [
      Example("let result = await foo(bar)"),
      Example("let result = await foo(bar, baz)"),
    ],
    triggeringExamples: [
      Example("let result = foo(↓await bar())"),
      Example("let result = foo(↓await bar(), baz)"),
      Example("let result = [↓await foo(), ↓await bar()]"),
    ],
    corrections: [
      Example("let result = foo(↓await bar())"): Example("let result = await foo(bar())")
    ],
  )
}

extension HoistAwaitRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: configuration, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: configuration, file: file)
  }
}

extension HoistAwaitRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard !node.isAlreadyWrappedInAwait else { return }
      for arg in node.arguments {
        if arg.expression.is(AwaitExprSyntax.self) {
          violations.append(arg.expression.positionAfterSkippingLeadingTrivia)
        }
      }
    }

    override func visitPost(_ node: ArrayExprSyntax) {
      guard !node.isAlreadyWrappedInAwait else { return }
      for element in node.elements {
        if element.expression.is(AwaitExprSyntax.self) {
          violations.append(element.expression.positionAfterSkippingLeadingTrivia)
        }
      }
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard !node.isAlreadyWrappedInAwait else { return super.visit(node) }

      let hasAwaitArgs = node.arguments.contains { $0.expression.is(AwaitExprSyntax.self) }
      guard hasAwaitArgs else { return super.visit(node) }

      numberOfCorrections += 1

      let newArgs = LabeledExprListSyntax(
        node.arguments.map { arg in
          guard let awaitExpr = arg.expression.as(AwaitExprSyntax.self) else {
            return arg
          }
          return arg.with(
            \.expression, awaitExpr.expression.with(\.leadingTrivia, arg.expression.leadingTrivia))
        },
      )

      let newCall = node.with(\.arguments, newArgs)
      let awaitExpr = AwaitExprSyntax(
        leadingTrivia: newCall.leadingTrivia,
        expression: ExprSyntax(newCall.with(\.leadingTrivia, .space)),
      )
      return super.visit(ExprSyntax(awaitExpr))
    }
  }
}

extension SyntaxProtocol {
  fileprivate var isAlreadyWrappedInAwait: Bool {
    parent?.as(AwaitExprSyntax.self) != nil
  }
}
