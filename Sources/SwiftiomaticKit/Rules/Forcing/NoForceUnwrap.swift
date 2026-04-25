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
/// Format: In test functions, force unwraps are replaced with XCTUnwrap/#require.
final class NoForceUnwrap: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var group: ConfigurationGroup? { .forcing }
    override static var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    private var testContext = TestContextTracker()
    private var insideTestFunction = false
    private var addedTryExpression = false
    /// Set when a force unwrap is converted inside a chain that needs wrapping at the chain top.
    private var chainNeedsWrapping = false

    // MARK: - Scope tracking

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        testContext.visitImport(node)
        return .init(node)
    }

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        testContext.visitSourceFile(node, context: context)
        return super.visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        let was = testContext.pushClass(node, context: context)
        defer { testContext.popClass(was: was) }
        return super.visit(node)
    }

    // Don't recurse into closures in test functions — try can't propagate out.
    // In non-test code, continue recursing to diagnose.
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        guard insideTestFunction else { return super.visit(node) }
        return .init(node)
    }

    // Don't recurse into string interpolation in test functions — try is not allowed.
    // In non-test code, continue recursing to diagnose.
    override func visit(_ node: StringLiteralExprSyntax) -> ExprSyntax {
        guard insideTestFunction else { return super.visit(node) }
        return .init(node)
    }

    // MARK: - Function-level: detect test, add throws

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard node.body != nil else { return DeclSyntax(node) }

        // Non-test functions: visit children for diagnose-only but don't rewrite.
        // Reset insideTestFunction so nested functions inside test functions don't
        // get treated as test code (try can't propagate out of nested functions).
        guard testContext.isTestFunction(node) else {
            let wasInsideTest = insideTestFunction
            insideTestFunction = false
            defer { insideTestFunction = wasInsideTest }
            return super.visit(node)
        }

        let wasInsideTest = insideTestFunction
        let wasAddedTry = addedTryExpression
        insideTestFunction = true
        addedTryExpression = false

        defer {
            insideTestFunction = wasInsideTest
            addedTryExpression = wasAddedTry
        }
        let visited = super.visit(node)

        guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

        guard addedTryExpression else { return DeclSyntax(result) }

        if result.signature.effectSpecifiers?.throwsClause == nil {
            result = result.addingThrowsClause()
        }

        return .init(result)
    }

    // MARK: - Force unwrap

    override func visit(_ node: ForceUnwrapExprSyntax) -> ExprSyntax {
        // Non-test code: diagnose only (no rewriting)
        guard insideTestFunction else {
            diagnose(.doNotForceUnwrap(name: node.expression.trimmedDescription), on: node)
            return ExprSyntax(node)
        }

        // Skip if preceded by try! (handled by NoForceTry)
        if let parentTry = node.parent?.as(TryExprSyntax.self),
           parentTry.questionOrExclamationMark?.tokenKind == .exclamationMark
        {
            return ExprSyntax(node)
        }

        let visited = super.visit(node)
        guard let typedNode = visited.as(ForceUnwrapExprSyntax.self) else { return visited }

        diagnose(.replaceForceUnwrap, on: node.exclamationMark)

        // If this ForceUnwrapExpr IS the chain top, handle wrapping directly
        if isChainTop(Syntax(node)) {
            let context = classifyChainTopContext(Syntax(node))

            switch context {
                case .wrap:
                    // Wrap the inner expression (remove !, XCTUnwrap does the unwrapping)
                    addedTryExpression = true
                    return wrapInUnwrap(
                        typedNode.expression,
                        trailingTrivia: typedNode.exclamationMark.trailingTrivia
                    )
                case .noWrap:
                    // Just convert to optional chaining
                    return ExprSyntax(
                        OptionalChainingExprSyntax(
                            expression: typedNode.expression,
                            questionMark: .postfixQuestionMarkToken(
                                leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                                trailingTrivia: typedNode.exclamationMark.trailingTrivia
                            )
                        ))
                case .propagate:
                    // Convert to ? and let parent handle wrapping
                    chainNeedsWrapping = true
                    return ExprSyntax(
                        OptionalChainingExprSyntax(
                            expression: typedNode.expression,
                            questionMark: .postfixQuestionMarkToken(
                                leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                                trailingTrivia: typedNode.exclamationMark.trailingTrivia
                            )
                        ))
            }
        }

        // Not the chain top — convert to ? and signal chain needs wrapping
        chainNeedsWrapping = true
        return .init(
            OptionalChainingExprSyntax(
                expression: typedNode.expression,
                questionMark: .postfixQuestionMarkToken(
                    leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                    trailingTrivia: typedNode.exclamationMark.trailingTrivia
                )
            ))
    }

    // MARK: - Force cast (as!)

    override func visit(_ node: AsExprSyntax) -> ExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else {
            return ExprSyntax(node)
        }

        // Non-test code: diagnose only (no rewriting)
        guard insideTestFunction else {
            diagnose(.doNotForceCast(name: node.type.trimmedDescription), on: node)
            return ExprSyntax(node)
        }

        let visited = super.visit(node)
        guard let typedNode = visited.as(AsExprSyntax.self) else { return visited }

        diagnose(.replaceForceCast, on: node.asKeyword)

        // Convert as! to as?
        var result = typedNode
        result
            .questionOrExclamationMark = .postfixQuestionMarkToken(
                leadingTrivia: typedNode.questionOrExclamationMark!.leadingTrivia,
                trailingTrivia: typedNode.questionOrExclamationMark!.trailingTrivia
            )

        // If this is a chain top, decide wrapping
        if isChainTop(Syntax(node)) {
            let context = classifyChainTopContext(Syntax(node))

            switch context {
                case .wrap:
                    addedTryExpression = true
                    return wrapInUnwrap(ExprSyntax(result), trailingTrivia: result.trailingTrivia)
                case .noWrap: return ExprSyntax(result)
                case .propagate:
                    chainNeedsWrapping = true
                    return ExprSyntax(result)
            }
        }

        // Not chain top — signal chain needs wrapping
        chainNeedsWrapping = true
        return .init(result)
    }

    // MARK: - Chain top wrapping: MemberAccessExpr

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        guard insideTestFunction else { return ExprSyntax(node) }

        // Check original node: does the base contain a force cast inside parens?
        let originalHadForceCast: Bool

        if let base = node.base,
           let tupleExpr = base.as(TupleExprSyntax.self),
           tupleExpr.elements.count == 1,
           let singleElement = tupleExpr.elements.first,
           findForceCast(in: singleElement.expression) != nil
        {
            originalHadForceCast = true
        } else {
            originalHadForceCast = false
        }

        let savedFlag = chainNeedsWrapping
        chainNeedsWrapping = false
        let visited = super.visit(node)
        let childChainNeedsWrapping = chainNeedsWrapping
        chainNeedsWrapping = savedFlag || childChainNeedsWrapping
        guard let typedNode = visited.as(MemberAccessExprSyntax.self) else { return visited }

        // If the original had a force cast that we converted to as?, add optional chaining
        if originalHadForceCast, let base = typedNode.base {
            let optionalBase = OptionalChainingExprSyntax(
                expression: base,
                questionMark: .postfixQuestionMarkToken()
            )
            var result = typedNode
            result.base = ExprSyntax(optionalBase)

            if isChainTop(Syntax(node)), childChainNeedsWrapping {
                return wrapIfNeeded(ExprSyntax(result), originalNode: Syntax(node))
            }
            return ExprSyntax(result)
        }

        // If at chain top and wrapping needed, wrap
        if isChainTop(Syntax(node)), childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(typedNode), originalNode: Syntax(node))
        }

        return .init(typedNode)
    }

    // MARK: - Chain top wrapping: FunctionCallExpr

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard insideTestFunction else { return ExprSyntax(node) }

        let savedFlag = chainNeedsWrapping
        chainNeedsWrapping = false
        let visited = super.visit(node)
        let childChainNeedsWrapping = chainNeedsWrapping
        chainNeedsWrapping = savedFlag || childChainNeedsWrapping
        guard let typedNode = visited.as(FunctionCallExprSyntax.self) else { return visited }

        // If at chain top and wrapping needed, wrap
        if isChainTop(Syntax(node)), childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(typedNode), originalNode: Syntax(node))
        }

        return .init(typedNode)
    }

    // MARK: - Chain top wrapping: SubscriptCallExpr

    override func visit(_ node: SubscriptCallExprSyntax) -> ExprSyntax {
        guard insideTestFunction else { return ExprSyntax(node) }

        let savedFlag = chainNeedsWrapping
        chainNeedsWrapping = false
        let visited = super.visit(node)
        let childChainNeedsWrapping = chainNeedsWrapping
        chainNeedsWrapping = savedFlag || childChainNeedsWrapping
        guard let typedNode = visited.as(SubscriptCallExprSyntax.self) else { return visited }

        if isChainTop(Syntax(node)), childChainNeedsWrapping {
            return wrapIfNeeded(ExprSyntax(typedNode), originalNode: Syntax(node))
        }

        return .init(typedNode)
    }

    // MARK: - Chain topology

    /// Returns true if this node is the top of an expression chain (parent is not a chain node).
    private func isChainTop(_ node: Syntax) -> Bool {
        guard let parent = node.parent else { return true }

        // Chain continuation nodes — if parent is one of these, we're NOT the top
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

    // MARK: - Context-dependent wrapping

    /// At a chain top, decide if the expression should be wrapped based on parent context.
    private func wrapIfNeeded(_ expr: ExprSyntax, originalNode: Syntax) -> ExprSyntax {
        let context = classifyChainTopContext(originalNode)

        switch context {
            case .wrap:
                addedTryExpression = true
                chainNeedsWrapping = false
                return wrapInUnwrap(expr, trailingTrivia: expr.trailingTrivia)
            case .noWrap:
                chainNeedsWrapping = false
                return expr
            case .propagate: return expr
        }
    }

    private enum ChainTopContext { case wrap, noWrap, propagate }

    private func classifyChainTopContext(_ node: Syntax) -> ChainTopContext {
        guard let parent = node.parent else { return .wrap }

        // Tuple (parens) — keep propagating
        if parent.is(TupleExprSyntax.self) { return .propagate }

        // Function argument — check which function
        if let labeledExpr = parent.as(LabeledExprSyntax.self) {
            return classifyArgContext(labeledExpr)
        }

        // Infix operator — check which operator
        if let infixExpr = parent.as(InfixOperatorExprSyntax.self) {
            return classifyInfixTopContext(infixExpr, chainExpr: node)
        }

        // Standalone expression (direct child of CodeBlockItem)
        if parent.is(CodeBlockItemSyntax.self) { return .noWrap }

        // Initializer clause (let x = expr) — wrap
        if parent.is(InitializerClauseSyntax.self) { return .wrap }

        // Return statement — wrap
        if parent.is(ReturnStmtSyntax.self) { return .wrap }

        // Condition element — wrap
        if parent.is(ConditionElementSyntax.self) { return .wrap }

        return .wrap
    }

    private func classifyArgContext(_ labeledExpr: LabeledExprSyntax) -> ChainTopContext {
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

    private func classifyInfixTopContext(
        _ infixExpr: InfixOperatorExprSyntax,
        chainExpr: Syntax
    ) -> ChainTopContext {
        let op = infixExpr.operator

        // Assignment: LHS → no wrap, RHS → wrap
        if op.is(AssignmentExprSyntax.self) {
            if infixExpr.leftOperand.id == chainExpr.id { return .noWrap }
            return .wrap
        }

        // Equality: no wrap
        if let binOp = op.as(BinaryOperatorExprSyntax.self), binOp.operator.text == "==" {
            return .noWrap
        }

        // Other operators: wrap
        return .wrap
    }

    // MARK: - Wrap expression in XCTUnwrap / #require

    private func wrapInUnwrap(_ expr: ExprSyntax, trailingTrivia: Trivia = []) -> ExprSyntax {
        let innerExpr = expr.trimmed
        let callExpr: ExprSyntax

        callExpr = testContext.importsTesting
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

        return .init(
            TryExprSyntax(
                tryKeyword: .keyword(.try, trailingTrivia: .space),
                expression: callExpr
            ))
    }

    /// Find a force cast (as!) anywhere in the expression tree.
    private func findForceCast(in expr: ExprSyntax) -> AsExprSyntax? {
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
}

fileprivate extension Finding.Message {
    static func doNotForceUnwrap(name: String) -> Finding.Message {
        "do not force unwrap '\(name)'"
    }

    static func doNotForceCast(name: String) -> Finding.Message { "do not force cast to '\(name)'" }

    static let replaceForceUnwrap: Finding.Message =
        "replace force unwrap in test with 'XCTUnwrap' or '#require'"
    
    static let replaceForceCast: Finding.Message = "replace force cast in test with optional cast"
}
