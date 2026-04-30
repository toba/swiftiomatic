import SwiftSyntax

/// Single-return `if` statements followed by a final `return` should be expressed as an
/// `if/else` expression.
///
/// When one or more `if` statements each contain only a `return` and are followed by a trailing
/// `return` , the sequence is converted into a single `if/else if/.../else` expression.
///
/// ```swift
/// // Before
/// if case .spaces = $0 { return true }
/// if case .tabs = $0 { return true }
/// return false
///
/// // After
/// if case .spaces = $0 {
///     true
/// } else if case .tabs = $0 {
///     true
/// } else {
///     false
/// }
/// ```
///
/// Lint: A chain of early-return `if` statements raises a warning.
///
/// Rewrite: The chain is replaced with an `if/else` expression.
final class PreferIfElseChain: StaticFormatRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .conditions }

    static func transform(
        _ visited: CodeBlockItemListSyntax,
        parent: Syntax?,
        context: Context
    ) -> CodeBlockItemListSyntax {
        // The rewrite turns explicit `return` statements into bare-expression branches of an
        // if-expression. That only preserves semantics when the expression's value is the implicit
        // return of the enclosing scope, which requires (1) the chain occupies the entire item list and
        // (2) the list is the body of a single-expression function/closure/accessor.
        guard parentAllowsImplicitReturn(visited) else { return visited }

        let items = Array(visited)
        guard let chain = tryBuildChain(items: items, startingAt: 0),
              chain.endIndex == items.count else { return visited }

        Self.diagnose(.useIfElseChain, on: chain.firstIf, context: context)
        return CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                leadingTrivia: items[0].leadingTrivia,
                item: .expr(ExprSyntax(chain.ifExpr)),
                trailingTrivia: items[chain.endIndex - 1].trailingTrivia
            )
        ])
    }

    /// Whether the items list sits in a position where a trailing bare expression becomes the
    /// enclosing scope's implicit return value.
    private static func parentAllowsImplicitReturn(_ list: CodeBlockItemListSyntax) -> Bool {
        guard let parent = list.parent else { return false }

        // Closure body, computed-property accessor block, and top-level scripts host the items list
        // directly.
        if parent.is(ClosureExprSyntax.self) { return true }
        if parent.is(AccessorBlockSyntax.self) { return true }
        if parent.is(SourceFileSyntax.self) { return true }

        // Switch cases require explicit `return` to leave the enclosing function.
        if parent.is(SwitchCaseSyntax.self) { return false }

        // Otherwise the list is wrapped in a CodeBlockSyntax. Function and accessor bodies allow
        // implicit return; do/for/while/if/guard/defer/catch do not.
        guard let codeBlock = parent.as(CodeBlockSyntax.self),
              let grandparent = codeBlock.parent else { return false }

        if grandparent.is(FunctionDeclSyntax.self) { return true }
        if grandparent.is(AccessorDeclSyntax.self) { return true }
        return false
    }

    // MARK: - Chain detection

    private struct Chain {
        let ifExpr: IfExprSyntax
        let firstIf: IfExprSyntax
        /// Index past the last consumed item (exclusive).
        let endIndex: Int
    }

    /// Tries to build a chain starting at `startIndex` . Requires at least one `if` statement (each
    /// with a single `return` body and no `else` ) followed by a trailing `return` statement.
    private static func tryBuildChain(
        items: [CodeBlockItemSyntax],
        startingAt startIndex: Int
    ) -> Chain? {
        var ifBranches:
            [(conditions: ConditionElementListSyntax, value: ExprSyntax, leading: Trivia)] = []
        var j = startIndex

        // Collect consecutive single-return if statements without else.
        while j < items.count {
            guard let ifStmt = extractIfStatement(from: items[j]),
                  ifStmt.elseBody == nil,
                  let returnValue = singleReturnValue(from: ifStmt.body) else { break }
            ifBranches.append((ifStmt.conditions, returnValue, ifStmt.ifKeyword.leadingTrivia))
            j += 1
        }

        guard ifBranches.count >= 1 else { return nil }

        // The next item must be a trailing return statement.
        guard j < items.count, let fallbackValue = extractReturnValue(from: items[j])
        else { return nil }

        let endIndex = j + 1

        // Build the if/else chain from the bottom up. Start with the else block (the fallback return
        // value).
        let elseBlock = CodeBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space, trailingTrivia: .newline),
            statements: CodeBlockItemListSyntax([
                CodeBlockItemSyntax(
                    leadingTrivia: .spaces(2),
                    item: .expr(fallbackValue.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
                    trailingTrivia: .newline
                )
            ]),
            rightBrace: .rightBraceToken()
        )

        // Build from last if-branch backward.
        var currentElse: IfExprSyntax.ElseBody = .codeBlock(elseBlock)

        for i in stride(from: ifBranches.count - 1, through: 0, by: -1) {
            let branch = ifBranches[i]

            let body = CodeBlockSyntax(
                leftBrace: .leftBraceToken(trailingTrivia: .newline),
                statements: CodeBlockItemListSyntax([
                    CodeBlockItemSyntax(
                        leadingTrivia: .spaces(2),
                        item: .expr(
                            branch.value.with(\.leadingTrivia, []).with(\.trailingTrivia, [])),
                        trailingTrivia: .newline
                    )
                ]),
                rightBrace: .rightBraceToken()
            )

            let isFirst = i == 0
            let ifKeyword:
                TokenSyntax = isFirst
                    ? .keyword(.if, trailingTrivia: .space)
                    : .keyword(.if, leadingTrivia: .space, trailingTrivia: .space)

            let ifExpr = IfExprSyntax(
                ifKeyword: ifKeyword,
                conditions: branch.conditions,
                body: body,
                elseKeyword: .keyword(.else, leadingTrivia: .space),
                elseBody: currentElse
            )

            if !isFirst {
                currentElse = .ifExpr(ifExpr)
            } else {
                // Extract the first if for the finding location.
                let firstIf = extractIfStatement(from: items[startIndex])!
                return Chain(ifExpr: ifExpr, firstIf: firstIf, endIndex: endIndex)
            }
        }

        return nil  // unreachable
    }

    // MARK: - Helpers

    private static func extractIfStatement(from item: CodeBlockItemSyntax) -> IfExprSyntax? {
        if let exprStmt = item.item.as(ExpressionStmtSyntax.self) {
            return exprStmt.expression.as(IfExprSyntax.self)
        }
        return item.item.as(ExprSyntax.self)?.as(IfExprSyntax.self)
    }

    /// Returns the single return value from an if body, or nil if the body isn't a single return
    /// statement.
    private static func singleReturnValue(from body: CodeBlockSyntax) -> ExprSyntax? {
        guard let onlyItem = body.statements.firstAndOnly else { return nil }

        if let returnStmt = onlyItem.item.as(ReturnStmtSyntax.self) { return returnStmt.expression }
        if let stmtItem = onlyItem.item.as(StmtSyntax.self),
           let returnStmt = ReturnStmtSyntax(stmtItem)
        {
            return returnStmt.expression
        }
        return nil
    }

    /// Extracts the return value from a standalone return statement.
    private static func extractReturnValue(from item: CodeBlockItemSyntax) -> ExprSyntax? {
        if let returnStmt = item.item.as(ReturnStmtSyntax.self) {
            returnStmt.expression
        } else if let stmtItem = item.item.as(StmtSyntax.self),
           let returnStmt = ReturnStmtSyntax(stmtItem)
        {
            returnStmt.expression
        } else {
            nil
        }
    }
}

fileprivate extension Finding.Message {
    static let useIfElseChain: Finding.Message =
        "replace early-return chain with if/else expression"
}
