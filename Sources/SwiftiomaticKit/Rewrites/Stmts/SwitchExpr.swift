import SwiftSyntax

/// Compact-pipeline merge of all `SwitchExprSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)`.
///
/// Per Phase 4d of `ddi-wtv` (sub-issue `zvf-rsq`). The generator emits a
/// thin override that delegates to this function — see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`.
///
/// No node-local rules currently target `SwitchExprSyntax` via the compact
/// `transform` form. The unported entries below are tracked in 4f.
func rewriteSwitchExpr(
    _ node: SwitchExprSyntax,
    context: Context
) -> SwitchExprSyntax {
    var result = node
    let nodeSyntax = Syntax(result)
    _ = nodeSyntax

    // BlankLinesAfterSwitchCase — inserts a blank line after multiline cases
    // and removes the blank line before the closing brace. Inlined from
    // `Sources/SwiftiomaticKit/Rules/BlankLines/BlankLinesAfterSwitchCase.swift`.
    if context.shouldFormat(BlankLinesAfterSwitchCase.self, node: Syntax(result)) {
        result = applyBlankLinesAfterSwitchCase(result, context: context)
    }

    // NoParensAroundConditions — unported (legacy `SyntaxFormatRule.visit`
    // override across multiple statement node types). Audit-only;
    // deferred to 4f.
    _ = context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result))

    // SwitchCaseIndentation — unported (legacy `SyntaxFormatRule.visit`
    // override; indentation logic not yet migrated to a static
    // `transform`). Audit-only; deferred to 4f.
    _ = context.shouldFormat(SwitchCaseIndentation.self, node: Syntax(result))

    // WrapMultilineStatementBraces — unported (same reasons as above).
    // Audit-only; deferred to 4f.
    _ = context.shouldFormat(WrapMultilineStatementBraces.self, node: Syntax(result))

    return result
}

private func applyBlankLinesAfterSwitchCase(
    _ node: SwitchExprSyntax,
    context: Context
) -> SwitchExprSyntax {
    var switchExpr = node
    let cases = Array(switchExpr.cases)
    guard !cases.isEmpty else { return node }

    var modifiedCases = cases
    var modified = false

    for i in 0..<(cases.count - 1) {
        guard case .switchCase(let switchCase) = cases[i],
              switchCase.statements.count > 1
        else { continue }

        let nextIndex = i + 1
        guard !cases[nextIndex].leadingTrivia.hasBlankLine else { continue }

        BlankLinesAfterSwitchCase.diagnose(
            .insertBlankLineAfterCase,
            on: switchCase.label,
            context: context
        )
        modifiedCases[nextIndex] = modifiedCases[nextIndex].prependingNewline()
        modified = true
    }

    if modified { switchExpr.cases = SwitchCaseListSyntax(modifiedCases) }

    if switchExpr.rightBrace.leadingTrivia.hasBlankLine {
        BlankLinesAfterSwitchCase.diagnose(
            .removeBlankLineBeforeClosingBrace,
            on: switchExpr.rightBrace,
            context: context
        )
        switchExpr.rightBrace = switchExpr.rightBrace.with(
            \.leadingTrivia,
            switchExpr.rightBrace.leadingTrivia.reducingToSingleNewlines
        )
        modified = true
    }

    return modified ? switchExpr : node
}

extension Finding.Message {
    fileprivate static let insertBlankLineAfterCase: Finding.Message =
        "insert blank line after multiline switch case"

    fileprivate static let removeBlankLineBeforeClosingBrace: Finding.Message =
        "remove blank line before closing brace"
}
