import SwiftSyntax

/// §8b/§8c: Enhanced fire-and-forget Task detection and .onAppear+Task analysis.
///
/// Replaces the basic fire-and-forget detection from AgentReviewCheck with
/// deeper AST analysis, adding scope-aware severity and .onAppear+Task detection.
final class FireAndForgetTaskCheck: BaseCheck {
    /// Whether we are currently inside a `var body: some View` computed property.
    private var insideViewBody = false

    /// Whether we are currently inside an `init` declaration.
    private var insideInit = false

    // MARK: - Scope Tracking

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Detect `var body: some View`
        guard node.bindingSpecifier.tokenKind == .keyword(.var) else {
            return .visitChildren
        }
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

    // MARK: - Fire-and-Forget Task Detection (§8b) & .onAppear+Task (§8c)

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription

        // §8c: .onAppear { Task { } } detection
        if callee.hasSuffix(".onAppear") {
            checkOnAppearTask(node)
        }

        // §8b: Unassigned Task {} detection
        if callee == "Task" || callee == "Task.detached" {
            checkFireAndForgetTask(node)
        }

        return .visitChildren
    }

    // MARK: - §8b: Unassigned Task Analysis

    private func checkFireAndForgetTask(_ node: FunctionCallExprSyntax) {
        if TaskDetectionHelpers.isReturned(node) { return }
        if TaskDetectionHelpers.isAssigned(node) { return }

        // Task in SwiftUI View body or init — lifecycle mismatch.
        if insideViewBody || insideInit {
            let location = insideViewBody ? "body" : "init"
            addFinding(
                at: node,
                category: .agentReview,
                severity: .medium,
                message:
                "Task created in SwiftUI View \(location) — runs on every evaluation, not tied to view lifecycle",
                suggestion: "Use .task { } modifier to tie the Task to the view's lifecycle",
                confidence: .medium
            )
            return
        }

        // Determine severity based on enclosing scope.
        let scope = TaskDetectionHelpers.enclosingScope(of: node)

        switch scope {
        case .deinit, .viewDidDisappear:
            addFinding(
                at: node,
                category: .agentReview,
                severity: .high,
                message:
                "Fire-and-forget Task in \(scope.description) — work continues after teardown with no cancellation handle",
                suggestion: "Assign to a stored property or use structured concurrency",
                confidence: .high
            )
        case .general:
            addFinding(
                at: node,
                category: .agentReview,
                severity: .low,
                message: "Fire-and-forget Task — result not captured, cancellation not possible",
                suggestion: "Assign to a variable if cancellation matters: `let task = Task { ... }`",
                confidence: .medium
            )
        }
    }

    // MARK: - §8c: .onAppear + Task Detection

    private func checkOnAppearTask(_ node: FunctionCallExprSyntax) {
        if let trailingClosure = node.trailingClosure {
            if TaskDetectionHelpers.closureContainsTask(trailingClosure) {
                addFinding(
                    at: node,
                    category: .agentReview,
                    severity: .medium,
                    message:
                    ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                    suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
                    confidence: .high
                )
                return
            }
        }

        for argument in node.arguments {
            if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                if TaskDetectionHelpers.closureContainsTask(closureExpr) {
                    addFinding(
                        at: node,
                        category: .agentReview,
                        severity: .medium,
                        message:
                        ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                        suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
                        confidence: .high
                    )
                    return
                }
            }
        }
    }
}
