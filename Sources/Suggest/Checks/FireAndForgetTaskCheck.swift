import SwiftSyntax

/// §8b/§8c: Enhanced fire-and-forget Task detection and .onAppear+Task analysis.
///
/// Replaces the basic fire-and-forget detection from AgentReviewCheck with
/// deeper AST analysis, adding scope-aware severity and .onAppear+Task detection.
public final class FireAndForgetTaskCheck: BaseCheck {

    /// Whether we are currently inside a `var body: some View` computed property.
    private var insideViewBody = false

    /// Whether we are currently inside an `init` declaration.
    private var insideInit = false

    // MARK: - Scope Tracking

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Detect `var body: some View`
        guard node.bindingSpecifier.tokenKind == .keyword(.var) else {
            return .visitChildren
        }
        for binding in node.bindings {
            if binding.pattern.trimmedDescription == "body",
               let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.trimmedDescription.contains("View") {
                insideViewBody = true
            }
        }
        return .visitChildren
    }

    override public func visitPost(_ node: VariableDeclSyntax) {
        // Reset when leaving the variable declaration.
        // Note: This resets after visiting the variable decl node itself,
        // but the accessor block children are visited before visitPost.
        for binding in node.bindings {
            if binding.pattern.trimmedDescription == "body",
               let typeAnnotation = binding.typeAnnotation,
               typeAnnotation.type.trimmedDescription.contains("View") {
                insideViewBody = false
            }
        }
    }

    override public func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        insideInit = true
        return .visitChildren
    }

    override public func visitPost(_ node: InitializerDeclSyntax) {
        insideInit = false
    }

    // MARK: - Fire-and-Forget Task Detection (§8b) & .onAppear+Task (§8c)

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
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
        // Skip if the Task result is returned — returned tasks are managed by the caller.
        if isReturned(node) {
            return
        }

        // Skip if the Task result is assigned or captured.
        if isAssigned(node) {
            return
        }

        // Task in SwiftUI View body or init — lifecycle mismatch.
        if insideViewBody || insideInit {
            let location = insideViewBody ? "body" : "init"
            addFinding(
                at: node,
                category: .agentReview,
                severity: .medium,
                message: "Task created in SwiftUI View \(location) — runs on every evaluation, not tied to view lifecycle",
                suggestion: "Use .task { } modifier to tie the Task to the view's lifecycle",
                confidence: .medium
            )
            return
        }

        // Determine severity based on enclosing scope.
        let scope = enclosingScope(of: node)

        switch scope {
        case .deinit, .viewDidDisappear:
            addFinding(
                at: node,
                category: .agentReview,
                severity: .high,
                message: "Fire-and-forget Task in \(scope.description) — work continues after teardown with no cancellation handle",
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
        // Check the trailing closure for Task {} creation.
        if let trailingClosure = node.trailingClosure {
            if closureContainsTask(trailingClosure) {
                addFinding(
                    at: node,
                    category: .agentReview,
                    severity: .medium,
                    message: ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                    suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
                    confidence: .high
                )
                return
            }
        }

        // Also check closure arguments (non-trailing closure style).
        for argument in node.arguments {
            if let closureExpr = argument.expression.as(ClosureExprSyntax.self) {
                if closureContainsTask(closureExpr) {
                    addFinding(
                        at: node,
                        category: .agentReview,
                        severity: .medium,
                        message: ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                        suggestion: "Replace .onAppear { Task { ... } } with .task { ... }",
                        confidence: .high
                    )
                    return
                }
            }
        }
    }

    // MARK: - Helpers

    /// Whether the node is the direct child of a return statement.
    private func isReturned(_ node: FunctionCallExprSyntax) -> Bool {
        node.parent?.is(ReturnStmtSyntax.self) == true
    }

    /// Whether the Task result is assigned to a variable or binding.
    private func isAssigned(_ node: FunctionCallExprSyntax) -> Bool {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            // `let task = Task { ... }` — InitializerClauseSyntax wraps the value.
            if parent.is(InitializerClauseSyntax.self) {
                return true
            }

            // Direct PatternBindingSyntax parent (less common but possible).
            if parent.is(PatternBindingSyntax.self) {
                return true
            }

            // `task = Task { ... }` — InfixOperatorExprSyntax with assignment.
            if let infixOp = parent.as(InfixOperatorExprSyntax.self),
               infixOp.operator.is(AssignmentExprSyntax.self) {
                return true
            }

            // Stop walking at statement boundaries — don't escape the expression.
            if parent.is(CodeBlockItemSyntax.self)
                || parent.is(MemberBlockItemSyntax.self) {
                break
            }

            current = parent
        }

        return false
    }

    /// The kind of scope enclosing a node.
    private enum EnclosingScope {
        case `deinit`
        case viewDidDisappear
        case general

        var description: String {
            switch self {
            case .`deinit`: "deinit"
            case .viewDidDisappear: "viewDidDisappear"
            case .general: "general scope"
            }
        }
    }

    /// Walk the parent chain to determine the enclosing scope.
    private func enclosingScope(of node: some SyntaxProtocol) -> EnclosingScope {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            if let deinitDecl = parent.as(DeinitializerDeclSyntax.self) {
                _ = deinitDecl
                return .`deinit`
            }

            if let funcDecl = parent.as(FunctionDeclSyntax.self) {
                let name = funcDecl.name.text
                if name == "viewDidDisappear" {
                    return .viewDidDisappear
                }
            }

            // Also check for accessor blocks (computed properties) — stop if we hit a type decl.
            if parent.is(ClassDeclSyntax.self)
                || parent.is(StructDeclSyntax.self)
                || parent.is(EnumDeclSyntax.self)
                || parent.is(ActorDeclSyntax.self) {
                break
            }

            current = parent
        }

        return .general
    }

    /// Check whether a closure body contains a `Task { }` or `Task.detached { }` call.
    private func closureContainsTask(_ closure: ClosureExprSyntax) -> Bool {
        let finder = TaskFinder(viewMode: .sourceAccurate)
        finder.walk(closure)
        return finder.foundTask
    }
}

// MARK: - TaskFinder

/// A lightweight visitor that checks if a syntax subtree contains a Task {} call.
private final class TaskFinder: SyntaxVisitor, @unchecked Sendable {
    var foundTask = false

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.trimmedDescription
        if callee == "Task" || callee == "Task.detached" {
            foundTask = true
            return .skipChildren
        }
        return .visitChildren
    }
}
