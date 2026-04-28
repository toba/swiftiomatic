import SwiftSyntax

/// Shared helpers and state class for the inlined `NoForceUnwrap` rule.
///
/// Mirrors the `NoForceTry` port (`NoForceTryHelpers.swift`) but adds chain-top
/// wrapping logic: in test functions, a `try!`-style force-unwrap inside a
/// chain (`foo!.bar.baz()`) is replaced with `try XCTUnwrap`/`try #require`
/// at the chain top. The flag that signals "wrap me at the top" is propagated
/// through the rewriting chain via the state's `chainNeedsWrapping` field plus
/// per-chain-node save stacks pushed by `willEnter`.
///
/// Legacy implementation: `Sources/SwiftiomaticKit/Rules/Unsafety/NoForceUnwrap.swift`.

final class NoForceUnwrapState {
    var importsTesting = false
    var insideXCTestCase = false
    /// Saved `insideXCTestCase` per nested class.
    var classStack: [Bool] = []
    /// Whether the innermost enclosing function is a test function.
    var insideTestFunction = false
    /// Whether at least one force unwrap was wrapped (`XCTUnwrap`/`#require`)
    /// in the current function frame, requiring `throws` injection.
    var addedTryExpression = false
    /// Saved `(insideTestFunction, addedTryExpression)` per nested function.
    var functionStack: [(Bool, Bool)] = []
    /// Number of function declarations currently on the stack.
    var functionDepth = 0
    /// Number of closure expressions currently on the stack. Legacy didn't
    /// recurse into closures inside test functions (`try` can't propagate);
    /// we mimic by bailing in `ForceUnwrap`/`AsExpr` handlers when this is
    /// non-zero.
    var closureDepth = 0
    /// Number of string-interpolation literals currently on the stack. Same
    /// rationale as `closureDepth`.
    var stringInterpolationDepth = 0

    /// Flag set by an inner `ForceUnwrap`/`AsExpr` to signal that the chain
    /// top needs wrapping. Saved/restored at each chain-eligible parent's
    /// `willEnter`/`rewrite` boundary.
    var chainNeedsWrapping = false
    /// Saved `chainNeedsWrapping` values per chain-eligible enclosing parent.
    var chainSaveStack: [Bool] = []
    /// Whether each chain-eligible parent was the chain top in the original
    /// (pre-recursion) tree. Captured by `willEnter` and consumed by
    /// `rewrite<...>`.
    var chainTopStack: [Bool] = []
    /// Pre-classified context (`wrap`/`noWrap`/`propagate`) per chain-top
    /// node, captured by `willEnter` since the post-recursion node lacks the
    /// original parent links.
    var chainContextStack: [NoForceUnwrapChainTopContext] = []
    /// MemberAccess only: whether the original base was `(force-cast)` —
    /// determines if we need to add an optional-chain on the base.
    var memberHadForceCastStack: [Bool] = []
}

enum NoForceUnwrapChainTopContext { case wrap, noWrap, propagate }

func noForceUnwrapState(_ context: Context) -> NoForceUnwrapState {
    context.ruleState(for: NoForceUnwrap.self) { NoForceUnwrapState() }
}

// MARK: - File-level pre-scan

func noForceUnwrapVisitImport(_ node: ImportDeclSyntax, context: Context) {
    if node.path.first?.name.text == "Testing" {
        noForceUnwrapState(context).importsTesting = true
    }
}

func noForceUnwrapVisitSourceFile(_ node: SourceFileSyntax, context: Context) {
    setImportsXCTest(context: context, sourceFile: node)
}

// MARK: - Class scope

func noForceUnwrapPushClass(_ node: ClassDeclSyntax, context: Context) {
    let state = noForceUnwrapState(context)
    state.classStack.append(state.insideXCTestCase)
    if context.importsXCTest == .importsXCTest,
       let inheritance = node.inheritanceClause,
       inheritance.contains(named: "XCTestCase")
    {
        state.insideXCTestCase = true
    }
}

func noForceUnwrapPopClass(context: Context) {
    let state = noForceUnwrapState(context)
    if let was = state.classStack.popLast() { state.insideXCTestCase = was }
}

// MARK: - Function scope

