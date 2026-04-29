import SwiftSyntax

/// Stateless helpers for the inlined `RedundantOverride` rule. The rule's
/// `static transform(_ FunctionDeclSyntax, parent:context:)` overload
/// delegates to `applyRedundantOverride(_:parent:context:)`.

/// Methods that should never be flagged because their parent class
/// implementations are typically intentional anchors (test lifecycle,
/// UIKit/AppKit lifecycle).
private let redundantOverrideExcludedMethods: Set<String> = [
    "setUp", "setUpWithError", "tearDown", "tearDownWithError",
    "viewDidLoad", "viewWillAppear", "viewDidAppear",
    "viewWillDisappear", "viewDidDisappear",
    "awakeFromNib", "prepareForReuse", "prepareForInterfaceBuilder",
    "didReceiveMemoryWarning",
]

func applyRedundantOverride(
    _ node: FunctionDeclSyntax,
    parent: Syntax?,
    context: Context
) -> DeclSyntax {
    _ = parent
    guard !redundantOverrideExcludedMethods.contains(node.name.text),
        redundantOverrideIsRedundantFunctionOverride(node)
    else {
        return DeclSyntax(node)
    }

    let overrideToken = node.modifiers.first(where: {
        $0.name.tokenKind == .keyword(.override)
    })?.name ?? node.funcKeyword

    RedundantOverride.diagnose(
        .removeRedundantOverride(name: node.name.text),
        on: overrideToken,
        context: context
    )
    return redundantOverrideRemoved(node)
}

// MARK: - Detection

private func redundantOverrideIsRedundantFunctionOverride(
    _ node: FunctionDeclSyntax
) -> Bool {
    guard redundantOverrideHasOverride(node.modifiers),
        !redundantOverrideHasStaticOrClass(node.modifiers),
        node.attributes.isEmpty,
        let body = node.body
    else {
        return false
    }
    return redundantOverrideForwardsToSuper(
        name: node.name.text,
        params: node.signature.parameterClause.parameters,
        body: body
    )
}

private func redundantOverrideHasOverride(
    _ modifiers: DeclModifierListSyntax
) -> Bool {
    modifiers.contains { $0.name.tokenKind == .keyword(.override) }
}

private func redundantOverrideHasStaticOrClass(
    _ modifiers: DeclModifierListSyntax
) -> Bool {
    modifiers.contains {
        $0.name.tokenKind == .keyword(.static) || $0.name.tokenKind == .keyword(.class)
    }
}

/// Returns true when the body is a single statement that calls `super.<name>(args)`
/// with arguments that exactly mirror the function's parameters.
private func redundantOverrideForwardsToSuper(
    name: String,
    params: FunctionParameterListSyntax,
    body: CodeBlockSyntax
) -> Bool {
    guard body.statements.count == 1,
        let only = body.statements.first,
        let call = redundantOverrideExtractCall(from: only),
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
private func redundantOverrideExtractCall(
    from item: CodeBlockItemSyntax
) -> FunctionCallExprSyntax? {
    switch item.item {
    case .expr(let expr):
        return redundantOverrideUnwrapCall(expr)
    case .stmt(let stmt):
        if let returnStmt = stmt.as(ReturnStmtSyntax.self), let value = returnStmt.expression {
            return redundantOverrideUnwrapCall(value)
        }
        return nil
    default:
        return nil
    }
}

private func redundantOverrideUnwrapCall(
    _ expr: ExprSyntax
) -> FunctionCallExprSyntax? {
    if let call = expr.as(FunctionCallExprSyntax.self) {
        return call
    }
    if let awaitExpr = expr.as(AwaitExprSyntax.self) {
        return redundantOverrideUnwrapCall(awaitExpr.expression)
    }
    if let tryExpr = expr.as(TryExprSyntax.self) {
        // `try!` / `try?` may change behavior — bail out.
        guard tryExpr.questionOrExclamationMark == nil else { return nil }
        return redundantOverrideUnwrapCall(tryExpr.expression)
    }
    return nil
}

/// Returns an empty declaration whose only contribution is the original node's trivia.
private func redundantOverrideRemoved(_ node: some DeclSyntaxProtocol) -> DeclSyntax {
    let empty: DeclSyntax = ""
    return empty
        .with(\.leadingTrivia, node.leadingTrivia)
        .with(\.trailingTrivia, node.trailingTrivia)
}

extension Finding.Message {
    fileprivate static func removeRedundantOverride(name: String) -> Finding.Message {
        "remove redundant override of '\(name)'; it only forwards to super with identical arguments"
    }
}
