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

    // MARK: - Per-pass state

    final class State {
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
        var chainContextStack: [ChainTopContext] = []
        /// MemberAccess only: whether the original base was `(force-cast)` —
        /// determines if we need to add an optional-chain on the base.
        var memberHadForceCastStack: [Bool] = []
        /// Number of chain-eligible parents (FunctionCall, MemberAccess,
        /// SubscriptCall) currently on the stack. Used to suppress diagnostics
        /// in non-test code: legacy short-circuits recursion at these nodes (see
        /// `NoForceUnwrap.visit(_ FunctionCallExprSyntax)` etc.), so descendants
        /// never reach the ForceUnwrap visitor. We mimic by skipping diagnose
        /// when `nonTestChainParentDepth > 0` and `!insideTestFunction`.
        var nonTestChainParentDepth = 0
    }

    enum ChainTopContext { case wrap, noWrap, propagate }

    static func state(_ context: Context) -> State {
        context.noForceUnwrapState
    }

    // MARK: - Compact-pipeline scope hooks

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        visitSourceFile(node, context: context)
    }

    static func willEnter(_ node: ImportDeclSyntax, context: Context) {
        visitImport(node, context: context)
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        pushClass(node, context: context)
    }
    static func didExit(_: ClassDeclSyntax, context: Context) {
        popClass(context: context)
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        pushFunction(node, context: context)
    }
    static func didExit(_: FunctionDeclSyntax, context: Context) {
        popFunction(context: context)
    }

    static func willEnter(_: ClosureExprSyntax, context: Context) {
        pushClosure(context: context)
    }
    static func didExit(_: ClosureExprSyntax, context: Context) {
        popClosure(context: context)
    }

    static func willEnter(_: StringLiteralExprSyntax, context: Context) {
        pushStringLiteral(context: context)
    }
    static func didExit(_: StringLiteralExprSyntax, context: Context) {
        popStringLiteral(context: context)
    }

    static func willEnter(_ node: MemberAccessExprSyntax, context: Context) {
        state(context).nonTestChainParentDepth += 1
        pushMemberAccess(node, context: context)
    }
    static func didExit(_ node: MemberAccessExprSyntax, context: Context) {
        popMemberAccess(node, context: context)
        let s = state(context)
        if s.nonTestChainParentDepth > 0 { s.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: FunctionCallExprSyntax, context: Context) {
        state(context).nonTestChainParentDepth += 1
        pushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: FunctionCallExprSyntax, context: Context) {
        popChainNode(Syntax(node), context: context)
        let s = state(context)
        if s.nonTestChainParentDepth > 0 { s.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: SubscriptCallExprSyntax, context: Context) {
        state(context).nonTestChainParentDepth += 1
        pushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: SubscriptCallExprSyntax, context: Context) {
        popChainNode(Syntax(node), context: context)
        let s = state(context)
        if s.nonTestChainParentDepth > 0 { s.nonTestChainParentDepth -= 1 }
    }

    static func willEnter(_ node: ForceUnwrapExprSyntax, context: Context) {
        pushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: ForceUnwrapExprSyntax, context: Context) {
        popChainNode(Syntax(node), context: context)
    }

    static func willEnter(_ node: AsExprSyntax, context: Context) {
        pushChainNode(Syntax(node), context: context)
    }
    static func didExit(_ node: AsExprSyntax, context: Context) {
        popChainNode(Syntax(node), context: context)
    }

    // MARK: - File-level pre-scan

    static func visitImport(_ node: ImportDeclSyntax, context: Context) {
        if node.path.first?.name.text == "Testing" {
            state(context).importsTesting = true
        }
    }

    static func visitSourceFile(_ node: SourceFileSyntax, context: Context) {
        setImportsXCTest(context: context, sourceFile: node)
    }

    // MARK: - Class scope

    static func pushClass(_ node: ClassDeclSyntax, context: Context) {
        let s = state(context)
        s.classStack.append(s.insideXCTestCase)
        if context.importsXCTest == .importsXCTest,
           let inheritance = node.inheritanceClause,
           inheritance.contains(named: "XCTestCase")
        {
            s.insideXCTestCase = true
        }
    }

    static func popClass(context: Context) {
        let s = state(context)
        if let was = s.classStack.popLast() { s.insideXCTestCase = was }
    }

    // MARK: - Function scope

    private static func isTestFunction(_ node: FunctionDeclSyntax, state s: State) -> Bool {
        if s.importsTesting, node.hasAttribute("Test", inModule: "Testing") { return true }
        if s.insideXCTestCase {
            let name = node.name.text
            return name.hasPrefix("test")
                && node.signature.parameterClause.parameters.isEmpty
                && node.signature.returnClause == nil
        }
        return false
    }

    static func pushFunction(_ node: FunctionDeclSyntax, context: Context) {
        let s = state(context)
        s.functionStack.append((s.insideTestFunction, s.addedTryExpression))
        s.insideTestFunction = isTestFunction(node, state: s)
        s.addedTryExpression = false
        s.functionDepth += 1
    }

    static func popFunction(context: Context) {
        let s = state(context)
        if let (wasInside, wasAdded) = s.functionStack.popLast() {
            s.insideTestFunction = wasInside
            s.addedTryExpression = wasAdded
        }
        s.functionDepth -= 1
    }

    // MARK: - Closure / string-interpolation scope

    static func pushClosure(context: Context) {
        state(context).closureDepth += 1
    }

    static func popClosure(context: Context) {
        let s = state(context)
        if s.closureDepth > 0 { s.closureDepth -= 1 }
    }

    static func pushStringLiteral(context: Context) {
        state(context).stringInterpolationDepth += 1
    }

    static func popStringLiteral(context: Context) {
        let s = state(context)
        if s.stringInterpolationDepth > 0 { s.stringInterpolationDepth -= 1 }
    }

    // MARK: - Chain-eligible parent willEnter / didExit

    /// Push state at a chain-eligible parent (MemberAccess/FunctionCall/
    /// SubscriptCall/ForceUnwrap/AsExpr): saves the current `chainNeedsWrapping`,
    /// resets it to false so children's signals are isolated, and captures
    /// chain-top status + classification from the pre-recursion node.
    static func pushChainNode(_ originalNode: Syntax, context: Context) {
        let s = state(context)
        s.chainSaveStack.append(s.chainNeedsWrapping)
        s.chainNeedsWrapping = false

        let isTop = isChainTop(originalNode)
        s.chainTopStack.append(isTop)
        s.chainContextStack.append(
            isTop ? classifyChainTopContext(originalNode) : .propagate
        )

        // Emit findings here (during willEnter, with original positions). The
        // legacy rule diagnoses/skips inside its `visit(_:)` BEFORE recursing —
        // we mirror that timing so location info reflects the original tree.
        if let force = originalNode.as(ForceUnwrapExprSyntax.self) {
            diagnoseForceUnwrap(force, isTop: isTop, context: context)
        } else if let asExpr = originalNode.as(AsExprSyntax.self),
                  asExpr.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            diagnoseAsExpr(asExpr, isTop: isTop, context: context)
        }
    }

    private static func diagnoseForceUnwrap(
        _ node: ForceUnwrapExprSyntax,
        isTop: Bool,
        context: Context
    ) {
        let s = state(context)

        // Skip if parent is `try!` (handled by NoForceTry).
        if let parentTry = node.parent?.as(TryExprSyntax.self),
           parentTry.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            return
        }

        if s.insideTestFunction {
            if s.closureDepth > 0 || s.stringInterpolationDepth > 0 { return }
            Self.diagnose(.replaceForceUnwrap, on: node.exclamationMark, context: context)
            return
        }

        // Non-test code: legacy diagnoses without recursing, so only the chain top
        // emits a finding. Additionally, legacy short-circuits recursion through
        // chain-eligible parents (FunctionCall/MemberAccess/SubscriptCall) in
        // non-test code, so a ForceUnwrap nested inside one never reaches
        // visit_ForceUnwrap. Mirror that here.
        guard isTop else { return }
        if s.nonTestChainParentDepth > 0 { return }
        Self.diagnose(
            .doNotForceUnwrap(name: node.expression.trimmedDescription),
            on: node, context: context
        )
    }

    private static func diagnoseAsExpr(
        _ node: AsExprSyntax,
        isTop: Bool,
        context: Context
    ) {
        let s = state(context)
        if s.insideTestFunction {
            if s.closureDepth > 0 || s.stringInterpolationDepth > 0 { return }
            Self.diagnose(.replaceForceCast, on: node.asKeyword, context: context)
            return
        }
        guard isTop else { return }
        if s.nonTestChainParentDepth > 0 { return }
        Self.diagnose(
            .doNotForceCast(name: node.type.trimmedDescription),
            on: node, context: context
        )
    }

    /// Restore the chain state stacks. Called from `didExit`. Note: the chain
    /// rewrite functions read (without popping) via `.last`; this pop runs after
    /// the rewrite. The propagation of `chainNeedsWrapping` happens here.
    static func popChainNode(_ originalNode: Syntax, context: Context) {
        let s = state(context)
        assert(
            !s.chainSaveStack.isEmpty
                && !s.chainTopStack.isEmpty
                && !s.chainContextStack.isEmpty,
            "willEnter/didExit imbalance in NoForceUnwrap chain stacks"
        )
        let saved = s.chainSaveStack.popLast() ?? false
        let isTop = s.chainTopStack.popLast() ?? false
        _ = s.chainContextStack.popLast()
        _ = originalNode

        if isTop {
            s.chainNeedsWrapping = saved
        } else {
            s.chainNeedsWrapping = saved || s.chainNeedsWrapping
        }
    }

    static func pushMemberAccess(_ node: MemberAccessExprSyntax, context: Context) {
        let s = state(context)
        let hadForceCast: Bool
        if let base = node.base,
           let tupleExpr = base.as(TupleExprSyntax.self),
           tupleExpr.elements.count == 1,
           let singleElement = tupleExpr.elements.first,
           findForceCast(in: singleElement.expression) != nil
        {
            hadForceCast = true
        } else {
            hadForceCast = false
        }
        s.memberHadForceCastStack.append(hadForceCast)
        pushChainNode(Syntax(node), context: context)
    }

    static func popMemberAccess(_ node: MemberAccessExprSyntax, context: Context) {
        let s = state(context)
        _ = s.memberHadForceCastStack.popLast()
        popChainNode(Syntax(node), context: context)
    }

    // MARK: - Chain topology

    /// Returns true if the node is the top of an expression chain.
    static func isChainTop(_ node: Syntax) -> Bool {
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

    static func classifyChainTopContext(_ node: Syntax) -> ChainTopContext {
        guard let parent = node.parent else { return .wrap }

        if parent.is(TupleExprSyntax.self) { return .propagate }

        if let labeledExpr = parent.as(LabeledExprSyntax.self) {
            return classifyArgContext(labeledExpr)
        }

        if let infixExpr = parent.as(InfixOperatorExprSyntax.self) {
            return classifyInfixTopContext(infixExpr, chainExpr: node)
        }

        if parent.is(CodeBlockItemSyntax.self) { return .noWrap }
        if parent.is(InitializerClauseSyntax.self) { return .wrap }
        if parent.is(ReturnStmtSyntax.self) { return .wrap }
        if parent.is(ConditionElementSyntax.self) { return .wrap }
        return .wrap
    }

    private static func classifyArgContext(
        _ labeledExpr: LabeledExprSyntax
    ) -> ChainTopContext {
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

    private static func classifyInfixTopContext(
        _ infixExpr: InfixOperatorExprSyntax,
        chainExpr: Syntax
    ) -> ChainTopContext {
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

    static func findForceCast(in expr: ExprSyntax) -> AsExprSyntax? {
        if let asExpr = expr.as(AsExprSyntax.self),
           asExpr.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            return asExpr
        }
        for child in expr.children(viewMode: .sourceAccurate) {
            if let childExpr = child.as(ExprSyntax.self),
               let found = findForceCast(in: childExpr)
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
    static func rewriteForceUnwrap(
        _ node: ForceUnwrapExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let s = state(context)

        guard s.insideTestFunction else { return ExprSyntax(node) }
        if s.closureDepth > 0 || s.stringInterpolationDepth > 0 {
            return ExprSyntax(node)
        }

        let isTop = s.chainTopStack.last ?? true
        let chainContext = s.chainContextStack.last ?? .wrap

        if isTop {
            switch chainContext {
                case .wrap:
                    s.addedTryExpression = true
                    return wrapInUnwrap(
                        node.expression,
                        trailingTrivia: node.exclamationMark.trailingTrivia,
                        state: s
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
                    s.chainNeedsWrapping = true
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
        s.chainNeedsWrapping = true
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
    static func rewriteAsExpr(
        _ node: AsExprSyntax,
        context: Context
    ) -> ExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else {
            return ExprSyntax(node)
        }

        let s = state(context)
        guard s.insideTestFunction else { return ExprSyntax(node) }
        if s.closureDepth > 0 || s.stringInterpolationDepth > 0 {
            return ExprSyntax(node)
        }

        var result = node
        result.questionOrExclamationMark = .postfixQuestionMarkToken(
            leadingTrivia: node.questionOrExclamationMark!.leadingTrivia,
            trailingTrivia: node.questionOrExclamationMark!.trailingTrivia
        )

        let isTop = s.chainTopStack.last ?? true
        let chainContext = s.chainContextStack.last ?? .wrap

        if isTop {
            switch chainContext {
                case .wrap:
                    s.addedTryExpression = true
                    return wrapInUnwrap(
                        ExprSyntax(result),
                        trailingTrivia: result.trailingTrivia,
                        state: s
                    )
                case .noWrap:
                    return ExprSyntax(result)
                case .propagate:
                    s.chainNeedsWrapping = true
                    return ExprSyntax(result)
            }
        }

        s.chainNeedsWrapping = true
        return ExprSyntax(result)
    }

    /// Apply the `MemberAccessExpr` chain-top wrapping. Called after children
    /// have been visited.
    static func rewriteMemberAccess(
        _ node: MemberAccessExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let s = state(context)
        guard s.insideTestFunction,
              s.closureDepth == 0,
              s.stringInterpolationDepth == 0
        else {
            return ExprSyntax(node)
        }

        let childChainNeedsWrapping = s.chainNeedsWrapping
        let isTop = s.chainTopStack.last ?? false
        let originalHadForceCast = s.memberHadForceCastStack.last ?? false

        if originalHadForceCast, let base = node.base {
            let optionalBase = OptionalChainingExprSyntax(
                expression: base,
                questionMark: .postfixQuestionMarkToken()
            )
            var result = node
            result.base = ExprSyntax(optionalBase)

            if isTop, childChainNeedsWrapping {
                return wrapIfNeeded(ExprSyntax(result), state: s)
            }
            return ExprSyntax(result)
        }

        if isTop, childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(node), state: s)
        }

        return ExprSyntax(node)
    }

    static func rewriteFunctionCallTop(
        _ node: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let s = state(context)
        guard s.insideTestFunction,
              s.closureDepth == 0,
              s.stringInterpolationDepth == 0
        else {
            return ExprSyntax(node)
        }

        let childChainNeedsWrapping = s.chainNeedsWrapping
        let isTop = s.chainTopStack.last ?? false
        if isTop, childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(node), state: s)
        }
        return ExprSyntax(node)
    }

    static func rewriteSubscriptCallTop(
        _ node: SubscriptCallExprSyntax,
        context: Context
    ) -> ExprSyntax {
        let s = state(context)
        guard s.insideTestFunction,
              s.closureDepth == 0,
              s.stringInterpolationDepth == 0
        else {
            return ExprSyntax(node)
        }

        let childChainNeedsWrapping = s.chainNeedsWrapping
        let isTop = s.chainTopStack.last ?? false
        if isTop, childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(node), state: s)
        }
        return ExprSyntax(node)
    }

    // MARK: - Wrap helpers

    static func wrapIfNeeded(
        _ expr: ExprSyntax,
        state s: State
    ) -> ExprSyntax {
        let chainContext = s.chainContextStack.last ?? .wrap
        switch chainContext {
            case .wrap:
                s.addedTryExpression = true
                s.chainNeedsWrapping = false
                return wrapInUnwrap(
                    expr, trailingTrivia: expr.trailingTrivia, state: s
                )
            case .noWrap:
                s.chainNeedsWrapping = false
                return expr
            case .propagate:
                return expr
        }
    }

    static func wrapInUnwrap(
        _ expr: ExprSyntax,
        trailingTrivia: Trivia = [],
        state s: State
    ) -> ExprSyntax {
        let innerExpr = expr.trimmed
        let callExpr: ExprSyntax = s.importsTesting
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
    static func afterFunctionDecl(
        _ node: FunctionDeclSyntax,
        context: Context
    ) -> FunctionDeclSyntax {
        let s = state(context)
        guard s.insideTestFunction, s.addedTryExpression else { return node }
        if node.signature.effectSpecifiers?.throwsClause != nil { return node }
        return node.addingThrowsClause()
    }
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
