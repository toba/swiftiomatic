import SwiftSyntax
import SwiftSyntaxBuilder

/// Remove `override` declarations whose body only forwards identical arguments to `super`.
///
/// An override that does nothing other than `super.<name>(...)` with the same parameters
/// (in order, with matching labels) adds no behavior.
///
/// The rule is conservative:
/// - Bails out if the override has any attributes (e.g. `@available`).
/// - Bails out if any parameter has a default value (the override may be tightening defaults).
/// - Bails out if the call uses a trailing closure or `try!`/`try?` (assumed to change behavior).
/// - Skips overrides explicitly required by tests (`tearDown`, `setUp`, etc.) and common
///   UIKit/AppKit lifecycle methods that are typically intentional anchors.
///
/// Lint: A finding is raised on the `override` keyword.
///
/// Format: The entire `override` declaration is removed, preserving surrounding trivia.
final class RedundantOverride: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }
    override class var defaultValue: BasicRuleValue { BasicRuleValue(rewrite: false, lint: .warn) }

    /// Methods that should never be flagged because their parent class implementations
    /// are typically intentional anchors (test lifecycle, UIKit/AppKit lifecycle).
    private static let excludedMethods: Set<String> = [
        "setUp", "setUpWithError", "tearDown", "tearDownWithError",
        "viewDidLoad", "viewWillAppear", "viewDidAppear",
        "viewWillDisappear", "viewDidDisappear",
        "awakeFromNib", "prepareForReuse", "prepareForInterfaceBuilder",
        "didReceiveMemoryWarning",
    ]

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard !Self.excludedMethods.contains(node.name.text),
            isRedundantFunctionOverride(node)
        else {
            return super.visit(node)
        }

        let overrideToken = node.modifiers.first(where: {
            $0.name.tokenKind == .keyword(.override)
        })?.name ?? node.funcKeyword

        diagnose(.removeRedundantOverride(name: node.name.text), on: overrideToken)
        return removed(node)
    }

    // MARK: - Detection

    private func isRedundantFunctionOverride(_ node: FunctionDeclSyntax) -> Bool {
        guard hasOverride(node.modifiers),
            !hasStaticOrClass(node.modifiers),
            node.attributes.isEmpty,
            let body = node.body
        else {
            return false
        }
        return forwardsToSuper(
            name: node.name.text,
            params: node.signature.parameterClause.parameters,
            body: body
        )
    }

    private func hasOverride(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(.override) }
    }

    private func hasStaticOrClass(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
    }

    /// Returns true when the body is a single statement that calls `super.<name>(args)`
    /// with arguments that exactly mirror the function's parameters.
    private func forwardsToSuper(
        name: String,
        params: FunctionParameterListSyntax,
        body: CodeBlockSyntax
    ) -> Bool {
        guard body.statements.count == 1,
            let only = body.statements.first,
            let call = extractCall(from: only),
            call.trailingClosure == nil,
            call.additionalTrailingClosures.isEmpty,
            let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            member.base?.is(SuperExprSyntax.self) == true,
            member.declName.baseName.text == name,
            !params.contains(where: { $0.defaultValue != nil }),
            params.count == call.arguments.count
        else {
            return false
        }

        for (param, arg) in zip(params, call.arguments) {
            let expectedLabel = param.firstName.text == "_" ? "" : param.firstName.text
            let expectedName = param.secondName?.text ?? param.firstName.text
            let actualLabel = arg.label?.text ?? ""
            guard actualLabel == expectedLabel,
                let ref = arg.expression.as(DeclReferenceExprSyntax.self),
                ref.baseName.text == expectedName
            else {
                return false
            }
        }
        return true
    }

    /// Unwraps `try`/`await`/`return` to find the inner function call.
    private func extractCall(from item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
        switch item.item {
        case .expr(let expr):
            return unwrapCall(expr)
        case .stmt(let stmt):
            if let returnStmt = stmt.as(ReturnStmtSyntax.self), let value = returnStmt.expression {
                return unwrapCall(value)
            }
            return nil
        default:
            return nil
        }
    }

    private func unwrapCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? {
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return call
        }
        if let awaitExpr = expr.as(AwaitExprSyntax.self) {
            return unwrapCall(awaitExpr.expression)
        }
        if let tryExpr = expr.as(TryExprSyntax.self) {
            // `try!` / `try?` may change behavior — bail out.
            guard tryExpr.questionOrExclamationMark == nil else { return nil }
            return unwrapCall(tryExpr.expression)
        }
        return nil
    }

    /// Returns an empty declaration whose only contribution is the original node's trivia.
    private func removed(_ node: some DeclSyntaxProtocol) -> DeclSyntax {
        let empty: DeclSyntax = ""
        return empty
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
    }
}

extension Finding.Message {
    fileprivate static func removeRedundantOverride(name: String) -> Finding.Message {
        "remove redundant override of '\(name)'; it only forwards to super with identical arguments"
    }
}