private func noForceUnwrapIsTestFunction(
    _ node: FunctionDeclSyntax,
    state: NoForceUnwrapState
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

func noForceUnwrapPushFunction(_ node: FunctionDeclSyntax, context: Context) {
    let state = noForceUnwrapState(context)
    state.functionStack.append((state.insideTestFunction, state.addedTryExpression))
    state.insideTestFunction = noForceUnwrapIsTestFunction(node, state: state)
    state.addedTryExpression = false
    state.functionDepth += 1
}

func noForceUnwrapPopFunction(context: Context) {
    let state = noForceUnwrapState(context)
    if let (wasInside, wasAdded) = state.functionStack.popLast() {
        state.insideTestFunction = wasInside
        state.addedTryExpression = wasAdded
    }
    state.functionDepth -= 1
}

// MARK: - Closure / string-interpolation scope

func noForceUnwrapPushClosure(context: Context) {
    noForceUnwrapState(context).closureDepth += 1
}

func noForceUnwrapPopClosure(context: Context) {
    let state = noForceUnwrapState(context)
    if state.closureDepth > 0 { state.closureDepth -= 1 }
}

func noForceUnwrapPushStringLiteral(context: Context) {
    noForceUnwrapState(context).stringInterpolationDepth += 1
}

func noForceUnwrapPopStringLiteral(context: Context) {
    let state = noForceUnwrapState(context)
    if state.stringInterpolationDepth > 0 { state.stringInterpolationDepth -= 1 }
}

// MARK: - Chain-eligible parent willEnter / didExit

/// Push state at a chain-eligible parent (MemberAccess/FunctionCall/
/// SubscriptCall/ForceUnwrap/AsExpr): saves the current `chainNeedsWrapping`,
/// resets it to false so children's signals are isolated, and captures
/// chain-top status + classification from the pre-recursion node.
func noForceUnwrapPushChainNode(_ originalNode: Syntax, context: Context) {
    let state = noForceUnwrapState(context)
    state.chainSaveStack.append(state.chainNeedsWrapping)
    state.chainNeedsWrapping = false

    let isTop = noForceUnwrapIsChainTop(originalNode)
    state.chainTopStack.append(isTop)
    state.chainContextStack.append(
        isTop ? noForceUnwrapClassifyChainTopContext(originalNode) : .propagate
    )

    // Emit findings here (during willEnter, with original positions). The
    // legacy rule diagnoses/skips inside its `visit(_:)` BEFORE recursing —
    // we mirror that timing so location info reflects the original tree.
    if let force = originalNode.as(ForceUnwrapExprSyntax.self) {
        noForceUnwrapDiagnoseForceUnwrap(force, isTop: isTop, context: context)
    } else if let asExpr = originalNode.as(AsExprSyntax.self),
              asExpr.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        noForceUnwrapDiagnoseAsExpr(asExpr, isTop: isTop, context: context)
    }
}

private func noForceUnwrapDiagnoseForceUnwrap(
    _ node: ForceUnwrapExprSyntax,
    isTop: Bool,
    context: Context
) {
    let state = noForceUnwrapState(context)

    // Skip if parent is `try!` (handled by NoForceTry).
    if let parentTry = node.parent?.as(TryExprSyntax.self),
       parentTry.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        return
    }

    if state.insideTestFunction {
        if state.closureDepth > 0 || state.stringInterpolationDepth > 0 { return }
        NoForceUnwrap.diagnose(.replaceForceUnwrap, on: node.exclamationMark, context: context)
        return
    }

    // Non-test code: legacy diagnoses without recursing, so only the chain top
    // emits a finding.
    guard isTop else { return }
    NoForceUnwrap.diagnose(
        .doNotForceUnwrap(name: node.expression.trimmedDescription),
        on: node, context: context
    )
}

private func noForceUnwrapDiagnoseAsExpr(
    _ node: AsExprSyntax,
    isTop: Bool,
    context: Context
) {
    let state = noForceUnwrapState(context)
    if state.insideTestFunction {
        if state.closureDepth > 0 || state.stringInterpolationDepth > 0 { return }
        NoForceUnwrap.diagnose(.replaceForceCast, on: node.asKeyword, context: context)
        return
    }
    guard isTop else { return }
    NoForceUnwrap.diagnose(
        .doNotForceCast(name: node.type.trimmedDescription),
        on: node, context: context
    )
}

