import SwiftSyntax

/// Convert XCTest suites to Swift Testing.
///
/// Replaces `import XCTest` with `import Testing` + `import Foundation` , removes `XCTestCase`
/// conformance, converts `setUp` / `tearDown` to `init` / `deinit` , adds `@Test` to test methods,
/// and converts XCT assertions to `#expect` / `#require` .
///
/// Bails out entirely if the file contains unsupported XCTest functionality (expectations,
/// performance tests, unknown overrides, async/throws tearDown, XCTestCase extensions).
final class PreferSwiftTesting: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .testing }

    override class var defaultValue: BasicRuleValue { .init(rewrite: false, lint: .no) }

    /// Per-file mutable state held as a typed lazy property on `Context` .
    final class State {
        var bailOut = false
        var hasXCTestImport = false
        var xcTestCaseClassNames = Set<String>()
        /// Stack of `insideXCTestCase` saved values (push at class/extension entry).
        var insideXCTestCaseStack: [Bool] = []
        var insideXCTestCase = false
        /// Stack of `currentFunctionHasTry` saved values.
        var currentFunctionHasTryStack: [Bool] = []
        var currentFunctionHasTry = false
        /// Stack of pre-traversal `FunctionCallExprSyntax` nodes captured by the compact pipeline's
        /// `willEnter` so that the post-traversal `transform` can use the original (still-attached)
        /// node for finding source locations.
        var originalCallStack: [FunctionCallExprSyntax] = []
    }

    // MARK: - Pre-scan

    static func willEnter(_ node: SourceFileSyntax, context: Context) {
        let state = context.preferSwiftTestingState

        for stmt in node.statements {
            if let importDecl = stmt.item.as(ImportDeclSyntax.self) {
                if importDecl.path.first?.name.text == "XCTest" { state.hasXCTestImport = true }
            }
        }

        guard state.hasXCTestImport else { return }

        if hasUnsupportedPatterns(in: node) {
            state.bailOut = true
            return
        }

        for stmt in node.statements {
            if let classDecl = stmt.item.as(ClassDeclSyntax.self),
               let inheritance = classDecl.inheritanceClause,
               inheritance.contains(named: "XCTestCase")
            {
                state.xcTestCaseClassNames.insert(classDecl.name.text)
            }
        }

        for stmt in node.statements {
            if let extDecl = stmt.item.as(ExtensionDeclSyntax.self) {
                let extName = extDecl.extendedType.trimmedDescription

                if extName == "XCTestCase" || state.xcTestCaseClassNames.contains(extName) {
                    if extName == "XCTestCase" {
                        state.bailOut = true
                        return
                    }
                }
            }
        }
    }

    static func willEnter(_ node: ClassDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return }
        state.insideXCTestCaseStack.append(state.insideXCTestCase)
        if let inheritance = node.inheritanceClause,
           inheritance.contains(named: "XCTestCase")
        {
            state.insideXCTestCase = true
        }
    }

    static func didExit(_: ClassDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return }
        if let was = state.insideXCTestCaseStack.popLast() { state.insideXCTestCase = was }
    }

    static func willEnter(_ node: ExtensionDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return }
        state.insideXCTestCaseStack.append(state.insideXCTestCase)
        let extName = node.extendedType.trimmedDescription
        if state.xcTestCaseClassNames.contains(extName) { state.insideXCTestCase = true }
    }

    static func didExit(_: ExtensionDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return }
        if let was = state.insideXCTestCaseStack.popLast() { state.insideXCTestCase = was }
    }

    static func willEnter(_: FunctionDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        state.currentFunctionHasTryStack.append(state.currentFunctionHasTry)
        state.currentFunctionHasTry = false
    }

    static func didExit(_: FunctionDeclSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        if let was = state.currentFunctionHasTryStack.popLast() {
            state.currentFunctionHasTry = was
        }
    }

    static func willEnter(_ node: FunctionCallExprSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return }
        let calledName = node.calledExpression.trimmedDescription
        guard calledName.hasPrefix("XCT") || calledName == "Issue.record" else { return }
        state.originalCallStack.append(node)
    }

    static func didExit(_: FunctionCallExprSyntax, context: Context) {
        let state = context.preferSwiftTestingState
        // The matching `transform` already pops; this is a safety net in case the call wasn't
        // actually transformed (e.g. arity mismatch).
        _ = state.originalCallStack
    }

    static func transform(
        _ node: FunctionCallExprSyntax,
        parent: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return ExprSyntax(node) }

        let calledName = node.calledExpression.trimmedDescription
        guard calledName.hasPrefix("XCT") || calledName == "Issue.record" else {
            return ExprSyntax(node)
        }

        // Pop the matching original (pre-recursion) node pushed in willEnter. The compact
        // dispatcher visits children before this transform, so `node` is detached from its parent
        // and its source locations would be wrong.
        let originalNode: FunctionCallExprSyntax

        if let last = state.originalCallStack.popLast() {
            originalNode = last
        } else {
            originalNode = node
        }
        return Self.transformAssertion(
            node, originalNode: originalNode, parent: parent, context: context
        )
    }

    // MARK: - Static transforms

    static func transform(
        _ node: ImportDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return DeclSyntax(node) }

        if node.path.first?.name.text == "XCTest" {
            var result = node
            result.path = ImportPathComponentListSyntax([
                ImportPathComponentSyntax(name: .identifier("Testing"))
            ])
            return DeclSyntax(result)
        }
        return DeclSyntax(node)
    }

    static func transform(
        _ node: ClassDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut else { return DeclSyntax(node) }
        guard let inheritance = node.inheritanceClause,
              inheritance.contains(named: "XCTestCase") else { return DeclSyntax(node) }

        var result = node

        if let inheritanceClause = result.inheritanceClause {
            if let newClause = inheritanceClause.removing(named: "XCTestCase") {
                if newClause.inheritedTypes.count == inheritanceClause.inheritedTypes.count {
                    // Same count → name not found, no change
                } else {
                    result.inheritanceClause = newClause
                }
            } else {
                result.inheritanceClause = nil
                result.memberBlock.leftBrace.leadingTrivia = .space
            }
        }

        return DeclSyntax(result)
    }

    private static func transformAssertion(
        _ typedNode: FunctionCallExprSyntax,
        originalNode: FunctionCallExprSyntax,
        parent _: Syntax?,
        context: Context
    ) -> ExprSyntax {
        let calledName = originalNode.calledExpression.trimmedDescription

        if var replacement = convertAssertion(
            calledName,
            call: typedNode,
            originalNode: originalNode,
            context: context
        ) {
            replacement.leadingTrivia = typedNode.leadingTrivia
            replacement.trailingTrivia = typedNode.trailingTrivia
            return replacement
        }
        return ExprSyntax(typedNode)
    }

    // MARK: - Assertion conversion (static)

    private static func convertAssertion(
        _ name: String,
        call: FunctionCallExprSyntax,
        originalNode: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        let args = Array(call.arguments)

        switch name {
            case "XCTAssert", "XCTAssertTrue":
                return convertSingleValueAssert(
                    args, originalNode: originalNode, context: context
                ) { $0 }

            case "XCTAssertFalse":
                return convertSingleValueAssert(
                    args, originalNode: originalNode, context: context
                ) { expr in
                    ExprSyntax(
                        PrefixOperatorExprSyntax(
                            operator: .prefixOperator("!"),
                            expression: wrapInParensIfNeeded(expr)
                        ))
                }

            case "XCTAssertNil":
                return convertSingleValueAssert(
                    args, originalNode: originalNode, context: context
                ) { expr in
                    ExprSyntax(
                        InfixOperatorExprSyntax(
                            leftOperand: wrapInParensIfNeeded(expr),
                            operator: ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: .binaryOperator(
                                        "==",
                                        leadingTrivia: .space,
                                        trailingTrivia: .space
                                    ))),
                            rightOperand: ExprSyntax(NilLiteralExprSyntax())
                        ))
                }

            case "XCTAssertNotNil":
                return convertSingleValueAssert(
                    args, originalNode: originalNode, context: context
                ) { expr in
                    ExprSyntax(
                        InfixOperatorExprSyntax(
                            leftOperand: wrapInParensIfNeeded(expr),
                            operator: ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: .binaryOperator(
                                        "!=",
                                        leadingTrivia: .space,
                                        trailingTrivia: .space
                                    ))),
                            rightOperand: ExprSyntax(NilLiteralExprSyntax())
                        ))
                }

            case "XCTAssertEqual":
                return convertComparisonAssert(
                    args, operator: "==", originalNode: originalNode, context: context
                )

            case "XCTAssertNotEqual":
                return convertComparisonAssert(
                    args, operator: "!=", originalNode: originalNode, context: context
                )

            case "XCTFail":
                return convertXCTFail(args, originalNode: originalNode, context: context)

            case "XCTUnwrap":
                return convertXCTUnwrap(args, originalNode: originalNode, context: context)

            default: return nil
        }
    }

    private static func convertSingleValueAssert(
        _ args: [LabeledExprSyntax],
        originalNode: FunctionCallExprSyntax,
        context: Context,
        transform: (ExprSyntax) -> ExprSyntax
    ) -> ExprSyntax? {
        guard args.count == 1 || args.count == 2 else { return nil }
        guard args.allSatisfy({ $0.label == nil }) else { return nil }

        let value = transform(args[0].expression.trimmed)

        Self.diagnose(.convertAssertion, on: originalNode.calledExpression, context: context)

        var expectArgs = [LabeledExprSyntax]()

        if args.count == 2 {
            expectArgs.append(
                LabeledExprSyntax(
                    expression: value,
                    trailingComma: .commaToken(trailingTrivia: .space)
                ))
            expectArgs.append(LabeledExprSyntax(expression: args[1].expression.trimmed))
        } else {
            expectArgs.append(LabeledExprSyntax(expression: value))
        }

        return ExprSyntax(
            MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("expect"),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(expectArgs),
                rightParen: .rightParenToken()
            ))
    }

    private static func convertComparisonAssert(
        _ args: [LabeledExprSyntax],
        operator op: String,
        originalNode: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard args.count == 2 || args.count == 3 else { return nil }
        guard args.allSatisfy({ $0.label == nil }) else { return nil }

        let lhs = wrapInParensIfNeeded(args[0].expression.trimmed)
        let rhs = wrapInParensIfNeeded(args[1].expression.trimmed)

        Self.diagnose(.convertAssertion, on: originalNode.calledExpression, context: context)

        let comparison = ExprSyntax(
            InfixOperatorExprSyntax(
                leftOperand: lhs,
                operator: ExprSyntax(
                    BinaryOperatorExprSyntax(
                        operator: .binaryOperator(
                            op,
                            leadingTrivia: .space,
                            trailingTrivia: .space
                        ))),
                rightOperand: rhs
            ))

        var expectArgs = [LabeledExprSyntax]()

        if args.count == 3 {
            expectArgs.append(
                LabeledExprSyntax(
                    expression: comparison,
                    trailingComma: .commaToken(trailingTrivia: .space)
                ))
            expectArgs.append(LabeledExprSyntax(expression: args[2].expression.trimmed))
        } else {
            expectArgs.append(LabeledExprSyntax(expression: comparison))
        }

        return ExprSyntax(
            MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("expect"),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(expectArgs),
                rightParen: .rightParenToken()
            ))
    }

    private static func convertXCTFail(
        _ args: [LabeledExprSyntax],
        originalNode: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard args.count <= 1 else { return nil }

        Self.diagnose(.convertAssertion, on: originalNode.calledExpression, context: context)

        let issueRecord = MemberAccessExprSyntax(
            base: ExprSyntax(DeclReferenceExprSyntax(baseName: .identifier("Issue"))),
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier("record")))

        var callArgs = [LabeledExprSyntax]()
        if let msgArg = args.first {
            callArgs.append(LabeledExprSyntax(expression: msgArg.expression.trimmed))
        }

        return ExprSyntax(
            FunctionCallExprSyntax(
                calledExpression: ExprSyntax(issueRecord),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(callArgs),
                rightParen: .rightParenToken()
            ))
    }

    private static func convertXCTUnwrap(
        _ args: [LabeledExprSyntax],
        originalNode: FunctionCallExprSyntax,
        context: Context
    ) -> ExprSyntax? {
        guard args.count == 1 || args.count == 2 else { return nil }

        Self.diagnose(.convertAssertion, on: originalNode.calledExpression, context: context)

        var requireArgs = [LabeledExprSyntax]()

        if args.count == 2 {
            requireArgs.append(
                LabeledExprSyntax(
                    expression: args[0].expression.trimmed,
                    trailingComma: .commaToken(trailingTrivia: .space)
                ))
            requireArgs.append(LabeledExprSyntax(expression: args[1].expression.trimmed))
        } else {
            requireArgs.append(LabeledExprSyntax(expression: args[0].expression.trimmed))
        }

        return ExprSyntax(
            MacroExpansionExprSyntax(
                pound: .poundToken(),
                macroName: .identifier("require"),
                leftParen: .leftParenToken(),
                arguments: LabeledExprListSyntax(requireArgs),
                rightParen: .rightParenToken()
            ))
    }

    // MARK: - Compact-pipeline FunctionDecl transform

    /// Compact-pipeline counterpart of the legacy `visit(FunctionDeclSyntax)` override. State has
    /// been pushed in `willEnter(FunctionDeclSyntax)` and children already visited, so the
    /// conversion helpers operate on the post-traversal node directly (they take `visited` rather
    /// than calling `super.visit` ).
    static func transform(
        _ node: FunctionDeclSyntax,
        parent _: Syntax?,
        context: Context
    ) -> DeclSyntax {
        let state = context.preferSwiftTestingState
        guard state.hasXCTestImport, !state.bailOut, state.insideXCTestCase else {
            return DeclSyntax(node)
        }

        let name = node.name.text

        if name == "setUp" || name == "setUpWithError", node.modifiers.contains(.override) {
            return Self.convertSetUpStatic(node)
        }
        if name == "tearDown", node.modifiers.contains(.override) {
            return Self.convertTearDownStatic(node)
        }
        if name.hasPrefix("test"),
           node.signature.parameterClause.parameters.isEmpty,
           node.signature.returnClause == nil,
           !node.modifiers.contains(.static)
        {
            return Self.convertTestMethodStatic(node)
        }

        return DeclSyntax(node)
    }

    /// Static counterpart of `convertSetUp` . Operates on the already-visited node (no
    /// `super.visit` ); the legacy form's post-recursion logic is preserved.
    private static func convertSetUpStatic(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var result = node
        result.modifiers = result.modifiers.filter {
            $0.name.tokenKind != .keyword(.override)
        }

        if var body = result.body {
            body.statements = Self.removeSuperCall(
                from: body.statements, methodName: node.name.text)
            result.body = body
        }

        let initDecl = InitializerDeclSyntax(
            attributes: result.attributes,
            modifiers: result.modifiers,
            initKeyword: .keyword(
                .`init`,
                leadingTrivia: node.leadingTrivia,
                trailingTrivia: []),
            signature: result.signature,
            body: result.body)

        return DeclSyntax(initDecl)
    }

    private static func convertTearDownStatic(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var result = node
        result.modifiers = result.modifiers.filter {
            $0.name.tokenKind != .keyword(.override)
        }

        if var body = result.body {
            body.statements = Self.removeSuperCall(from: body.statements, methodName: "tearDown")
            result.body = body
        }

        let deinitDecl = DeinitializerDeclSyntax(
            attributes: result.attributes,
            modifiers: result.modifiers,
            deinitKeyword: .keyword(
                .deinit,
                leadingTrivia: node.leadingTrivia,
                trailingTrivia: result.body?.leftBrace.leadingTrivia ?? .space),
            body: result.body?.with(
                \.leftBrace,
                result.body!.leftBrace.with(\.leadingTrivia, .space)))

        return DeclSyntax(deinitDecl)
    }

    private static func convertTestMethodStatic(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let bodyHasTry = node.body?.statements.contains(where: { stmt in
            stmt.item.tokens(viewMode: .sourceAccurate).contains { $0.tokenKind == .keyword(.try) }
        }) ?? false

        let alreadyThrows = node.signature.effectSpecifiers?.throwsClause != nil

        var result = node

        let testAttr = AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier("Test")),
            trailingTrivia: .space)

        let funcTrivia = result.funcKeyword.leadingTrivia
        result.funcKeyword = result.funcKeyword.with(\.leadingTrivia, [])

        var attrList = [AttributeListSyntax.Element]()
        attrList.append(
            AttributeListSyntax.Element(
                testAttr.with(
                    \.atSign,
                    .atSignToken(leadingTrivia: funcTrivia)
                )))

        for attr in result.attributes { attrList.append(attr) }

        result.attributes = AttributeListSyntax(attrList)

        if bodyHasTry, !alreadyThrows { result = result.addingThrowsClause() }

        return DeclSyntax(result)
    }

    // MARK: - Unsupported pattern detection

    private static func hasUnsupportedPatterns(in node: SourceFileSyntax) -> Bool {
        let unsupportedIdentifiers: Set<String> = [
            "expectation", "wait", "measure", "measureMetrics", "addTeardownBlock",
            "continueAfterFailure", "executionTimeAllowance", "startMeasuring",
            "stopMeasuring", "fulfillment", "XCUIApplication",
        ]

        for token in node.tokens(viewMode: .sourceAccurate) {
            if case let .identifier(text) = token.tokenKind {
                if unsupportedIdentifiers.contains(text) { return true }
            }
        }

        for stmt in node.statements {
            if let classDecl = stmt.item.as(ClassDeclSyntax.self) {
                for member in classDecl.memberBlock.members {
                    if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
                       funcDecl.name.text == "tearDown",
                       funcDecl.modifiers.contains(.override)
                    {
                        let effects = funcDecl.signature.effectSpecifiers
                        if effects?.asyncSpecifier != nil || effects?.throwsClause != nil {
                            return true
                        }
                    }

                    if let funcDecl = member.decl.as(FunctionDeclSyntax.self),
                       funcDecl.modifiers.contains(.override)
                    {
                        let name = funcDecl.name.text
                        let supported = ["setUp", "setUpWithError", "tearDown"]
                        if !supported.contains(name) { return true }
                    }
                }
            }
        }

        for token in node.tokens(viewMode: .sourceAccurate) {
            if case let .identifier(text) = token.tokenKind {
                if text == "StaticString" {
                    if let prev = token.previousToken(viewMode: .sourceAccurate),
                       prev.tokenKind == .colon,
                       let prevPrev = prev.previousToken(viewMode: .sourceAccurate),
                       prevPrev.text == "file"
                    {
                        return true
                    }
                }
            }
        }

        return false
    }

    // MARK: - Helpers

    private static func removeSuperCall(
        from statements: CodeBlockItemListSyntax,
        methodName: String
    ) -> CodeBlockItemListSyntax {
        var items = Array(statements)
        items.removeAll { item in
            guard let call = extractFunctionCall(from: item.item) else { return false }
            let callText = call.calledExpression.trimmedDescription
            return callText == "super.\(methodName)" || callText == "super.setUp"
        }
        return CodeBlockItemListSyntax(items)
    }

    private static func extractFunctionCall(
        from item: CodeBlockItemSyntax.Item
    ) -> FunctionCallExprSyntax? {
        func unwrapToCall(_ expr: ExprSyntax) -> FunctionCallExprSyntax? {
            if let call = expr.as(FunctionCallExprSyntax.self) {
                call
            } else if let tryExpr = expr.as(TryExprSyntax.self) {
                unwrapToCall(tryExpr.expression)
            } else if let awaitExpr = expr.as(AwaitExprSyntax.self) {
                unwrapToCall(awaitExpr.expression)
            } else {
                nil
            }
        }

        if let call = item.as(FunctionCallExprSyntax.self) { return call }
        if let tryExpr = item.as(TryExprSyntax.self) { return unwrapToCall(tryExpr.expression) }
        if let awaitExpr = item.as(AwaitExprSyntax.self) {
            return unwrapToCall(awaitExpr.expression)
        }
        return nil
    }

    private static func wrapInParensIfNeeded(_ expr: ExprSyntax) -> ExprSyntax {
        expr.is(InfixOperatorExprSyntax.self)
            || expr.is(IsExprSyntax.self)
            || expr.is(TryExprSyntax.self)
            ? ExprSyntax(
                TupleExprSyntax(
                    leftParen: .leftParenToken(),
                    elements: LabeledExprListSyntax([
                        LabeledExprSyntax(expression: expr)
                    ]),
                    rightParen: .rightParenToken()
                ))
            : expr
    }
}

fileprivate extension Finding.Message {
    static let replaceImport: Finding.Message = "replace 'import XCTest' with 'import Testing'"
    static let removeConformance: Finding.Message = "remove 'XCTestCase' conformance"
    static let convertSetUp: Finding.Message = "convert 'setUp' to 'init'"
    static let convertTearDown: Finding.Message = "convert 'tearDown' to 'deinit'"
    static let addTestAttribute: Finding.Message = "add '@Test' attribute to test method"
    static let convertAssertion: Finding.Message = "convert XCTest assertion to Swift Testing"
}
