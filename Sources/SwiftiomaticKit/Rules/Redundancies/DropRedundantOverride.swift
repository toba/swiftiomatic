import SwiftSyntax

/// Flag an `override` whose body only forwards identical arguments to `super`
///
/// An override that does nothing other than `super.<name>(...)` with the same parameters (in order,
/// with matching labels) usually adds no behavior.
///
/// The rule reports and never rewrites. Source alone does not say whether the declaration is dead.
/// A forwarding override can raise the access level, hold the override point open for a later edit,
/// or exist to prove the signature still matches the superclass. Deleting one of those deletes
/// working code, so the decision stays with the reader.
///
/// The check is conservative:
/// - Skips an override that carries any attribute (e.g. `@available` ).
/// - Skips an override with a defaulted parameter, because the override may tighten the default.
/// - Skips a call that uses a trailing closure or `try!` / `try?` , which may change behavior.
/// - Skips an override required by tests ( `tearDown` , `setUp` ) and the common UIKit and AppKit
///   lifecycle methods, which are usually intentional anchors.
///
/// Lint: A finding is raised on the `override` keyword.
final class DropRedundantOverride: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    /// Methods that the rule never flags, because an override of one is usually an intentional
    /// anchor (test lifecycle, UIKit and AppKit lifecycle).
    private static let excludedMethods: Set<String> = [
        "setUp", "setUpWithError", "tearDown", "tearDownWithError",
        "viewDidLoad", "viewWillAppear", "viewDidAppear",
        "viewWillDisappear", "viewDidDisappear",
        "awakeFromNib", "prepareForReuse", "prepareForInterfaceBuilder",
        "didReceiveMemoryWarning",
    ]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard !Self.excludedMethods.contains(node.name.text),
              Self.isRedundantFunctionOverride(node) else { return .visitChildren }

        let overrideModifier = node.modifiers.first { $0.name.tokenKind == .keyword(.override) }
        let anchor = overrideModifier?.name ?? node.funcKeyword

        diagnose(.removeRedundantOverride(name: node.name.text), on: anchor)
        return .visitChildren
    }

    // MARK: - Detection

    private static func isRedundantFunctionOverride(_ node: FunctionDeclSyntax) -> Bool {
        guard hasOverride(node.modifiers),
              !hasStaticOrClass(node.modifiers),
              node.attributes.isEmpty,
              let body = node.body else { return false }
        return forwardsToSuper(
            name: node.name.text,
            params: node.signature.parameterClause.parameters,
            body: body
        )
    }

    private static func hasOverride(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains { $0.name.tokenKind == .keyword(.override) }
    }

    private static func hasStaticOrClass(_ modifiers: DeclModifierListSyntax) -> Bool {
        modifiers.contains {
            $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
        }
    }

    /// Returns true when the body is a single statement that calls `super.<name>(args)` with
    /// arguments that exactly mirror the function's parameters.
    private static func forwardsToSuper(
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
              params.count == call.arguments.count else { return false }

        for (param, arg) in zip(params, call.arguments) {
            let expectedLabel = param.firstName.text == "_" ? "" : param.firstName.text
            let expectedName = param.secondName?.text ?? param.firstName.text
            let actualLabel = arg.label?.text ?? ""
            guard actualLabel == expectedLabel,
                  let ref = arg.expression.as(DeclReferenceExprSyntax.self),
                  ref.baseName.text == expectedName else { return false }
        }
        return true
    }

    /// Unwraps `try` / `await` / `return` to find the inner function call.
    private static func extractCall(from item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
        switch item.item {
            case let .expr(expr): return unwrapCall(expr)
            case let .stmt(stmt):
                if let returnStmt = stmt.as(ReturnStmtSyntax.self),
                   let value = returnStmt.expression { return unwrapCall(value) }
                return nil
            default: return nil
        }
    }

    private static func unwrapCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? {
        if let call = expr.as(FunctionCallExprSyntax.self) { return call }
        if let awaitExpr = expr.as(AwaitExprSyntax.self) { return unwrapCall(awaitExpr.expression) }

        if let tryExpr = expr.as(TryExprSyntax.self) {
            // a forced or optional try may change behavior, so bail out
            guard tryExpr.questionOrExclamationMark == nil else { return nil }
            return unwrapCall(tryExpr.expression)
        }
        return nil
    }
}

fileprivate extension Finding.Message {
    static func removeRedundantOverride(name: String) -> Finding.Message {
        """
        override of '\(name)' only forwards to super with identical arguments. \
        Remove it when nothing depends on the declaration
        """
    }
}
