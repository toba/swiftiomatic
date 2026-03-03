import SwiftSyntax

struct AssertionFailuresRule {
  static let id = "assertion_failures"
  static let name = "Assertion Failures"
  static let summary =
    "Prefer `assertionFailure()` over `assert(false)` and `preconditionFailure()` over `precondition(false)`"
  static let isCorrectable = true
  static let isOptIn = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("assert(true)"),
      Example(#"assert(true, "message")"#),
      Example("assert(false || true)"),
      Example("assertionFailure()"),
      Example("preconditionFailure()"),
      Example("XCTAssert(false)"),
      Example("precondition(condition)"),
    ]
  }
  static var triggeringExamples: [Example] {
    [
      Example("↓assert(false)"),
      Example(#"↓assert(false, "message")"#),
      Example(#"↓assert(false, "message", 2, 1)"#),
      Example("↓precondition(false)"),
      Example(#"↓precondition(false, "message")"#),
    ]
  }
  static var corrections: [Example: Example] {
    [
      Example("↓assert(false)"): Example("assertionFailure()"),
      Example(#"↓assert(false, "message")"#): Example(#"assertionFailure("message")"#),
      Example(#"↓assert(false, "msg", 2, 1)"#): Example(#"assertionFailure("msg", 2, 1)"#),
      Example("↓precondition(false)"): Example("preconditionFailure()"),
      Example(#"↓precondition(false, "msg")"#): Example(#"preconditionFailure("msg")"#),
    ]
  }
  var options = SeverityOption<Self>(.warning)
}

private let replacements: [String: String] = [
  "assert": "assertionFailure",
  "precondition": "preconditionFailure",
]

extension AssertionFailuresRule: SwiftSyntaxCorrectableRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension AssertionFailuresRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: FunctionCallExprSyntax) {
      guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
        replacements.keys.contains(callee.baseName.text),
        let firstArg = node.arguments.first,
        firstArg.label == nil,
        let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
        boolExpr.literal.tokenKind == .keyword(.false)
      else {
        return
      }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard let callee = node.calledExpression.as(DeclReferenceExprSyntax.self),
        let replacement = replacements[callee.baseName.text],
        let firstArg = node.arguments.first,
        firstArg.label == nil,
        let boolExpr = firstArg.expression.as(BooleanLiteralExprSyntax.self),
        boolExpr.literal.tokenKind == .keyword(.false)
      else {
        return super.visit(node)
      }

      numberOfCorrections += 1

      // Build new argument list: drop the first argument (false), keep the rest
      var remainingArgs = Array(node.arguments.dropFirst())

      if let first = remainingArgs.first {
        // Remove the leading comma from what was the second argument
        remainingArgs[0] = first
          .with(\.leadingTrivia, first.expression.leadingTrivia)
      }

      // Remove trailing comma from last arg if present
      if var last = remainingArgs.last {
        last = last.with(\.trailingComma, nil)
        remainingArgs[remainingArgs.count - 1] = last
      }

      let newCallee = callee.with(
        \.baseName,
        .identifier(
          replacement,
          leadingTrivia: callee.baseName.leadingTrivia,
          trailingTrivia: callee.baseName.trailingTrivia
        )
      )
      let newNode = node
        .with(\.calledExpression, ExprSyntax(newCallee))
        .with(\.arguments, LabeledExprListSyntax(remainingArgs))

      return super.visit(ExprSyntax(newNode))
    }
  }
}
