import SwiftSyntax

/// `Task { try ... }` silently swallows thrown errors when the error type is inferred (or written
/// as `_` ).
///
/// Without an explicit `Failure` generic argument, a `Task` that throws an unhandled error doesn't
/// surface the error anywhere — there is no `throws` signature on the closure call site, and the
/// value/result of the task is usually discarded.
///
/// See: https://forums.swift.org/t/task-initializer-with-throwing-closure-swallows-error/56066
///
/// Lint: When a `Task { ... }` (with implicit or wildcard error type) contains an unhandled `throw`
/// or `try` , an error is raised. Tasks whose value or result is consumed ( `let t = Task { ... }`
/// , `Task { ... }.value` , `return Task { ... }` ) are exempt.
final class UnhandledThrowingTask: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .closures }
    override class var defaultValue: LintOnlyValue { .init(lint: .no) }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard isTaskWithImplicitErrorType(node) else { return .visitChildren }
        guard !isConsumed(node) else { return .visitChildren }
        guard taskBodyThrows(node) else { return .visitChildren }
        diagnose(.unhandledThrowingTask, on: node.calledExpression)
        return .visitChildren
    }

    /// True if `node` is `Task { ... }` or `Task<_, _> { ... }` (or any specialization where the
    /// last generic argument is `_` , meaning the error type is inferred).
    private func isTaskWithImplicitErrorType(_ node: FunctionCallExprSyntax) -> Bool {
        if let ref = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ref.baseName.text == "Task"
        {
            true
        } else if let specialized = node.calledExpression.as(GenericSpecializationExprSyntax.self),
           let ref = specialized.expression.as(DeclReferenceExprSyntax.self),
           ref.baseName.text == "Task",
           let lastArg = specialized.genericArgumentClause.arguments.last?.argument
               .as(IdentifierTypeSyntax.self),
           lastArg.name.text == "_"
        {
            true
        } else {
            false
        }
    }

    /// True if the result of the Task is captured: assigned to a binding, awaited via `.value` /
    /// `.result` , or returned.
    private func isConsumed(_ node: FunctionCallExprSyntax) -> Bool {
        guard let parent = node.parent else { return false }

        // `let t = Task { ... }`
        if parent.is(InitializerClauseSyntax.self) { return true }

        // `Task { ... }.value` or `.result`
        if let memberAccess = parent.as(MemberAccessExprSyntax.self) {
            let name = memberAccess.declName.baseName.text
            if name == "value" || name == "result" { return true }
        }

        // `executor.task = Task { ... }` (assignment in expression list)
        if let list = parent.as(ExprListSyntax.self),
           list.contains(where: { $0.is(AssignmentExprSyntax.self) })
        {
            return true
        }

        // `return Task { ... }`
        if parent.is(ReturnStmtSyntax.self) { return true }

        // Implicit return: only statement in a function body that has a return type.
        if let codeBlockItem = parent.as(CodeBlockItemSyntax.self),
           let codeBlock = codeBlockItem.parent?.parent?.as(CodeBlockSyntax.self),
           codeBlock.statements.count == 1,
           let funcDecl = codeBlock.parent?.as(FunctionDeclSyntax.self),
           funcDecl.signature.returnClause != nil
        {
            return true
        }

        return false
    }

    /// True if the trailing closure (or only argument) of `node` contains an unhandled `throw` or
    /// `try` .
    private func taskBodyThrows(_ node: FunctionCallExprSyntax) -> Bool {
        let visitor = ThrowsVisitor(viewMode: .sourceAccurate)
        if let trailing = node.trailingClosure { visitor.walk(trailing) }
        for arg in node.arguments { visitor.walk(arg) }
        return visitor.hasThrow
    }
}

/// Walks a Task body and decides whether thrown errors escape.
///
/// `try?` / `try!` and complete `do` / `catch` (where the final catch binds via an identifier
/// pattern, catching everything) silence the throw. A `Result` initializer with a trailing closure
/// also handles its body's throws.
private final class ThrowsVisitor: SyntaxVisitor {
    var hasThrow = false

    override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
        if hasThrow { return .skipChildren }

        guard let lastCatch = node.catchClauses.last else { return .visitChildren }

        // If the final catch binds via a value-binding pattern that isn't a bare identifier (e.g.
        // `catch let x as Foo` ), it doesn't catch all.
        if let bindingPattern = lastCatch.catchItems.last?.pattern?
            .as(ValueBindingPatternSyntax.self),
           !bindingPattern.pattern.is(IdentifierPatternSyntax.self)
        {
            return .visitChildren
        }

        // Walk only the catch clause; the do-body's throws are caught.
        let catchVisitor = ThrowsVisitor(viewMode: .sourceAccurate)
        catchVisitor.walk(lastCatch)
        if catchVisitor.hasThrow { hasThrow = true }
        return .skipChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if hasThrow {
            .skipChildren
        } else if let ref = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ref.baseName.text == "Result",
           node.trailingClosure != nil
        {
            .skipChildren
        } else {
            .visitChildren
        }
    }

    override func visitPost(_ node: TryExprSyntax) {
        if node.questionOrExclamationMark == nil {
            hasThrow = true
        }
    }

    override func visitPost(_: ThrowStmtSyntax) { hasThrow = true }
}

fileprivate extension Finding.Message {
    static let unhandledThrowingTask: Finding.Message =
        "errors thrown inside this Task are not handled — use `try?`/`try!`, or wrap in do/catch"
}
