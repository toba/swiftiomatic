import SwiftSyntax

/// Flag a `ForEach` row closure whose number of top-level views can change.
///
/// SwiftUI gives each element of a `ForEach` a fixed number of views. When one row builds a
/// different number, SwiftUI cannot map elements to views directly and falls back to a slower path.
/// An `if` without `else` , a nested `ForEach` , or several top-level views each break the
/// one-view-per-element shape. Wrap the row in one container or extract a row `View` .
///
/// Lint: A `ForEach` content closure holds an `if` without a final `else` , a `ForEach` at its top
/// level, or more than one top-level view.
final class ConstantForEachRowCount: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .swiftui }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let closure = node.rowContentClosure() else { return .visitChildren }

        let views = closure.statements.compactMap { item -> ExprSyntax? in
            if let expression = item.item.as(ExprSyntax.self) { return expression }
            return item.item.as(ExpressionStmtSyntax.self)?.expression
        }
        if views.count > 1 { diagnose(.severalViews(views.count), on: node.calledExpression) }

        for view in views {
            if let ifExpr = view.as(IfExprSyntax.self), !Self.hasFinalElse(ifExpr) {
                diagnose(.ifWithoutElse, on: ifExpr.ifKeyword)
            } else if Self.isForEach(view) { diagnose(.nestedForEach, on: view) }
        }
        return .visitChildren
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

    static func severalViews(_ count: Int) -> Finding.Message {
        "'ForEach' row builds \(count) top-level views. Wrap them in one container or a row 'View' so each element makes one view"
    }
}
