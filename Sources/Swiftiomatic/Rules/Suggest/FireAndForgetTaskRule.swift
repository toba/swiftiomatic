import SwiftSyntax

struct FireAndForgetTaskRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "fire_and_forget_task",
        name: "Fire and Forget Task",
        description: "Enhanced fire-and-forget Task detection with scope-aware severity and .onAppear+Task analysis",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let task = Task { await work() }"),
            Example("return Task { await work() }"),
        ],
        triggeringExamples: [
            Example("""
            deinit {
                ↓Task { await cleanup() }
            }
            """),
        ]
    )
}

extension FireAndForgetTaskRule: SwiftSyntaxRule {
    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

extension FireAndForgetTaskRule: OptInRule {}

private extension FireAndForgetTaskRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var insideViewBody = false
        private var insideInit = false

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.bindingSpecifier.tokenKind == .keyword(.var) else { return .visitChildren }
            for binding in node.bindings {
                if binding.pattern.trimmedDescription == "body",
                   let typeAnnotation = binding.typeAnnotation,
                   typeAnnotation.type.trimmedDescription.contains("View") {
                    insideViewBody = true
                }
            }
            return .visitChildren
        }

        override func visitPost(_ node: VariableDeclSyntax) {
            for binding in node.bindings {
                if binding.pattern.trimmedDescription == "body",
                   let typeAnnotation = binding.typeAnnotation,
                   typeAnnotation.type.trimmedDescription.contains("View") {
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
            if isReturned(node) || isAssigned(node) { return }

            if insideViewBody || insideInit {
                let location = insideViewBody ? "body" : "init"
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Task created in SwiftUI View \(location) — runs on every evaluation, not tied to view lifecycle",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Use .task { } modifier to tie the Task to the view's lifecycle"
                ))
                return
            }

            let scope = enclosingScope(of: node)
            switch scope {
            case .deinit, .viewDidDisappear:
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Fire-and-forget Task in \(scope.description) — work continues after teardown with no cancellation handle",
                    severity: .error,
                    confidence: .high,
                    suggestion: "Assign to a stored property or use structured concurrency"
                ))
            case .general:
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Fire-and-forget Task — result not captured, cancellation not possible",
                    severity: .warning,
                    confidence: .medium,
                    suggestion: "Assign to a variable if cancellation matters: `let task = Task { ... }`"
                ))
            }
        }

        private func checkOnAppearTask(_ node: FunctionCallExprSyntax) {
            if let trailingClosure = node.trailingClosure, closureContainsTask(trailingClosure) {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                    severity: .warning,
                    confidence: .high,
                    suggestion: "Replace .onAppear { Task { ... } } with .task { ... }"
                ))
                return
            }
            for argument in node.arguments {
                if let closureExpr = argument.expression.as(ClosureExprSyntax.self),
                   closureContainsTask(closureExpr) {
                    violations.append(ReasonedRuleViolation(
                        position: node.positionAfterSkippingLeadingTrivia,
                        reason: ".onAppear contains Task { } — use .task modifier instead for automatic cancellation",
                        severity: .warning,
                        confidence: .high,
                        suggestion: "Replace .onAppear { Task { ... } } with .task { ... }"
                    ))
                    return
                }
            }
        }

        private func isReturned(_ node: FunctionCallExprSyntax) -> Bool {
            node.parent?.is(ReturnStmtSyntax.self) == true
        }

        private func isAssigned(_ node: FunctionCallExprSyntax) -> Bool {
            var current: Syntax? = Syntax(node)
            while let parent = current?.parent {
                if parent.is(InitializerClauseSyntax.self) || parent.is(PatternBindingSyntax.self) {
                    return true
                }
                if let infixOp = parent.as(InfixOperatorExprSyntax.self),
                   infixOp.operator.is(AssignmentExprSyntax.self) {
                    return true
                }
                if parent.is(CodeBlockItemSyntax.self) || parent.is(MemberBlockItemSyntax.self) {
                    break
                }
                current = parent
            }
            return false
        }

        private enum EnclosingScope {
            case `deinit`, viewDidDisappear, general
            var description: String {
                switch self {
                case .`deinit`: "deinit"
                case .viewDidDisappear: "viewDidDisappear"
                case .general: "general scope"
                }
            }
        }

        private func enclosingScope(of node: some SyntaxProtocol) -> EnclosingScope {
            var current: Syntax? = Syntax(node)
            while let parent = current?.parent {
                if parent.is(DeinitializerDeclSyntax.self) { return .`deinit` }
                if let funcDecl = parent.as(FunctionDeclSyntax.self), funcDecl.name.text == "viewDidDisappear" {
                    return .viewDidDisappear
                }
                if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
                    || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self) {
                    break
                }
                current = parent
            }
            return .general
        }

        private func closureContainsTask(_ closure: ClosureExprSyntax) -> Bool {
            let finder = TaskFinderVisitor(viewMode: .sourceAccurate)
            finder.walk(closure)
            return finder.foundTask
        }
    }
}

private final class TaskFinderVisitor: SyntaxVisitor, @unchecked Sendable {
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
