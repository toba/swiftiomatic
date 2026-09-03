import SwiftSyntax

/// Force-try ( `try!` ) is forbidden.
///
/// In test functions, `try!` is auto-fixed to `try` and `throws` is added to the function signature
/// if needed.
///
/// In non-test code, `try!` is diagnosed but not rewritten.
///
/// Test functions are:
/// - Functions annotated with `@Test` (Swift Testing)
/// - Functions named `test*()` with no parameters inside `XCTestCase` subclasses
///
/// A `try!` inside a closure or a nested function is reported but never rewritten, because the
/// enclosing test function's `throws` does not propagate into those scopes.
///
/// Lint: A warning is raised for each `try!` , wherever it sits.
///
/// Rewrite: In test functions, `try!` is replaced with `try` and `throws` is added.
final class NoForceTry: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    static let rewriteOrder = 1110

    override static var group: ConfigurationGroup? { .unsafety }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var testContext = TestContextTracker()
        /// Saved `insideXCTestCase` per nested class.
        var classStack: [Bool] = []
        /// Whether the innermost enclosing function is a test function.
        var insideTestFunction = false
        /// Whether at least one `try!` has been converted in the current (innermost) function
        /// frame. Reset on each `pushFunction` .
        var convertedForceTry = false
        /// Saved `(insideTestFunction, convertedForceTry)` per nested function.
        var functionStack: [(Bool, Bool)] = []
        /// Number of closure expressions currently on the stack. A non-zero depth blocks the
        /// rewrite, because `try` cannot propagate out of a closure.
        var closureDepth = 0
    }

    static func state(_ context: Context) -> State { context.noForceTryState }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        state(context).testContext.visitSourceFile(node, context: context)
    }

    /// Record an `import Testing` so later type-decl visits know the macro is in scope.
    ///
    /// This runs after the children are visited, because `UseSwiftTestingNotXCTest` rewrites
    /// `import XCTest` to `import Testing` first and the flag has to read the rewritten path.
    static func transform(
        _ node: ImportDeclSyntax,
        original _: ImportDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ImportDeclSyntax {
        state(context).testContext.visitImport(node)
        return node
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        let s = state(context)
        s.classStack.append(s.testContext.pushClass(node, context: context))
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        let s = state(context)
        if let was = s.classStack.popLast() { s.testContext.popClass(was: was) }
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        let s = state(context)
        s.functionStack.append((s.insideTestFunction, s.convertedForceTry))
        s.insideTestFunction = s.testContext.isTestFunction(node)
        s.convertedForceTry = false
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        let s = state(context)

        if let (wasInside, wasConverted) = s.functionStack.popLast() {
            s.insideTestFunction = wasInside
            s.convertedForceTry = wasConverted
        }
    }

    static func willEnter(_: ClosureExprSyntax, context: Context) {
        state(context).closureDepth += 1
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        let s = state(context)
        if s.closureDepth > 0 { s.closureDepth -= 1 }
    }

    /// Apply the rule's `TryExpr` handler logic: diagnose / rewrite `try!` based on the current
    /// scope state. Returns the (possibly rewritten) expression — strip the `!` and convert to a
    /// regular `try` when inside a test function, leave the node alone otherwise.
    static func transform(
        _ node: TryExprSyntax,
        original: TryExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> TryExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else { return node }
        let s = state(context)

        // anchor on the original tree; the rewritten node detaches once a child changes
        let anchor = original.tryKeyword

        // a closure body cannot propagate try to the enclosing test function, so report and stop
        if s.closureDepth > 0 {
            Self.diagnose(.doNotForceTry, on: anchor, context: context)
            return node
        }

        if s.insideTestFunction {
            Self.diagnose(.replaceForceTry, on: anchor, context: context)
            s.convertedForceTry = true

            let bangTrailingTrivia = node.questionOrExclamationMark?.trailingTrivia ?? .space
            return node
                .with(\.questionOrExclamationMark, nil)
                .with(\.tryKeyword, node.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
        }

        Self.diagnose(.doNotForceTry, on: anchor, context: context)
        return node
    }

    /// Post-process a function declaration — add a `throws` clause if any `try!` was converted in
    /// this function frame. Called from `rewriteFunctionDecl` AFTER children are visited but BEFORE
    /// `didExit` fires (which restores the parent frame).
    static func transform(
        _ node: FunctionDeclSyntax,
        original _: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> FunctionDeclSyntax {
        let s = state(context)
        guard s.insideTestFunction, s.convertedForceTry else { return node }
        return node.signature.effectSpecifiers?.throwsClause != nil
            ? node
            : node.addingThrowsClause()
    }
}

fileprivate extension Finding.Message {
    static let doNotForceTry: Finding.Message = "do not use force try"
    static let replaceForceTry: Finding.Message =
        "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