/// Restore the chain state stacks. Called from `didExit`. Note: the chain
/// rewrite functions read (without popping) via `.last`; this pop runs after
/// the rewrite. The propagation of `chainNeedsWrapping` happens here.
func noForceUnwrapPopChainNode(_ originalNode: Syntax, context: Context) {
    let state = noForceUnwrapState(context)
    assert(
        !state.chainSaveStack.isEmpty
            && !state.chainTopStack.isEmpty
            && !state.chainContextStack.isEmpty,
        "willEnter/didExit imbalance in NoForceUnwrap chain stacks"
    )
    let saved = state.chainSaveStack.popLast() ?? false
    let isTop = state.chainTopStack.popLast() ?? false
    _ = state.chainContextStack.popLast()
    _ = originalNode

    if isTop {
        state.chainNeedsWrapping = saved
    } else {
        state.chainNeedsWrapping = saved || state.chainNeedsWrapping
    }
}

func noForceUnwrapPushMemberAccess(_ node: MemberAccessExprSyntax, context: Context) {
    let state = noForceUnwrapState(context)
    let hadForceCast: Bool
    if let base = node.base,
       let tupleExpr = base.as(TupleExprSyntax.self),
       tupleExpr.elements.count == 1,
       let singleElement = tupleExpr.elements.first,
       noForceUnwrapFindForceCast(in: singleElement.expression) != nil
    {
        hadForceCast = true
    } else {
        hadForceCast = false
    }
    state.memberHadForceCastStack.append(hadForceCast)
    noForceUnwrapPushChainNode(Syntax(node), context: context)
}

func noForceUnwrapPopMemberAccess(_ node: MemberAccessExprSyntax, context: Context) {
    let state = noForceUnwrapState(context)
    _ = state.memberHadForceCastStack.popLast()
    noForceUnwrapPopChainNode(Syntax(node), context: context)
}

// MARK: - Chain topology

/// Returns true if the node is the top of an expression chain.
func noForceUnwrapIsChainTop(_ node: Syntax) -> Bool {
    guard let parent = node.parent else { return true }
    if parent.is(MemberAccessExprSyntax.self) { return false }
    if parent.is(ForceUnwrapExprSyntax.self) { return false }
    if parent.is(OptionalChainingExprSyntax.self) { return false }

    if let funcCall = parent.as(FunctionCallExprSyntax.self),
       funcCall.calledExpression.id == node.id
    {
        return false
    }
    if let subscriptCall = parent.as(SubscriptCallExprSyntax.self),
       subscriptCall.calledExpression.id == node.id
    {
        return false
    }
    return true
}

func noForceUnwrapClassifyChainTopContext(_ node: Syntax) -> NoForceUnwrapChainTopContext {
    guard let parent = node.parent else { return .wrap }

    if parent.is(TupleExprSyntax.self) { return .propagate }

    if let labeledExpr = parent.as(LabeledExprSyntax.self) {
        return noForceUnwrapClassifyArgContext(labeledExpr)
    }

    if let infixExpr = parent.as(InfixOperatorExprSyntax.self) {
        return noForceUnwrapClassifyInfixTopContext(infixExpr, chainExpr: node)
    }

    if parent.is(CodeBlockItemSyntax.self) { return .noWrap }
    if parent.is(InitializerClauseSyntax.self) { return .wrap }
    if parent.is(ReturnStmtSyntax.self) { return .wrap }
    if parent.is(ConditionElementSyntax.self) { return .wrap }
    return .wrap
}

private func noForceUnwrapClassifyArgContext(
    _ labeledExpr: LabeledExprSyntax
) -> NoForceUnwrapChainTopContext {
    guard let argList = labeledExpr.parent?.as(LabeledExprListSyntax.self),
          let funcCall = argList.parent?.as(FunctionCallExprSyntax.self)
    else {
        return .wrap
    }

    let funcName = funcCall.calledExpression.trimmedDescription
    if funcName == "XCTAssertNil" { return .noWrap }
    if funcName == "XCTAssertEqual", argList.count == 2 { return .noWrap }
    return .wrap
}

private func noForceUnwrapClassifyInfixTopContext(
    _ infixExpr: InfixOperatorExprSyntax,
    chainExpr: Syntax
) -> NoForceUnwrapChainTopContext {
    let op = infixExpr.operator
    if op.is(AssignmentExprSyntax.self) {
        if infixExpr.leftOperand.id == chainExpr.id { return .noWrap }
        return .wrap
    }
    if let binOp = op.as(BinaryOperatorExprSyntax.self), binOp.operator.text == "==" {
        return .noWrap
    }
    return .wrap
}

