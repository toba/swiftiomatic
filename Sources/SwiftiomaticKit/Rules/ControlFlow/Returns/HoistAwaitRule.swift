import SwiftSyntax

struct HoistAwaitRule {
  static let id = "hoist_await"
  static let name = "Hoist Await"
  static let summary =
    "Move `await` keyword to the outermost expression instead of nesting it inside arguments"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("let result = await foo(bar)"),
      Example("let result = await foo(bar, baz)"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("let result = foo(↓await bar())"),
      Example("let result = foo(↓await bar(), baz)"),
      Example("let result = [↓await foo(), ↓await bar()]"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("let result = foo(↓await bar())"): Example("let result = await foo(bar())")
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension HoistAwaitRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
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
            \.expression,
            awaitExpr.expression.with(
              \.leadingTrivia,
              arg.expression.leadingTrivia,
            ),
          )
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
