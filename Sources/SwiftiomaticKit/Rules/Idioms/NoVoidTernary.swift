import SwiftSyntax

/// Don't use a ternary expression to call void-returning functions.
///
/// `condition ? doA() : doB()` reads as if it produces a value, but when both branches return
/// `Void` it's effectively a hidden if/else with strictly worse readability. Use a proper `if` /
/// `else` statement instead.
///
/// Lint: A warning is raised when a ternary appears as a statement and both branches are call
/// expressions.
///
/// Rewrite: Not auto-fixed; the rewrite would change formatting beyond the scope of this rule.
final class NoVoidTernary: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .warn) }

    override func visit(_ node: TernaryExprSyntax) -> ExprSyntax {
        if isStandaloneStatementTernary(node),
           node.thenExpression.is(FunctionCallExprSyntax.self),
           node.elseExpression.is(FunctionCallExprSyntax.self)
        {
            diagnose(.noVoidTernary, on: node.questionMark)
        }
        return super.visit(node)
    }

    /// Returns true if this ternary is at the statement boundary (its enclosing CodeBlockItem has
    /// more than just this expression — i.e. it isn't an implicit return) — or, more simply, the
    /// ternary is the top expression of a CodeBlockItem that contains multiple statements (so it
    /// can't be an implicit return) or whose enclosing context doesn't allow implicit returns.
    private func isStandaloneStatementTernary(_ node: TernaryExprSyntax) -> Bool {
        // Walk up to find the enclosing CodeBlockItem.
        var current = Syntax(node)
        while let parent = current.parent {
            if parent.is(CodeBlockItemSyntax.self) {
                guard let blockItem = parent.as(CodeBlockItemSyntax.self) else { return false }
                // The ternary must be the entire item expression (no assignment etc.).
                guard let itemExpr = blockItem.item.as(ExprSyntax.self) else { return false }
                guard isExprChainTopOf(node, expr: itemExpr) else { return false }
                return !isImplicitReturn(blockItem)
            }
            // If we hit an assignment or other infix, this is part of an expression — bail.
            if parent.is(InfixOperatorExprSyntax.self) { return false }
            if parent.is(AssignmentExprSyntax.self) { return false }
            if parent.is(LabeledExprSyntax.self) { return false }
            if parent.is(FunctionCallExprSyntax.self) { return false }
            current = parent
        }
        return false
    }

    /// True if `inner` is reachable from `outer` purely through ExprSyntax wrapping (i.e. the
    /// ternary IS the entire expression of the CodeBlockItem).
    private func isExprChainTopOf(_ inner: TernaryExprSyntax, expr: ExprSyntax) -> Bool {
        if expr.id == ExprSyntax(inner).id {
            true
        } else if let tuple = expr.as(TupleExprSyntax.self),
           tuple.elements.count == 1,
           let onlyExpr = tuple.elements.first?.expression
        {
            isExprChainTopOf(inner, expr: onlyExpr)
        } else {
            false
        }
    }

    /// Determine if the enclosing CodeBlockItem is the only statement in a context that allows
    /// implicit return (so a ternary there is a value-producing expression, not a statement).
    private func isImplicitReturn(_ item: CodeBlockItemSyntax) -> Bool {
        guard let listSyntax = item.parent?.as(CodeBlockItemListSyntax.self) else { return false }
        // Multiple statements -> definitely a statement, not implicit return.
        if listSyntax.children(viewMode: .sourceAccurate).count != 1 { return false }
        guard let grandparent = listSyntax.parent else { return false }

        // Closure: implicit return.
        if grandparent.is(ClosureExprSyntax.self) { return true }

        // Variable/subscript getter shorthand: `var x: T { expr }` or `subscript ... { expr }` —
        // the CodeBlockItemList is directly inside an AccessorBlockSyntax.
        if grandparent.is(AccessorBlockSyntax.self) { return true }

        // CodeBlock: check what owns it.
        if let codeBlock = grandparent.as(CodeBlockSyntax.self) {
            guard let owner = codeBlock.parent else { return false }

            // Function: only when return type allows implicit returns.
            if let funcDecl = owner.as(FunctionDeclSyntax.self) {
                return funcDecl.signature.allowsImplicitReturns
            }

            // Accessor (get): always allows implicit return.
            if owner.is(AccessorDeclSyntax.self) { return true }

            // Subscript: check return type.
            if let subscriptDecl = owner.as(SubscriptDeclSyntax.self) {
                return subscriptDecl.returnClause.allowsImplicitReturns
            }
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let noVoidTernary: Finding.Message =
        "use 'if'/'else' instead of a ternary to call void-returning functions"
}

private extension FunctionSignatureSyntax {
    var allowsImplicitReturns: Bool { returnClause?.allowsImplicitReturns ?? false }
}

private extension ReturnClauseSyntax {
    var allowsImplicitReturns: Bool {
        if let simple = type.as(IdentifierTypeSyntax.self) {
            simple.name.text != "Void" && simple.name.text != "Never"
        } else if let tuple = type.as(TupleTypeSyntax.self) {
            !tuple.elements.isEmpty
        } else {
            true
        }
    }
}
