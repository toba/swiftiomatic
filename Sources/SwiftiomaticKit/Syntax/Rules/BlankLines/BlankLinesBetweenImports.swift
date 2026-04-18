import SwiftSyntax

/// Remove blank lines between consecutive import statements.
///
/// Import blocks should be compact — blank lines within the import section add visual noise
/// without aiding readability. This rule removes them while preserving linebreaks.
///
/// Lint: If there are blank lines between consecutive import statements, a lint warning is raised.
///
/// Format: The blank lines are removed.
final class BlankLinesBetweenImports: SyntaxFormatRule {
    static let group: ConfigGroup? = .blankLines

    static let defaultHandling: RuleHandling = .off

    override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
        let originalStatements = Array(node.statements)
        var statements = originalStatements
        var modified = false

        for i in 0..<originalStatements.count {
            guard originalStatements[i].item.is(ImportDeclSyntax.self) else { continue }

            let nextIndex = i + 1
            guard nextIndex < originalStatements.count,
                originalStatements[nextIndex].item.is(ImportDeclSyntax.self)
            else { continue }

            let nextStmt = originalStatements[nextIndex]
            guard nextStmt.leadingTrivia.hasBlankLine else { continue }

            diagnose(.removeBlankLineBetweenImports, on: nextStmt.item)
            var modifiedNext = nextStmt
            modifiedNext.leadingTrivia = nextStmt.leadingTrivia.replacingFirstNewlines(with: 1)
            statements[nextIndex] = modifiedNext
            modified = true
        }

        guard modified else { return node }
        var result = node
        result.statements = CodeBlockItemListSyntax(statements)
        return result
    }
}

extension Finding.Message {
    fileprivate static let removeBlankLineBetweenImports: Finding.Message =
        "remove blank line between import statements"
}
