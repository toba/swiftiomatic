import SwiftSyntax

/// Comma-delimited switch case items are wrapped onto separate lines.
///
/// Switch cases with multiple patterns separated by commas are expanded so each
/// pattern appears on its own line, aligned after `case `.
///
/// Lint: A switch case with multiple comma-separated items on a single line
///       raises a warning.
///
/// Format: Each item is placed on its own line with alignment indentation.
final class WrapCompoundCaseStatements: SyntaxFormatRule {
    //    static let name = "wrapCompoundCaseStatements"
    static let group: ConfigGroup? = .wrap
    static let defaultHandling: RuleHandling = .off

    override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
        let items = node.caseItems
        guard items.count > 1 else { return node }

        // Check if any items need wrapping (items after first on same line as comma)
        var needsWrapping = false
        for item in items {
            guard item.trailingComma != nil else { continue }
            // If the next item doesn't start on a new line, we need to wrap
            if let nextToken = item.trailingComma?.nextToken(viewMode: .sourceAccurate),
                !nextToken.leadingTrivia.containsNewlines
            {
                needsWrapping = true
                break
            }
        }

        guard needsWrapping else { return node }

        diagnose(.wrapSwitchCase, on: node.caseKeyword)

        let alignIndent =
            node.caseKeyword.leadingTrivia.indentation
            + String(repeating: " ", count: "case ".count)

        var newItems = [SwitchCaseItemSyntax]()
        for (index, item) in items.enumerated() {
            var modified = item
            if index > 0 {
                modified.leadingTrivia = .newline + Trivia(stringLiteral: alignIndent)
            }
            if let comma = modified.trailingComma {
                modified.trailingComma = comma.with(\.trailingTrivia, [])
            }
            newItems.append(modified)
        }

        var result = node
        result.caseItems = SwitchCaseItemListSyntax(newItems)
        return result
    }
}

extension Finding.Message {
    fileprivate static let wrapSwitchCase: Finding.Message =
        "wrap comma-delimited switch case items onto separate lines"
}
