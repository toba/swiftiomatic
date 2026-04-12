import SwiftiomaticSyntax

struct RedundantParensRule {
  static let id = "redundant_parens"
  static let name = "Redundant Parentheses"
  static let summary =
    "Redundant parentheses around control flow expressions and empty attribute argument lists should be removed"
  static let scope: Scope = .format
  static let isCorrectable = true
  static var nonTriggeringExamples: [Example] {
    [
      Example("if foo == true {}"),
      Example("while !flag {}"),
      Example("let x = (a, b)"),
      Example("let x = (a + b) * c"),
      Example("switch (a, b) { default: break }"),
      Example("func foo(bar: Int) {}"),
      Example("@Test func foo() {}"),
      Example("@available(iOS 16, *) func foo() {}"),
      Example("@objc(doThing:) func doThing(_ x: Int) {}"),
      Example("queue.async { doWork() }"),
      Example("foo(bar) { doWork() }"),
      Example("UIView.animate(withDuration: 1) { view.alpha = 0 }"),
      Example("let x = (a + b) * c"),
      Example("foo((bar, baz))"),
    ]
  }

  static var triggeringExamples: [Example] {
    [
      Example("if ↓(foo == true) {}"),
      Example("while ↓(flag) {}"),
      Example("guard ↓(condition) else { return }"),
      Example("↓@Test() func foo() {}"),
      Example("↓@MainActor() class Foo {}"),
      Example("queue.async↓() { doWork() }"),
      Example("DispatchQueue.main.async↓() { self.reload() }"),
      Example("let x = ↓((a + b))"),
      Example("↓((1, 2)) == ↓((3, 4))"),
    ]
  }

  static var corrections: [Example: Example] {
    [
      Example("if ↓(foo == true) {}"): Example("if foo == true {}"),
      Example("while ↓(flag) {}"): Example("while flag {}"),
      Example("↓@Test() func foo() {}"): Example("@Test func foo() {}"),
      Example("↓@MainActor() class Foo {}"): Example("@MainActor class Foo {}"),
      Example("queue.async↓() { doWork() }"): Example("queue.async { doWork() }"),
      Example("let x = ↓((a + b))"): Example("let x = (a + b)"),
      Example("↓((1, 2)) == ↓((3, 4))"): Example("(1, 2) == (3, 4)"),
    ]
  }

  var options = SeverityOption<Self>(.warning)
}

extension RedundantParensRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }

  func makeRewriter(file: SwiftSource) -> ViolationCollectingRewriter<OptionsType>? {
    Rewriter(configuration: options, file: file)
  }
}

extension RedundantParensRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    override func visitPost(_ node: AttributeSyntax) {
      if node.hasEmptyArguments {
        violations.append(node.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      if node.hasRedundantTrailingClosureParens {
        violations.append(node.leftParen!.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: TupleExprSyntax) {
      guard node.elements.count == 1,
        let onlyElement = node.elements.first,
        onlyElement.label == nil,
        onlyElement.expression.is(TupleExprSyntax.self)
      else { return }
      violations.append(node.positionAfterSkippingLeadingTrivia)
    }

    override func visitPost(_ node: ConditionElementSyntax) {
      guard let condition = node.condition.as(ExprSyntax.self)
      else { return }
      if let tupleExpr = condition.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      {
        violations.append(tupleExpr.positionAfterSkippingLeadingTrivia)
      }
    }

    override func visitPost(_ node: ReturnStmtSyntax) {
      guard let expr = node.expression,
        let tupleExpr = expr.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return }
      violations.append(tupleExpr.positionAfterSkippingLeadingTrivia)
    }
  }

  fileprivate final class Rewriter: ViolationCollectingRewriter<OptionsType> {
    override func visit(_ node: AttributeSyntax) -> AttributeSyntax {
      guard node.hasEmptyArguments else { return super.visit(node) }

      numberOfCorrections += 1
      let cleaned = node
        .with(\.leftParen, nil)
        .with(\.arguments, nil)
        .with(\.rightParen, nil)
      return super.visit(cleaned)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
      guard node.hasRedundantTrailingClosureParens else { return super.visit(node) }

      numberOfCorrections += 1
      let cleaned = node
        .with(\.leftParen, nil)
        .with(\.rightParen, nil)
      return super.visit(cleaned)
    }

    override func visit(_ node: TupleExprSyntax) -> ExprSyntax {
      // Visit children first so inner nesting is resolved bottom-up
      let visited = super.visit(node)
      guard let tuple = visited.as(TupleExprSyntax.self),
        tuple.elements.count == 1,
        let onlyElement = tuple.elements.first,
        onlyElement.label == nil,
        let innerTuple = onlyElement.expression.as(TupleExprSyntax.self)
      else { return visited }

      numberOfCorrections += 1
      return ExprSyntax(
        innerTuple
          .with(\.leadingTrivia, tuple.leadingTrivia)
          .with(\.trailingTrivia, tuple.trailingTrivia))
    }

    override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
      guard let condition = node.condition.as(ExprSyntax.self),
        let tupleExpr = condition.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return super.visit(node) }

      numberOfCorrections += 1
      let unwrapped = onlyElement.expression
        .with(\.leadingTrivia, tupleExpr.leadingTrivia)
        .with(\.trailingTrivia, tupleExpr.trailingTrivia)
      return super.visit(node.with(\.condition, .expression(unwrapped)))
    }

    override func visit(_ node: ReturnStmtSyntax) -> StmtSyntax {
      guard let expr = node.expression,
        let tupleExpr = expr.as(TupleExprSyntax.self),
        tupleExpr.elements.count == 1,
        let onlyElement = tupleExpr.elements.first,
        onlyElement.label == nil
      else { return super.visit(node) }

      numberOfCorrections += 1
      let unwrapped = onlyElement.expression
        .with(\.leadingTrivia, expr.leadingTrivia)
        .with(\.trailingTrivia, expr.trailingTrivia)
      return super.visit(node.with(\.expression, unwrapped))
    }
  }
}

extension FunctionCallExprSyntax {
  /// Whether this call has empty `()` before a trailing closure (e.g. `foo() { }`)
  fileprivate var hasRedundantTrailingClosureParens: Bool {
    leftParen != nil
      && rightParen != nil
      && arguments.isEmpty
      && trailingClosure != nil
  }
}

extension AttributeSyntax {
  /// Whether the attribute has parentheses with no arguments (e.g. `@Test()`)
  fileprivate var hasEmptyArguments: Bool {
    guard leftParen != nil, rightParen != nil else { return false }
    switch arguments {
    case .argumentList(let list):
      return list.isEmpty
    case nil:
      return true
    default:
      return false
    }
  }
}
