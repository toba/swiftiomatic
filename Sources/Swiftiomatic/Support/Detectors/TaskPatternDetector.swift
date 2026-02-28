import SwiftSyntax

/// Shared fire-and-forget Task pattern detection, used by both
/// `FireAndForgetTaskCheck` (suggest) and `FireAndForgetTaskRule` (lint).
enum TaskPatternDetector {
    /// Whether the node is the direct child of a return statement.
    static func isReturned(_ node: FunctionCallExprSyntax) -> Bool {
        node.parent?.is(ReturnStmtSyntax.self) == true
    }

    /// Whether the Task result is assigned to a variable or binding.
    static func isAssigned(_ node: FunctionCallExprSyntax) -> Bool {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            if parent.is(InitializerClauseSyntax.self) || parent.is(PatternBindingSyntax.self) {
                return true
            }

            if let infixOp = parent.as(InfixOperatorExprSyntax.self),
               infixOp.operator.is(AssignmentExprSyntax.self)
            {
                return true
            }

            if parent.is(CodeBlockItemSyntax.self) || parent.is(MemberBlockItemSyntax.self) {
                break
            }

            current = parent
        }

        return false
    }

    /// The kind of scope enclosing a node.
    enum EnclosingScope {
        case `deinit`
        case viewDidDisappear
        case general

        var description: String {
            switch self {
                case .deinit: "deinit"
                case .viewDidDisappear: "viewDidDisappear"
                case .general: "general scope"
            }
        }
    }

    /// Walk the parent chain to determine the enclosing scope.
    static func enclosingScope(of node: some SyntaxProtocol) -> EnclosingScope {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            if parent.is(DeinitializerDeclSyntax.self) { return .deinit }
            if let funcDecl = parent.as(FunctionDeclSyntax.self),
               funcDecl.name.text == "viewDidDisappear"
            {
                return .viewDidDisappear
            }
            if parent.is(ClassDeclSyntax.self) || parent.is(StructDeclSyntax.self)
                || parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self)
            {
                break
            }
            current = parent
        }

        return .general
    }

    /// Check whether a closure body contains a `Task { }` or `Task.detached { }` call.
    static func closureContainsTask(_ closure: ClosureExprSyntax) -> Bool {
        let finder = TaskFinder(viewMode: .sourceAccurate)
        finder.walk(closure)
        return finder.foundTask
    }
}

/// A lightweight visitor that checks if a syntax subtree contains a Task {} call.
final class TaskFinder: SyntaxVisitor, @unchecked Sendable {
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
