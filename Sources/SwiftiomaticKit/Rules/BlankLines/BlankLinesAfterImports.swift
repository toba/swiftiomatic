import SwiftSyntax

/// Insert a blank line after the last import statement.
///
/// When import statements are followed directly by other declarations without a separating blank
/// line, readability suffers. This rule ensures exactly one blank line separates the import block
/// from the rest of the code.
///
/// Lint: If the first non-import declaration is not preceded by a blank line, a lint warning is raised.
///
/// Format: A blank line is inserted after the last import statement.
final class BlankLinesAfterImports: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override static var key: String { "afterImports" }
    override static var group: ConfigurationGroup? { .blankLines }

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let statements = Array(node.statements)
        guard let lastImportIndex = findLastImportIndex(in: statements) else { return node }

        // Check there's a statement after the last import.
        let nextIndex = lastImportIndex + 1
        guard nextIndex < statements.count else { return node }

        let nextStatement = statements[nextIndex]

        // Count newlines in the leading trivia of the next statement.
        // We need at least 2 newlines (end of import line + blank line).
        let newlineCount = nextStatement.leadingTrivia.pieces.reduce(0) { count, piece in
            switch piece {
                case .newlines(let n): count + n
                default: count
            }
        }

        guard newlineCount < 2 else { return node }

        diagnose(.insertBlankLineAfterImports, on: nextStatement)

        // Add an extra newline to the leading trivia of the next statement.
        var modifiedStatements = statements
        var modifiedNext = nextStatement
        modifiedNext.leadingTrivia = .newline + nextStatement.leadingTrivia
        modifiedStatements[nextIndex] = modifiedNext

        var result = node
        result.statements = CodeBlockItemListSyntax(modifiedStatements)
        return result
    }

    /// Find the index of the last import-related statement (import decl or `#if` block containing
    /// only imports) at the top of the file.
    private func findLastImportIndex(in statements: [CodeBlockItemSyntax]) -> Int? {
        var lastImportIndex: Int?

        for (index, statement) in statements.enumerated() {
            if statement.item.is(ImportDeclSyntax.self) {
                lastImportIndex = index
            } else if let ifConfig = statement.item.as(IfConfigDeclSyntax.self),
                containsOnlyImports(ifConfig)
            {
                lastImportIndex = index
            } else {
                // Stop at the first non-import statement. Imports after code are handled by
                // SortImports.
                break
            }
        }

        return lastImportIndex
    }

    /// Check if an `#if` configuration block contains only import statements.
    private func containsOnlyImports(_ ifConfig: IfConfigDeclSyntax) -> Bool {
        for clause in ifConfig.clauses {
            guard case .statements(let stmts) = clause.elements else { continue }

            for stmt in stmts {
                if !stmt.item.is(ImportDeclSyntax.self) { return false }
            }
        }
        return true
    }
}

extension Finding.Message {
    fileprivate static let insertBlankLineAfterImports: Finding.Message =
        "insert blank line after import statements"
}