func noForceUnwrapFindForceCast(in expr: ExprSyntax) -> AsExprSyntax? {
    if let asExpr = expr.as(AsExprSyntax.self),
       asExpr.questionOrExclamationMark?.tokenKind == .exclamationMark
    {
        return asExpr
    }
    for child in expr.children(viewMode: .sourceAccurate) {
        if let childExpr = child.as(ExprSyntax.self),
           let found = noForceUnwrapFindForceCast(in: childExpr)
        {
            return found
        }
    }
    return nil
}

// MARK: - Rewrite handlers

/// Apply the `ForceUnwrapExpr` rewrite. Diagnostics are emitted from
/// `willEnter` (with original tree positions) — this function only does the
/// rewrite based on accumulated state.
func noForceUnwrapRewriteForceUnwrap(
    _ node: ForceUnwrapExprSyntax,
    context: Context
) -> ExprSyntax {
    let state = noForceUnwrapState(context)

    guard state.insideTestFunction else { return ExprSyntax(node) }
    if state.closureDepth > 0 || state.stringInterpolationDepth > 0 {
        return ExprSyntax(node)
    }

    let isTop = state.chainTopStack.last ?? true
    let chainContext = state.chainContextStack.last ?? .wrap

    if isTop {
        switch chainContext {
            case .wrap:
                state.addedTryExpression = true
                return noForceUnwrapWrapInUnwrap(
                    node.expression,
                    trailingTrivia: node.exclamationMark.trailingTrivia,
                    state: state
                )
            case .noWrap:
                return ExprSyntax(
                    OptionalChainingExprSyntax(
                        expression: node.expression,
                        questionMark: .postfixQuestionMarkToken(
                            leadingTrivia: node.exclamationMark.leadingTrivia,
                            trailingTrivia: node.exclamationMark.trailingTrivia
                        )
                    ))
            case .propagate:
                state.chainNeedsWrapping = true
                return ExprSyntax(
                    OptionalChainingExprSyntax(
                        expression: node.expression,
                        questionMark: .postfixQuestionMarkToken(
                            leadingTrivia: node.exclamationMark.leadingTrivia,
                            trailingTrivia: node.exclamationMark.trailingTrivia
                        )
                    ))
        }
    }

    // Not chain top: convert to optional chain, signal upward.
    state.chainNeedsWrapping = true
    return ExprSyntax(
        OptionalChainingExprSyntax(
            expression: node.expression,
            questionMark: .postfixQuestionMarkToken(
                leadingTrivia: node.exclamationMark.leadingTrivia,
                trailingTrivia: node.exclamationMark.trailingTrivia
            )
        ))
}

/// Apply the `AsExpr` rewrite for `as!` force casts (called only when the
/// node is `as!`). Diagnostics are emitted from `willEnter`.
func noForceUnwrapRewriteAsExpr(
    _ node: AsExprSyntax,
    context: Context
) -> ExprSyntax {
    guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else {
        return ExprSyntax(node)
    }

    let state = noForceUnwrapState(context)
    guard state.insideTestFunction else { return ExprSyntax(node) }
    if state.closureDepth > 0 || state.stringInterpolationDepth > 0 {
        return ExprSyntax(node)
    }

    var result = node
    result.questionOrExclamationMark = .postfixQuestionMarkToken(
        leadingTrivia: node.questionOrExclamationMark!.leadingTrivia,
        trailingTrivia: node.questionOrExclamationMark!.trailingTrivia
    )

    let isTop = state.chainTopStack.last ?? true
    let chainContext = state.chainContextStack.last ?? .wrap

    if isTop {
        switch chainContext {
            case .wrap:
                state.addedTryExpression = true
                return noForceUnwrapWrapInUnwrap(
                    ExprSyntax(result),
                    trailingTrivia: result.trailingTrivia,
                    state: state
                )
            case .noWrap:
                return ExprSyntax(result)
            case .propagate:
                state.chainNeedsWrapping = true
                return ExprSyntax(result)
        }
    }

    state.chainNeedsWrapping = true
    return ExprSyntax(result)
}

