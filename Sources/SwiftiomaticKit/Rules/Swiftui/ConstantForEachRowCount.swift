import SwiftSyntax

/// Flag a `ForEach` row closure whose number of top-level views can change.
///
/// SwiftUI gives each element of a `ForEach` a fixed number of views. When one row builds a
/// different number, SwiftUI cannot map elements to views directly and falls back to a slower path.
/// An `if` without `else` , a nested `ForEach` , or several top-level views each break the
/// one-view-per-element shape. Wrap the row in one container or extract a row `View` .
///
/// The rule follows a call to a `@ViewBuilder` method or computed property of the same type, at the
/// top level of the row or inside a `switch` case or `if` branch. A helper that builds more than
/// one view, an `if` without `else` or a `ForEach` changes the row's view count the same way.
///
/// Lint: A `ForEach` content closure holds an `if` without a final `else` , a `ForEach` at its top
/// level, more than one top-level view, or a call to a same-type `@ViewBuilder` helper that builds
/// a variable number of views.
final class ConstantForEachRowCount: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let closure = node.rowContentClosure() else { return .visitChildren }

        let views = Self.views(in: closure.statements)
        if views.count > 1 { diagnose(.severalViews(views.count), on: node.calledExpression) }

        checkRowViews(views, in: context.typeMembers(around: node).enclosingType(of: node))
        return .visitChildren
    }

    /// The deepest chain of helper calls the rule follows
    private static let maxHelperDepth = 4

    /// Reports the views of a row, and descends into `switch` cases and `if` branches
    private func checkRowViews(_ views: [ExprSyntax], in owner: TypeMemberIndex.TypeEntry?) {
        for view in views {
            if let ifExpr = view.as(IfExprSyntax.self) {
                if !Self.hasFinalElse(ifExpr) {
                    diagnose(.ifWithoutElse, on: ifExpr.ifKeyword)
                } else {
                    for branch in Self.branches(of: ifExpr) {
                        checkRowViews(Self.views(in: branch), in: owner)
                    }
                }
            } else if let switchExpr = view.as(SwitchExprSyntax.self) {
                for case let .switchCase(switchCase) in switchExpr.cases {
                    checkRowViews(Self.views(in: switchCase.statements), in: owner)
                }
            } else if Self.isForEach(view) {
                diagnose(.nestedForEach, on: view)
            } else if let owner, let helper = Self.helper(view, in: owner),
                      Self.buildsVariableViews(helper.body, in: owner, depth: 1) {
                diagnose(.variableHelper(helper.reference.baseName.text), on: helper.reference)
            }
        }
    }

    /// Whether the statements of a helper build a number of views other than one
    private static func buildsVariableViews(
        _ statements: CodeBlockItemListSyntax,
        in owner: TypeMemberIndex.TypeEntry,
        depth: Int
    ) -> Bool {
        let views = views(in: statements)
        guard views.count == 1, let view = views.first else { return views.count > 1 }

        if let ifExpr = view.as(IfExprSyntax.self) {
            return !hasFinalElse(ifExpr) || branches(of: ifExpr).contains {
                buildsVariableViews($0, in: owner, depth: depth)
            }
        }
        if let switchExpr = view.as(SwitchExprSyntax.self) {
            return switchExpr.cases.contains {
                guard case let .switchCase(switchCase) = $0 else { return false }
                return buildsVariableViews(switchCase.statements, in: owner, depth: depth)
            }
        }
        if isForEach(view) { return true }

        if depth < maxHelperDepth, let helper = helper(view, in: owner) {
            return buildsVariableViews(helper.body, in: owner, depth: depth + 1)
        }
        return false
    }

    /// The name and body of the same-type `@ViewBuilder` helper that `view` calls or reads
    ///
    /// A helper without a result builder returns one view, so the rule does not follow it.
    private static func helper(
        _ view: ExprSyntax,
        in owner: TypeMemberIndex.TypeEntry
    ) -> (reference: DeclReferenceExprSyntax, body: CodeBlockItemListSyntax)? {
        let callee = view.as(FunctionCallExprSyntax.self)?.calledExpression ?? view
        guard let reference = callee.selfMemberReference else { return nil }

        for member in owner.members[reference.baseName.text] ?? [] {
            guard let body = member.body, hasViewBuilder(member.declaration) else { continue }
            if let block = body.as(CodeBlockSyntax.self) { return (reference, block.statements) }
            if let block = body.as(AccessorDeclSyntax.self)?.body {
                return (reference, block.statements)
            }
            if let statements = body.as(CodeBlockItemListSyntax.self) {
                return (reference, statements)
            }
        }
        return nil
    }

    private static func hasViewBuilder(_ decl: DeclSyntax) -> Bool {
        if let function = decl.as(FunctionDeclSyntax.self) {
            return function.attributes.hasResultBuilder
        }
        return decl.as(VariableDeclSyntax.self)?.attributes.hasResultBuilder == true
    }

    /// The expressions among `statements` , which are the views a result builder collects
    private static func views(in statements: CodeBlockItemListSyntax) -> [ExprSyntax] {
        statements.compactMap { item -> ExprSyntax? in
            if let expression = item.item.as(ExprSyntax.self) { return expression }
            return item.item.as(ExpressionStmtSyntax.self)?.expression
        }
    }

    /// The statements of every branch of an `if` chain that ends in `else`
    private static func branches(of ifExpr: IfExprSyntax) -> [CodeBlockItemListSyntax] {
        var result = [ifExpr.body.statements]

        switch ifExpr.elseBody {
            case nil: break
            case let .codeBlock(block): result.append(block.statements)
            case let .ifExpr(next): result += branches(of: next)
        }
        return result
    }

    private static func hasFinalElse(_ ifExpr: IfExprSyntax) -> Bool {
        switch ifExpr.elseBody {
            case nil: false
            case .codeBlock: true
            case let .ifExpr(next): hasFinalElse(next)
        }
    }

    /// Whether `expression` is a `ForEach` call, with or without modifiers applied to it
    private static func isForEach(_ expression: ExprSyntax) -> Bool {
        var current: ExprSyntax? = expression

        while let call = current?.as(FunctionCallExprSyntax.self) {
            if call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "ForEach" {
                return true
            }
            current = call.calledExpression.as(MemberAccessExprSyntax.self)?.base
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let ifWithoutElse: Finding.Message =
        "'if' without 'else' in a 'ForEach' row changes the row's view count. Add an 'else' branch or move the condition into a row 'View'"

    static let nestedForEach: Finding.Message =
        "'ForEach' directly inside a 'ForEach' row changes the row's view count. Wrap it in a container or a row 'View'"

    static func variableHelper(_ name: String) -> Finding.Message {
        "'\(name)' builds a variable number of views, so this 'ForEach' row changes its view count. Give the helper one root view or extract a row 'View'"
    }

    static func severalViews(_ count: Int) -> Finding.Message {
        "'ForEach' row builds \(count) top-level views. Wrap them in one container or a row 'View' so each element makes one view"
    }
}
