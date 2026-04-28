import SwiftSyntax

/// Shared helpers and state class for the inlined `NoForceTry` rule. The
/// legacy rule uses instance state (a `TestContextTracker`,
/// `insideTestFunction`, `convertedForceTry`) which we migrate to a
/// reference-typed `State` cached on `Context.ruleState(for:)`.
///
/// In the legacy pipeline the rule's `visit(_ FunctionDecl)` short-circuits
/// for non-test functions — children are never traversed. The compact
/// pipeline always recurses, so we keep `functionDepth` and `closureDepth`
/// counters and bail out of the `TryExpr` handler when the legacy walk
/// would not have reached it.
///
/// See `Sources/SwiftiomaticKit/Rules/Unsafety/NoForceTry.swift` for the
/// legacy implementation.

final class NoForceTryState {
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

func noForceTryState(_ context: Context) -> NoForceTryState {
    context.ruleState(for: NoForceTry.self) { NoForceTryState() }
}

func noForceTryVisitImport(_ node: ImportDeclSyntax, context: Context) {
    if node.path.first?.name.text == "Testing" {
        noForceTryState(context).importsTesting = true
    }
}

func noForceTryVisitSourceFile(_ node: SourceFileSyntax, context: Context) {
    setImportsXCTest(context: context, sourceFile: node)
}

func noForceTryPushClass(_ node: ClassDeclSyntax, context: Context) {
    let state = noForceTryState(context)
    state.classStack.append(state.insideXCTestCase)
    if context.importsXCTest == .importsXCTest,
       let inheritance = node.inheritanceClause,
       inheritance.contains(named: "XCTestCase")
    {
        state.insideXCTestCase = true
    }
}

func noForceTryPopClass(context: Context) {
    let state = noForceTryState(context)
    if let was = state.classStack.popLast() { state.insideXCTestCase = was }
}

/// Returns true when the function declaration is a Swift Testing `@Test`
/// or an `XCTestCase` `test*()` method.
private func noForceTryIsTestFunction(
    _ node: FunctionDeclSyntax,
    state: NoForceTryState
) -> Bool {
    if state.importsTesting, node.hasAttribute("Test", inModule: "Testing") { return true }
    if state.insideXCTestCase {
        let name = node.name.text
        return name.hasPrefix("test")
            && node.signature.parameterClause.parameters.isEmpty
            && node.signature.returnClause == nil
    }
    return false
}

func noForceTryPushFunction(_ node: FunctionDeclSyntax, context: Context) {
    let state = noForceTryState(context)
    state.functionStack.append((state.insideTestFunction, state.convertedForceTry))
    state.insideTestFunction = noForceTryIsTestFunction(node, state: state)
    state.convertedForceTry = false
    state.functionDepth += 1
}

func noForceTryPopFunction(context: Context) {
    let state = noForceTryState(context)
    if let (wasInside, wasConverted) = state.functionStack.popLast() {
        state.insideTestFunction = wasInside
        state.convertedForceTry = wasConverted
    }
    state.functionDepth -= 1
}

func noForceTryPushClosure(context: Context) {
    noForceTryState(context).closureDepth += 1
}

func noForceTryPopClosure(context: Context) {
    let state = noForceTryState(context)
    if state.closureDepth > 0 { state.closureDepth -= 1 }
}

/// Apply the rule's `TryExpr` handler logic: diagnose / rewrite `try!` based
/// on the current scope state. Returns the (possibly rewritten) expression
/// — strip the `!` and convert to a regular `try` when inside a test
/// function, leave the node alone otherwise.
func noForceTryRewriteTryExpr(
    _ node: TryExprSyntax,
    context: Context
) -> TryExprSyntax {
    guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else { return node }
    let state = noForceTryState(context)

    // Legacy didn't recurse into closures — preserve that opacity.
    if state.closureDepth > 0 { return node }

    if state.insideTestFunction {
        NoForceTry.diagnose(.replaceForceTry, on: node.tryKeyword, context: context)
        state.convertedForceTry = true

        let bangTrailingTrivia = node.questionOrExclamationMark?.trailingTrivia ?? .space
        return node
            .with(\.questionOrExclamationMark, nil)
            .with(\.tryKeyword, node.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
    }

    // Inside a non-test function — legacy never visited this. Match by
    // skipping the diagnostic. Top-level (functionDepth == 0) try! is
    // syntactically rare but legacy would have diagnosed it.
    if state.functionDepth == 0 {
        NoForceTry.diagnose(.doNotForceTry, on: node.tryKeyword, context: context)
    }
    return node
}

/// Post-process a function declaration — add a `throws` clause if any
/// `try!` was converted in this function frame. Called from
/// `rewriteFunctionDecl` AFTER children are visited but BEFORE `didExit`
/// fires (which restores the parent frame).
func noForceTryAfterFunctionDecl(
    _ node: FunctionDeclSyntax,
    context: Context
) -> FunctionDeclSyntax {
    let state = noForceTryState(context)
    guard state.insideTestFunction, state.convertedForceTry else { return node }
    if node.signature.effectSpecifiers?.throwsClause != nil { return node }
    return node.addingThrowsClause()
}

extension Finding.Message {
    fileprivate static let doNotForceTry: Finding.Message = "do not use force try"
    fileprivate static let replaceForceTry: Finding.Message =
        "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
