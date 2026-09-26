import SwiftSyntax

/// Use `map` or `flatMap` on an optional instead of an optional binding that only returns a
/// transform of the value or `nil`.
///
/// An `if let` or `guard let` whose one job is to return `f(value)` or `nil` restates what
/// `Optional.map` does. The binding adds a name, a branch and a second `return`. The expression
/// `optional.map { f($0) }` states the intent in one line. Use `flatMap` when `f` itself returns an
/// optional.
///
/// The rule matches three shapes:
///
/// - `if let x = y { return f(x) }` followed directly by `return nil`
/// - `if let x = y { return f(x) } else { return nil }`
/// - `guard let x = y else { return nil }` followed by `return f(x)` as the last statement
///
/// The shape must be the whole body of a function, initializer, accessor or closure. A binding that
/// shares its body with other statements stays as it is. Examples are the last step of a cascade of
/// `if let` casts and a `switch` case body.
///
/// The rule stays silent when the binding has more than one condition, uses `var`, binds `_`, or
/// when the returned expression does not use the bound name, returns `nil`, or contains `await`. A
/// `map` closure cannot suspend.
///
/// Lint: An optional binding that only returns a transform of the value or `nil` raises a warning.
final class UseOptionalMap: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        guard isCallableBody(node), let first = node.first?.item else { return .visitChildren }
        let next = node.dropFirst().first?.item

        if let ifExpr = ifExpression(first) {
            let fitsBody = ifExpr.elseBody == nil ? node.count == 2 : node.count == 1

            if fitsBody, matchesIfShape(ifExpr, next: next) {
                diagnose(.useOptionalMap, on: ifExpr.ifKeyword)
            }
        } else if let guardStmt = first.as(GuardStmtSyntax.self),
           node.count == 2,
           let next,
           matchesGuardShape(guardStmt, next: next) {
            diagnose(.useOptionalMap, on: guardStmt.guardKeyword)
        }
        return .visitChildren
    }

    /// Reports whether `node` is the whole body of a function, initializer, accessor or closure.
    ///
    /// A binding that shares its body with other statements, such as the last step of a cascade of
    /// `if let` casts or a `switch` case, reads better as it is.
    private func isCallableBody(_ node: CodeBlockItemListSyntax) -> Bool {
        if node.parent?.is(ClosureExprSyntax.self) == true { return true }
        if node.parent?.is(AccessorBlockSyntax.self) == true { return true }

        guard let owner = node.parent?.as(CodeBlockSyntax.self)?.parent else { return false }
        return owner.is(FunctionDeclSyntax.self) || owner.is(InitializerDeclSyntax.self)
            || owner.is(AccessorDeclSyntax.self)
    }

    private func ifExpression(_ item: CodeBlockItemSyntax.Item) -> IfExprSyntax? {
        item.as(ExpressionStmtSyntax.self)?.expression.as(IfExprSyntax.self)
            ?? item.as(IfExprSyntax.self)
    }

    private func matchesIfShape(_ node: IfExprSyntax, next: CodeBlockItemSyntax.Item?) -> Bool {
        guard let name = boundName(node.conditions),
              let result = singleReturnValue(node.body.statements),
              isTransform(result, of: name) else { return false }

        switch node.elseBody {
            case nil: return next.map(isReturnNil) ?? false
            case let .codeBlock(block)?: return isOnlyReturnNil(block.statements)
            case .ifExpr?: return false
        }
    }

    private func matchesGuardShape(
        _ node: GuardStmtSyntax,
        next: CodeBlockItemSyntax.Item
    ) -> Bool {
        guard let name = boundName(node.conditions),
              isOnlyReturnNil(node.body.statements),
              let result = next.as(ReturnStmtSyntax.self)?.expression else { return false }
        return isTransform(result, of: name)
    }

    /// Returns the name a single `let` optional binding introduces, or `nil` for any other
    /// condition list.
    private func boundName(_ conditions: ConditionElementListSyntax) -> String? {
        guard let only = conditions.firstAndOnly,
              let binding = only.condition.as(OptionalBindingConditionSyntax.self),
              binding.bindingSpecifier.tokenKind == .keyword(.let),
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else { return nil }
        return pattern.identifier.text
    }

    private func singleReturnValue(_ statements: CodeBlockItemListSyntax) -> ExprSyntax? {
        statements.firstAndOnly?.item.as(ReturnStmtSyntax.self)?.expression
    }

    private func isOnlyReturnNil(_ statements: CodeBlockItemListSyntax) -> Bool {
        statements.firstAndOnly.map { isReturnNil($0.item) } ?? false
    }

    private func isReturnNil(_ item: CodeBlockItemSyntax.Item) -> Bool {
        item.as(ReturnStmtSyntax.self)?.expression?.is(NilLiteralExprSyntax.self) ?? false
    }

    /// Reports whether `expr` can be the body of a `map` closure over the bound `name`.
    private func isTransform(_ expr: ExprSyntax, of name: String) -> Bool {
        guard !expr.is(NilLiteralExprSyntax.self),
              !expr.tokens(viewMode: .sourceAccurate).contains(where: {
                  $0.tokenKind == .keyword(.await)
              }) else { return false }
        return expr.referencesLocal(named: [name])
    }
}

fileprivate extension Finding.Message {
    static let useOptionalMap: Finding.Message =
        "use 'map' or 'flatMap' on the optional instead of binding it only to return a transform or 'nil'"
}
