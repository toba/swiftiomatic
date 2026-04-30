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
final class NoForceTry: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .unsafety }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context`.
    final class State {
        var importsTesting = false
        var insideXCTestCase = false
        /// Saved `insideXCTestCase` per nested class.
        var classStack: [Bool] = []
        /// Whether the innermost enclosing function is a test function.
        var insideTestFunction = false
        /// Whether at least one `try!` has been converted in the current
        /// (innermost) function frame. Reset on each `pushFunction`.
        var convertedForceTry = false
        /// Saved `(insideTestFunction, convertedForceTry)` per nested function.
        var functionStack: [(Bool, Bool)] = []
        /// Number of function declarations currently on the stack — used so the
        /// `TryExpr` handler can tell apart "top-level try" from "try inside a
        /// non-test function".
        var functionDepth = 0
        /// Number of closure expressions currently on the stack. Legacy didn't
        /// recurse into closures; we mimic by bailing when this is non-zero.
        var closureDepth = 0
    }

    static func state(_ context: Context) -> State {
        context.noForceTryState
    }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        setImportsXCTest(context: context, sourceFile: node)
    }

    static func visitImport(_ node: ImportDeclSyntax, context: Context) {
        if node.path.first?.name.text == "Testing" {
            state(context).importsTesting = true
        }
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        let s = state(context)
        s.classStack.append(s.insideXCTestCase)
        if context.importsXCTest == .importsXCTest,
           let inheritance = node.inheritanceClause,
           inheritance.contains(named: "XCTestCase")
        {
            s.insideXCTestCase = true
        }
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        let s = state(context)
        if let was = s.classStack.popLast() { s.insideXCTestCase = was }
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        let s = state(context)
        s.functionStack.append((s.insideTestFunction, s.convertedForceTry))
        s.insideTestFunction = isTestFunction(node, state: s)
        s.convertedForceTry = false
        s.functionDepth += 1
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        let s = state(context)
        if let (wasInside, wasConverted) = s.functionStack.popLast() {
            s.insideTestFunction = wasInside
            s.convertedForceTry = wasConverted
        }
        s.functionDepth -= 1
    }

    static func willEnter(_: ClosureExprSyntax, context: Context) {
        state(context).closureDepth += 1
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        let s = state(context)
        if s.closureDepth > 0 { s.closureDepth -= 1 }
    }

    /// Apply the rule's `TryExpr` handler logic: diagnose / rewrite `try!` based
    /// on the current scope state. Returns the (possibly rewritten) expression
    /// — strip the `!` and convert to a regular `try` when inside a test
    /// function, leave the node alone otherwise.
    static func rewriteTryExpr(_ node: TryExprSyntax, context: Context) -> TryExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else { return node }
        let s = state(context)

        // Legacy didn't recurse into closures — preserve that opacity.
        if s.closureDepth > 0 { return node }

        if s.insideTestFunction {
            Self.diagnose(.replaceForceTry, on: node.tryKeyword, context: context)
            s.convertedForceTry = true

            let bangTrailingTrivia = node.questionOrExclamationMark?.trailingTrivia ?? .space
            return node
                .with(\.questionOrExclamationMark, nil)
                .with(\.tryKeyword, node.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
        }

        // Inside a non-test function — legacy never visited this. Match by
        // skipping the diagnostic. Top-level (functionDepth == 0) try! is
        // syntactically rare but legacy would have diagnosed it.
        if s.functionDepth == 0 {
            Self.diagnose(.doNotForceTry, on: node.tryKeyword, context: context)
        }
        return node
    }

    /// Post-process a function declaration — add a `throws` clause if any
    /// `try!` was converted in this function frame. Called from
    /// `rewriteFunctionDecl` AFTER children are visited but BEFORE `didExit`
    /// fires (which restores the parent frame).
    static func afterFunctionDecl(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> FunctionDeclSyntax {
        let s = state(context)
        guard s.insideTestFunction, s.convertedForceTry else { return node }
        if node.signature.effectSpecifiers?.throwsClause != nil { return node }
        return node.addingThrowsClause()
    }

    /// Returns true when the function declaration is a Swift Testing `@Test`
    /// or an `XCTestCase` `test*()` method.
    private static func isTestFunction(_ node: FunctionDeclSyntax, state: State) -> Bool {
        if state.importsTesting, node.hasAttribute("Test", inModule: "Testing") { return true }
        if state.insideXCTestCase {
            let name = node.name.text
            return name.hasPrefix("test")
                && node.signature.parameterClause.parameters.isEmpty
                && node.signature.returnClause == nil
        }
        return false
    }
}

fileprivate extension Finding.Message {
    static let doNotForceTry: Finding.Message = "do not use force try"
    static let replaceForceTry: Finding.Message =
        "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
