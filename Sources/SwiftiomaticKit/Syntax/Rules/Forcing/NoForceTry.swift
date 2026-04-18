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
/// Format: In test functions, `try!` is replaced with `try` and `throws` is added.
final class NoForceTry: SyntaxFormatRule {
    static let group: ConfigGroup? = .forcing
    static let defaultHandling: RuleHandling = .off

    private var testContext = TestContextTracker()
    private var insideTestFunction = false
    private var convertedForceTry = false

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        testContext.visitImport(node)
        return DeclSyntax(node)
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

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        guard node.body != nil else {
            return DeclSyntax(node)
        }

        // Non-test functions: don't recurse (blocks nested function try! conversion)
        guard testContext.isTestFunction(node) else {
            return DeclSyntax(node)
        }

        let wasInsideTest = insideTestFunction
        insideTestFunction = true
        convertedForceTry = false
        defer { insideTestFunction = wasInsideTest }

        let visited = super.visit(node)
        guard var result = visited.as(FunctionDeclSyntax.self) else { return visited }

        guard convertedForceTry else {
            return DeclSyntax(result)
        }

        if result.signature.effectSpecifiers?.throwsClause == nil {
            result = result.addingThrowsClause()
        }

        return DeclSyntax(result)
    }

    override func visit(_ node: TryExprSyntax) -> ExprSyntax {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else {
            return super.visit(node)
        }

        // Non-test code: diagnose only (no rewriting)
        guard insideTestFunction else {
            diagnose(.doNotForceTry, on: node.tryKeyword)
            return ExprSyntax(node)
        }

        diagnose(.replaceForceTry, on: node.tryKeyword)
        convertedForceTry = true

        let visited = super.visit(node)
        guard let tryNode = visited.as(TryExprSyntax.self) else { return visited }
        // Transfer the ! token's trailing trivia (usually a space) to the try keyword
        let bangTrailingTrivia = tryNode.questionOrExclamationMark?.trailingTrivia ?? .space
        return ExprSyntax(
            tryNode
                .with(\.questionOrExclamationMark, nil)
                .with(\.tryKeyword, tryNode.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
        )
    }

    // Don't recurse into closures — try! inside closures can't be fixed by making
    // the outer function throw.
    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        ExprSyntax(node)
    }

}

extension Finding.Message {
    fileprivate static let doNotForceTry: Finding.Message = "do not use force try"
    fileprivate static let replaceForceTry: Finding.Message =
        "replace 'try!' with 'try' in test function; use 'throws' on the test method instead"
}