/// Apply the `MemberAccessExpr` chain-top wrapping. Called after children
/// have been visited.
func noForceUnwrapRewriteMemberAccess(
    _ node: MemberAccessExprSyntax,
    context: Context
) -> ExprSyntax {
    let state = noForceUnwrapState(context)
    guard state.insideTestFunction,
          state.closureDepth == 0,
          state.stringInterpolationDepth == 0
    else {
        return ExprSyntax(node)
    }

    let childChainNeedsWrapping = state.chainNeedsWrapping
    let isTop = state.chainTopStack.last ?? false
    let originalHadForceCast = state.memberHadForceCastStack.last ?? false

    if originalHadForceCast, let base = node.base {
        let optionalBase = OptionalChainingExprSyntax(
            expression: base,
            questionMark: .postfixQuestionMarkToken()
        )
        var result = node
        result.base = ExprSyntax(optionalBase)

        if isTop, childChainNeedsWrapping {
            return noForceUnwrapWrapIfNeeded(
                ExprSyntax(result),
                state: state
            )
        }
        return ExprSyntax(result)
    }

    if isTop, childChainNeedsWrapping {
        return noForceUnwrapWrapIfNeeded(ExprSyntax(node), state: state)
    }

    return ExprSyntax(node)
}

func noForceUnwrapRewriteFunctionCallTop(
    _ node: FunctionCallExprSyntax,
    context: Context
) -> ExprSyntax {
    let state = noForceUnwrapState(context)
    guard state.insideTestFunction,
          state.closureDepth == 0,
          state.stringInterpolationDepth == 0
    else {
        return ExprSyntax(node)
    }

    let childChainNeedsWrapping = state.chainNeedsWrapping
    let isTop = state.chainTopStack.last ?? false
    if isTop, childChainNeedsWrapping {
        return noForceUnwrapWrapIfNeeded(ExprSyntax(node), state: state)
    }
    return ExprSyntax(node)
}

func noForceUnwrapRewriteSubscriptCallTop(
    _ node: SubscriptCallExprSyntax,
    context: Context
) -> ExprSyntax {
    let state = noForceUnwrapState(context)
    guard state.insideTestFunction,
          state.closureDepth == 0,
          state.stringInterpolationDepth == 0
    else {
        return ExprSyntax(node)
    }

    let childChainNeedsWrapping = state.chainNeedsWrapping
    let isTop = state.chainTopStack.last ?? false
    if isTop, childChainNeedsWrapping {
        return noForceUnwrapWrapIfNeeded(ExprSyntax(node), state: state)
    }
    return ExprSyntax(node)
}

// MARK: - Wrap helpers

func noForceUnwrapWrapIfNeeded(
    _ expr: ExprSyntax,
    state: NoForceUnwrapState
) -> ExprSyntax {
    let chainContext = state.chainContextStack.last ?? .wrap
    switch chainContext {
        case .wrap:
            state.addedTryExpression = true
            state.chainNeedsWrapping = false
            return noForceUnwrapWrapInUnwrap(
                expr, trailingTrivia: expr.trailingTrivia, state: state
            )
        case .noWrap:
            state.chainNeedsWrapping = false
            return expr
        case .propagate:
            return expr
    }
}

func noForceUnwrapWrapInUnwrap(
    _ expr: ExprSyntax,
    trailingTrivia: Trivia = [],
    state: NoForceUnwrapState
) -> ExprSyntax {
    let innerExpr = expr.trimmed
    let callExpr: ExprSyntax = state.importsTesting
        ? ExprSyntax(
            MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("require"),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([
                    LabeledExprSyntax(expression: innerExpr)
                ]),
                rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
            ))
        : ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier("XCTUnwrap"))
                ),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax([
                    LabeledExprSyntax(expression: innerExpr)
                ]),
                rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
            ))

    return ExprSyntax(
        TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: callExpr
        ))
}

// MARK: - FunctionDecl post-process

/// Add a `throws` clause if any force unwrap was wrapped inside the function
/// frame. Called from `rewriteFunctionDecl` AFTER children visited but BEFORE
/// `didExit` (which restores parent frame).
func noForceUnwrapAfterFunctionDecl(
    _ node: FunctionDeclSyntax,
    context: Context
) -> FunctionDeclSyntax {
    let state = noForceUnwrapState(context)
    guard state.insideTestFunction, state.addedTryExpression else { return node }
    if node.signature.effectSpecifiers?.throwsClause != nil { return node }
    return node.addingThrowsClause()
}

extension Finding.Message {
    fileprivate static func doNotForceUnwrap(name: String) -> Finding.Message {
        "do not force unwrap '\(name)'"
    }
    fileprivate static func doNotForceCast(name: String) -> Finding.Message {
        "do not force cast to '\(name)'"
    }
    fileprivate static let replaceForceUnwrap: Finding.Message =
        "replace force unwrap in test with 'XCTUnwrap' or '#require'"
    fileprivate static let replaceForceCast: Finding.Message =
        "replace force cast in test with optional cast"
}
