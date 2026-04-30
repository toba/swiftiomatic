import SwiftSyntax

/// Convert `guard` statements in test functions to `try #require(...)`/`#expect(...)` (Swift
/// Testing) or `try XCTUnwrap(...)`/`XCTAssert(...)` (XCTest).
///
/// Guard statements in tests obscure the test intent behind control flow. Replacing them with
/// direct assertions or unwraps makes the test linear and the failure message immediate.
///
/// Lint: A warning is raised for each `guard` that can be converted.
///
/// Rewrite: The `guard` is replaced with assertion/unwrap statements and `throws` is added to
/// the signature if needed.
final class NoGuardInTests: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .testing }
    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context`.
    final class State {
        var testContext = TestContextTracker()
        /// Stack of `(insideTestFunction, addedTryStatement)` frames pushed at function entry.
        var functionStack: [(insideTest: Bool, addedTry: Bool)] = []
        /// Stack of previous `insideXCTestCase` values pushed at class entry.
        var classStack: [Bool] = []
        var insideTestFunction = false
        var addedTryStatement = false
    }

    // MARK: - Pre-scan / scope tracking

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.noGuardInTestsState
        state.testContext.visitSourceFile(node, context: context)
        for stmt in node.statements {
            if let importDecl = stmt.item.as(ImportDeclSyntax.self) {
                state.testContext.visitImport(importDecl)
            }
        }
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        let state = context.noGuardInTestsState
        let was = state.testContext.pushClass(node, context: context)
        // Stash via stack — use functionStack as a generic stack? Use a dedicated stack instead.
        state.classStack.append(was)
    }

    static func didExit(_ node: ClassDeclSyntax, context: Context) {
        _ = node
        let state = context.noGuardInTestsState
        guard let was = state.classStack.popLast() else { return }
        state.testContext.popClass(was: was)
    }

    static func willEnter(_ node: FunctionDeclSyntax, context: Context) {
        let state = context.noGuardInTestsState
        state.functionStack.append((state.insideTestFunction, state.addedTryStatement))
        if state.testContext.isTestFunction(node), node.body != nil {
            state.insideTestFunction = true
            state.addedTryStatement = false
        } else {
            // Nested or non-test function: shadow the test-function context so guards in
            // nested helpers aren't rewritten (they belong to the inner function's scope).
            state.insideTestFunction = false
            state.addedTryStatement = false
        }
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        let state = context.noGuardInTestsState
        guard let frame = state.functionStack.popLast() else { return }
        state.insideTestFunction = frame.insideTest
        state.addedTryStatement = frame.addedTry
    }

    // Don't recurse into closures — guard inside closures can't be fixed by
    // making the outer function throw. Mirror the legacy override's
    // short-circuit by pushing/popping `insideTestFunction = false` around
    // the closure body in the compact pipeline.
    static func willEnter(_: ClosureExprSyntax, context: Context) {
        let state = context.noGuardInTestsState
        state.functionStack.append((state.insideTestFunction, state.addedTryStatement))
        state.insideTestFunction = false
    }

    static func didExit(_: ClosureExprSyntax, context: Context) {
        let state = context.noGuardInTestsState
        guard let frame = state.functionStack.popLast() else { return }
        state.insideTestFunction = frame.insideTest
        state.addedTryStatement = frame.addedTry
    }

    // MARK: - Static transforms

    /// Wraps the original `visit(FunctionDeclSyntax)` post-recursion logic. State has already been
    /// pushed in willEnter; we read `addedTryStatement` set during child traversal.
    static func transform(
        _ node: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.noGuardInTestsState
        // Only proceed if this is a test function (matches what willEnter detected).
        guard state.testContext.isTestFunction(node), node.body != nil else {
            return DeclSyntax(node)
        }
        guard state.addedTryStatement else { return DeclSyntax(node) }

        var result = node
        if result.signature.effectSpecifiers?.throwsClause == nil {
            result = result.addingThrowsClause()
        }
        return DeclSyntax(result)
    }

    /// Compact-pipeline entry point. Only runs when inside a test function
     /// (state populated by the `willEnter(FunctionDeclSyntax,…)` hook); the
     /// state gating mirrors the legacy override.
    static func transform(
        _ node: CodeBlockItemListSyntax,
        parent _: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        let state = context.noGuardInTestsState
        guard state.insideTestFunction else { return node }
        return Self.transformCodeBlockItemList(node, context: context)
    }

    private static func transformCodeBlockItemList(
        _ node: CodeBlockItemListSyntax,
        context: Context
    ) -> CodeBlockItemListSyntax {
        let state = context.noGuardInTestsState
        let items = Array(node)
        var newItems = [CodeBlockItemSyntax]()
        var changed = false

        var declaredNames = Set<String>()

        for item in items {
            collectDeclaredNames(from: item, into: &declaredNames)

            guard let guardStmt = item.item.as(GuardStmtSyntax.self) else {
                newItems.append(item)
                continue
            }

            guard
                let replacement = convertGuard(
                    guardStmt,
                    item: item,
                    declaredNames: declaredNames,
                    state: state,
                    context: context
                )
            else {
                newItems.append(item)
                continue
            }

            newItems.append(contentsOf: replacement)
            changed = true
        }

        guard changed else { return node }
        return CodeBlockItemListSyntax(newItems)
    }

    // MARK: - Guard analysis and conversion

    private static func convertGuard(
        _ guard: GuardStmtSyntax,
        item: CodeBlockItemSyntax,
        declaredNames: Set<String>,
        state: State,
        context: Context
    ) -> [CodeBlockItemSyntax]? {
        guard isValidElseBlock(`guard`.body) else { return nil }

        let conditions = Array(`guard`.conditions)

        for condition in conditions {
            switch condition.condition {
                case .optionalBinding(let binding):
                    let name = binding.pattern.trimmedDescription
                    if declaredNames.contains(name) { return nil }
                    if binding.initializer?.value.containsAwait == true { return nil }
                    if binding.initializer == nil && declaredNames.contains(name) { return nil }
                case .matchingPattern:
                    return nil
                case .expression(let expr):
                    if expr.containsAwait { return nil }
                case .availability:
                    return nil
                #if compiler(>=6.0)
                    @unknown default:
                        return nil
                #endif
            }
        }

        let assertionMessage = extractAssertionMessage(from: `guard`.body)
        let useSwiftTesting = state.testContext.importsTesting
        let fullLeadingTrivia = item.leadingTrivia
        let indentTrivia = extractIndentation(from: fullLeadingTrivia)

        Self.diagnose(.convertGuard, on: `guard`.guardKeyword, context: context)

        var replacements = [CodeBlockItemSyntax]()

        for (index, condition) in conditions.enumerated() {
            let isFirst = index == 0
            let trivia = isFirst ? fullLeadingTrivia : .newline + indentTrivia

            switch condition.condition {
                case .optionalBinding(let binding):
                    let stmt = buildUnwrapStatement(
                        from: binding,
                        useSwiftTesting: useSwiftTesting,
                        assertionMessage: assertionMessage
                    )
                    var codeBlockItem = CodeBlockItemSyntax(item: .decl(DeclSyntax(stmt)))
                    codeBlockItem.leadingTrivia = trivia
                    replacements.append(codeBlockItem)
                    state.addedTryStatement = true

                case .expression(let expr):
                    let assertExpr = buildAssertExpr(
                        for: expr,
                        useSwiftTesting: useSwiftTesting,
                        assertionMessage: assertionMessage
                    )
                    var codeBlockItem = CodeBlockItemSyntax(item: .expr(assertExpr))
                    codeBlockItem.leadingTrivia = trivia
                    replacements.append(codeBlockItem)

                default:
                    break
            }
        }

        return replacements
    }

    // MARK: - Else block validation

    private static func isValidElseBlock(_ body: CodeBlockSyntax) -> Bool {
        let stmts = body.statements.map(\.item)
        let nonTrivial = stmts.filter { stmt in
            stmt.trimmedDescription.isEmpty == false
        }

        if nonTrivial.count == 1, nonTrivial[0].is(ReturnStmtSyntax.self) {
            return true
        }

        guard nonTrivial.last?.is(ReturnStmtSyntax.self) == true else { return false }

        if nonTrivial.count == 2 {
            if let callExpr = extractFunctionCall(from: nonTrivial[0]) {
                let name = callExpr.calledExpression.trimmedDescription
                return name == "XCTFail" || name == "Issue.record"
            }
        }

        return false
    }

    private static func extractAssertionMessage(
        from body: CodeBlockSyntax
    ) -> LabeledExprListSyntax? {
        for stmt in body.statements {
            if let callExpr = extractFunctionCall(from: stmt.item) {
                let name = callExpr.calledExpression.trimmedDescription
                if name == "XCTFail" || name == "Issue.record",
                    !callExpr.arguments.isEmpty
                {
                    return callExpr.arguments
                }
            }
        }
        return nil
    }

    private static func extractFunctionCall(
        from item: CodeBlockItemSyntax.Item
    ) -> FunctionCallExprSyntax? {
        if let callExpr = item.as(FunctionCallExprSyntax.self) {
            return callExpr
        }
        if let exprStmt = item.as(ExpressionStmtSyntax.self) {
            return exprStmt.expression.as(FunctionCallExprSyntax.self)
        }
        return nil
    }

    // MARK: - Statement builders

    private static func buildUnwrapStatement(
        from binding: OptionalBindingConditionSyntax,
        useSwiftTesting: Bool,
        assertionMessage: LabeledExprListSyntax?
    ) -> VariableDeclSyntax {
        let keyword = binding.bindingSpecifier
        let patternText = binding.pattern.trimmedDescription

        let unwrapExpr: ExprSyntax
        if let initializer = binding.initializer {
            unwrapExpr = initializer.value.trimmed
        } else {
            unwrapExpr = ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier(patternText))
            )
        }

        let callExpr: ExprSyntax
        if useSwiftTesting {
            callExpr = buildMacroCall(
                name: "require",
                expression: unwrapExpr,
                assertionMessage: assertionMessage
            )
        } else {
            callExpr = buildFunctionCall(
                name: "XCTUnwrap",
                expression: unwrapExpr,
                assertionMessage: assertionMessage
            )
        }

        let tryExpr = TryExprSyntax(
            tryKeyword: .keyword(.try, trailingTrivia: .space),
            expression: callExpr
        )

        let initializerClause = InitializerClauseSyntax(
            equal: .binaryOperator("=", leadingTrivia: .space, trailingTrivia: .space),
            value: ExprSyntax(tryExpr)
        )

        let typeAnnotation: TypeAnnotationSyntax? = binding.typeAnnotation.map {
            $0.with(\.colon, $0.colon.with(\.leadingTrivia, []).with(\.trailingTrivia, .space))
                .with(\.type, $0.type.trimmed)
        }

        let pattern = PatternSyntax(
            IdentifierPatternSyntax(identifier: .identifier(patternText))
        )

        let patternBinding = PatternBindingSyntax(
            pattern: pattern,
            typeAnnotation: typeAnnotation,
            initializer: initializerClause
        )

        return VariableDeclSyntax(
            bindingSpecifier: keyword.with(\.leadingTrivia, []).with(\.trailingTrivia, .space),
            bindings: PatternBindingListSyntax([patternBinding])
        )
    }

    private static func buildAssertExpr(
        for expr: ExprSyntax,
        useSwiftTesting: Bool,
        assertionMessage: LabeledExprListSyntax?
    ) -> ExprSyntax {
        let args = buildArgList(expression: expr.trimmed, assertionMessage: assertionMessage)

        if useSwiftTesting {
            return ExprSyntax(
                MacroExpansionExprSyntax(
                    pound: .poundToken(),
                    macroName: .identifier("expect"),
                    leftParen: .leftParenToken(),
                    arguments: args,
                    rightParen: .rightParenToken()
                )
            )
        } else {
            return ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: ExprSyntax(
                        DeclReferenceExprSyntax(baseName: .identifier("XCTAssert"))
                    ),
                    leftParen: .leftParenToken(),
                    arguments: args,
                    rightParen: .rightParenToken()
                )
            )
        }
    }

    private static func buildArgList(
        expression: ExprSyntax,
        assertionMessage: LabeledExprListSyntax?
    ) -> LabeledExprListSyntax {
        var args = [LabeledExprSyntax]()

        if let message = assertionMessage {
            args.append(
                LabeledExprSyntax(
                    expression: expression,
                    trailingComma: .commaToken()
                )
            )
            for (i, arg) in message.enumerated() {
                var msgArg = arg.trimmed
                msgArg.leadingTrivia = .space
                if i == message.count - 1 {
                    msgArg.trailingComma = nil
                }
                args.append(msgArg)
            }
        } else {
            args.append(LabeledExprSyntax(expression: expression))
        }

        return LabeledExprListSyntax(args)
    }

    private static func buildMacroCall(
        name: String,
        expression: ExprSyntax,
        assertionMessage: LabeledExprListSyntax?
    ) -> ExprSyntax {
        ExprSyntax(
            MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier(name),
                leftParen: .leftParenToken(),
                arguments: buildArgList(expression: expression, assertionMessage: assertionMessage),
                rightParen: .rightParenToken()
            )
        )
    }

    private static func buildFunctionCall(
        name: String,
        expression: ExprSyntax,
        assertionMessage: LabeledExprListSyntax?
    ) -> ExprSyntax {
        ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier(name))
                ),
                leftParen: .leftParenToken(),
                arguments: buildArgList(expression: expression, assertionMessage: assertionMessage),
                rightParen: .rightParenToken()
            )
        )
    }

    // MARK: - Helpers

    private static func extractIndentation(from trivia: Trivia) -> Trivia {
        var pieces = [TriviaPiece]()
        for piece in trivia.pieces.reversed() {
            switch piece {
                case .spaces, .tabs:
                    pieces.insert(piece, at: 0)
                default:
                    if !pieces.isEmpty { return Trivia(pieces: pieces) }
            }
        }
        return Trivia(pieces: pieces)
    }

    private static func collectDeclaredNames(
        from item: CodeBlockItemSyntax,
        into names: inout Set<String>
    ) {
        if let varDecl = item.item.as(VariableDeclSyntax.self) {
            for binding in varDecl.bindings {
                if let identPattern = binding.pattern.as(IdentifierPatternSyntax.self) {
                    names.insert(identPattern.identifier.text)
                }
            }
        }
    }
}

// MARK: - Helpers

extension ExprSyntax {
    fileprivate var containsAwait: Bool {
        tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.await) }
    }
}

extension Finding.Message {
    fileprivate static let convertGuard: Finding.Message =
        "replace 'guard' in test with direct assertion or unwrap"
}
