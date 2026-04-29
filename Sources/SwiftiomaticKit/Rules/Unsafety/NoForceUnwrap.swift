import SwiftSyntax

/// Force-unwraps are strongly discouraged and must be documented.
///
/// In test functions, force unwraps are auto-fixed:
/// - `foo!` becomes `try XCTUnwrap(foo)` (XCTest) or `try #require(foo)` (Swift Testing)
/// - `foo as! Bar` becomes `try XCTUnwrap(foo as? Bar)` or `try #require(foo as? Bar)`
/// - `throws` is added to the function signature if needed
///
/// In non-test code, force unwraps are diagnosed but not rewritten.
///
/// Test functions are:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// Force unwraps in closures, nested functions, and string interpolation are left alone because
/// `try` cannot propagate out of those scopes.
///
/// Lint: A warning is raised for each force unwrap.
///
/// Rewrite: In test functions, force unwraps are replaced with XCTUnwrap/#require.
final class NoForceUnwrap: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .unsafety }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        noForceUnwrapVisitSourceFile(node, context: context)
    }

    static func willEnter(_ node: ImportDeclSyntax, context: Context) {
        noForceUnwrapVisitImport(node, context: context)
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        noForceUnwrapPushClass(node, context: context)
    }
    static func didExit(_: ClassDeclSyntax, context: Context) {
        noForceUnwrapPopClass(context: context)
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        noForceUnwrapPushFunction(node, context: context)
    }
    static func didExit(_: FunctionDeclSyntax, context: Context) {
        noForceUnwrapPopFunction(context: context)
    }

    static func willEnter(_: ClosureExprSyntax, context: Context) {
        noForceUnwrapPushClosure(context: context)
    }
    static func didExit(_: ClosureExprSyntax, context: Context) {
        noForceUnwrapPopClosure(context: context)
    }

    static func willEnter(_: StringLiteralExprSyntax, context: Context) {
        noForceUnwrapPushStringLiteral(context: context)
    }
    static func didExit(_: StringLiteralExprSyntax, context: Context) {
        noForceUnwrapPopStringLiteral(context: context)
    }

    static func willEnter(_ node: MemberAccessExprSyntax, context: Context) {
        noForceUnwrapState(context).nonTestChainParentDepth += 1
        noForceUnwrapPushMemberAccess(node, context: context)
    }
    static func didExit(_ node: MemberAccessExprSyntax, context: Context) {
        noForceUnwrapPopMemberAccess(node, context: context)
        let state = noForceUnwrapState(context)
        if state.nonTestChainParentDepth > 0 { state.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: FunctionCallExprSyntax, context: Context) {
        noForceUnwrapState(context).nonTestChainParentDepth += 1
        noForceUnwrapPushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: FunctionCallExprSyntax, context: Context) {
        noForceUnwrapPopChainNode(Syntax(node), context: context)
        let state = noForceUnwrapState(context)
        if state.nonTestChainParentDepth > 0 { state.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: SubscriptCallExprSyntax, context: Context) {
        noForceUnwrapState(context).nonTestChainParentDepth += 1
        noForceUnwrapPushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: SubscriptCallExprSyntax, context: Context) {
        noForceUnwrapPopChainNode(Syntax(node), context: context)
        let state = noForceUnwrapState(context)
        if state.nonTestChainParentDepth > 0 { state.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: ForceUnwrapExprSyntax, context: Context) {
        noForceUnwrapPushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: ForceUnwrapExprSyntax, context: Context) {
        noForceUnwrapPopChainNode(Syntax(node), context: context)
    }

    static func willEnter(_ node: AsExprSyntax, context: Context) {
        noForceUnwrapPushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: AsExprSyntax, context: Context) {
        noForceUnwrapPopChainNode(Syntax(node), context: context)
    }
}
