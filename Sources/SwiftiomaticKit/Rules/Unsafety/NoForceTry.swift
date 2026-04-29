import SwiftSyntax

/// Force-try (`try!`) is forbidden.
///
/// In test functions, `try!` is auto-fixed to `try` and `throws` is added to the function
/// signature if needed.
///
/// In non-test code, `try!` is diagnosed but not rewritten.
///
/// Test functions are:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// `try!` inside closures or nested functions is left alone because the enclosing test function's
/// `throws` does not propagate into those scopes.
///
/// Lint: A warning is raised for each `try!`.
///
/// Rewrite: In test functions, `try!` is replaced with `try` and `throws` is added.
final class NoForceTry: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .unsafety }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        noForceTryVisitSourceFile(node, context: context)
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        noForceTryPushClass(node, context: context)
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        noForceTryPopClass(context: context)
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        noForceTryPushFunction(node, context: context)
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        noForceTryPopFunction(context: context)
    }

    static func willEnter(_: ClosureExprSyntax, context: Context) {
        noForceTryPushClosure(context: context)
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        noForceTryPopClosure(context: context)
    }
}

fileprivate extension Finding.Message {
    static let doNotForceTry: Finding.Message = "do not use force try"
    static let replaceForceTry: Finding.Message =
        "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
