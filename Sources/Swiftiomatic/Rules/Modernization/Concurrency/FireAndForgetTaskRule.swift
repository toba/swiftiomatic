import SwiftSyntax

struct FireAndForgetTaskRule {
    static let id = "fire_and_forget_task"
    static let name = "Fire and Forget Task"
    static let summary = "Enhanced fire-and-forget Task detection with scope-aware severity and .onAppear+Task analysis"
    static let isOptIn = true
    static var nonTriggeringExamples: [Example] {
        [
              Example("let task = Task { await work() }"),
              Example("return Task { await work() }"),
            ]
    }
    static var triggeringExamples: [Example] {
        [
              Example(
                """
                deinit {
                    ↓Task { await cleanup() }
                }
                """,
              )
            ]
    }
  var options = SeverityConfiguration<Self>(.warning)

}

extension FireAndForgetTaskRule: SwiftSyntaxRule {
  func makeVisitor(file: SwiftSource) -> ViolationCollectingVisitor<OptionsType> {
    Visitor(configuration: options, file: file)
  }
}

extension FireAndForgetTaskRule {}

extension FireAndForgetTaskRule {
  fileprivate final class Visitor: ViolationCollectingVisitor<OptionsType> {
    private var insideViewBody = false
    private var insideInit = false

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
      guard node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }
      for binding in node.bindings {
        if binding.pattern.trimmedDescription == "body",
          let typeAnnotation = binding.typeAnnotation,
          typeAnnotation.type.trimmedDescription.contains("View")
        {
          insideViewBody = true
        }
      }
      return .visitChildren
    }

    override func visitPost(_ node: VariableDeclSyntax) {
      for binding in node.bindings {
        if binding.pattern.trimmedDescription == "body",
          let typeAnnotation = binding.typeAnnotation,
          typeAnnotation.type.trimmedDescription.contains("View")
        {
          insideViewBody = false
        }
      }
    }

    override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
      insideInit = true
      return .visitChildren
    }

    override func visitPost(_: InitializerDeclSyntax) {
      insideInit = false
    }

    override func visitPost(_ node: FunctionCallExprSyntax) {
      let callee = node.calledExpression.trimmedDescription

      if callee.hasSuffix(".onAppear") {
        checkOnAppearTask(node)
      }

      if callee == "Task" || callee == "Task.detached" {
        checkFireAndForgetTask(node)
      }
    }

    private func checkFireAndForgetTask(_ node: FunctionCallExprSyntax) {
      if TaskPatternDetector.isReturned(node)
        || TaskPatternDetector
          .isAssigned(node)
      {
        return
      }

      if insideViewBody || insideInit {
        let location = insideViewBody ? "body" : "init"
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Task created in SwiftUI View \(location) — runs on every evaluation, not tied to view lifecycle",
            severity: .warning,
            confidence: .medium,
            suggestion: "Use .task { } modifier to tie the Task to the view's lifecycle",
          ),
        )
        return
      }

      let scope = TaskPatternDetector.enclosingScope(of: node)
      switch scope {
      case .deinit, .viewDidDisappear:
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              "Fire-and-forget Task in \(scope.description) — work continues after teardown with no cancellation handle",
            severity: .error,
            confidence: .high,
            suggestion: "Assign to a stored property or use structured concurrency",
          ),
        )
      case .general:
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason: "Fire-and-forget Task — result not captured, cancellation not possible",
            severity: .warning,
            confidence: .medium,
            suggestion: "Assign to a variable if cancellation matters: `let task = Task { ... }`",
          ),
        )
      }
    }

    private func checkOnAppearTask(_ node: FunctionCallExprSyntax) {
      if let trailingClosure = node.trailingClosure,
        TaskPatternDetector.closureContainsTask(trailingClosure)
      {
        violations.append(
          SyntaxViolation(
            position: node.positionAfterSkippingLeadingTrivia,
            reason:
              ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
            severity: .warning,
            confidence: .high,
            suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
          ),
        )
        return
      }
      for argument in node.arguments {
        if let closureExpr = argument.expression.as(ClosureExprSyntax.self),
          TaskPatternDetector.closureContainsTask(closureExpr)
        {
          violations.append(
            SyntaxViolation(
              position: node.positionAfterSkippingLeadingTrivia,
              reason:
                ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
              severity: .warning,
              confidence: .high,
              suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
            ),
          )
          return
        }
      }
    }
  }
}
