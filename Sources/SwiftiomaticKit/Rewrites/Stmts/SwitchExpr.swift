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
    parent: Syntax?,
    context: Context
) -> SwitchExprSyntax {
    var result = node
    // BlankLinesAfterSwitchCase — inserts a blank line after multiline cases
    // and removes the blank line before the closing brace. Inlined from
    // `Sources/SwiftiomaticKit/Rules/BlankLines/BlankLinesAfterSwitchCase.swift`.
    if context.shouldFormat(BlankLinesAfterSwitchCase.self, node: Syntax(result)) {
        result = applyBlankLinesAfterSwitchCase(result, context: context)
    }

    // NoParensAroundConditions — strips parens around the `switch` subject
    // and ensures `switch` keyword has a trailing space. Helpers in
    // `NoParensAroundConditionsHelpers.swift`.
    if context.shouldFormat(NoParensAroundConditions.self, node: Syntax(result)) {
        if let stripped = noParensMinimalSingleExpression(result.subject, context: context) {
            result.subject = stripped
            noParensFixKeywordTrailingTrivia(&result.switchKeyword.trailingTrivia)
        }
    }

    // SwitchCaseIndentation — reindents `case` labels and bodies to the
    // configured style (`flush` aligns with `switch`; `indented` indents one
    // level). Inlined from
    // `Sources/SwiftiomaticKit/Rules/Indentation/SwitchCaseIndentation.swift`.
    if context.shouldFormat(SwitchCaseIndentation.self, node: Syntax(result)) {
        result = applySwitchCaseIndentation(result, context: context)
    }

    // WrapMultilineStatementBraces — wrap opening brace of a multiline
    // statement onto its own line aligned with the closing brace.
    applyRule(
        WrapMultilineStatementBraces.self, to: &result,
        parent: parent, context: context,
        transform: WrapMultilineStatementBraces.transform
    )

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

    fileprivate static let alignCaseWithSwitch: Finding.Message =
        "align 'case' with 'switch' keyword"

    fileprivate static let indentCaseFromSwitch: Finding.Message =
        "indent 'case' one level from 'switch' keyword"
}

private func applySwitchCaseIndentation(
    _ node: SwitchExprSyntax,
    context: Context
) -> SwitchExprSyntax {
    var switchExpr = node
    let style = context.configuration[SwitchCaseIndentation.self].style
    let switchIndent = lineIndentation(of: switchExpr.switchKeyword)
    let indent: String =
        switch context.configuration[IndentationSetting.self] {
            case .spaces(let count): String(repeating: " ", count: count)
            case .tabs(let count): String(repeating: "\t", count: count)
        }

    let expectedCaseIndent: String
    let expectedBodyIndent: String

    switch style {
        case .flush:
            expectedCaseIndent = switchIndent
            expectedBodyIndent = switchIndent + indent
        case .indented:
            expectedCaseIndent = switchIndent + indent
            expectedBodyIndent = switchIndent + indent + indent
    }

    let cases = Array(switchExpr.cases)
    guard !cases.isEmpty else { return node }

    var modifiedCases = cases
    var modified = false

    for i in 0..<cases.count {
        switch cases[i] {
            case .switchCase(var switchCase):
                let currentCaseIndent = switchCase.leadingTrivia.indentation

                if currentCaseIndent != expectedCaseIndent {
                    // Diagnose emitted in willEnter against the pre-traversal node.
                    switchCase = reindentCase(
                        switchCase,
                        caseIndent: expectedCaseIndent,
                        bodyIndent: expectedBodyIndent
                    )
                    modifiedCases[i] = .switchCase(switchCase)
                    modified = true
                }

            case .ifConfigDecl: break
        }
    }

    if modified { switchExpr.cases = SwitchCaseListSyntax(modifiedCases) }

    let braceIndent = switchExpr.rightBrace.leadingTrivia.indentation
    if braceIndent != switchIndent {
        switchExpr.rightBrace = switchExpr.rightBrace.with(
            \.leadingTrivia,
            replaceIndentation(in: switchExpr.rightBrace.leadingTrivia, with: switchIndent)
        )
        modified = true
    }

    return modified ? switchExpr : node
}

private func reindentCase(
    _ switchCase: SwitchCaseSyntax,
    caseIndent: String,
    bodyIndent: String
) -> SwitchCaseSyntax {
    var result = switchCase

    result = result.with(
        \.leadingTrivia,
        replaceIndentation(in: switchCase.leadingTrivia, with: caseIndent)
    )

    let stmts = Array(result.statements)
    var modifiedStmts = stmts
    for j in 0..<stmts.count {
        let stmt = stmts[j]
        modifiedStmts[j] = stmt.with(
            \.leadingTrivia,
            replaceIndentation(in: stmt.leadingTrivia, with: bodyIndent)
        )
    }
    result.statements = CodeBlockItemListSyntax(modifiedStmts)
    return result
}

private func replaceIndentation(in trivia: Trivia, with indent: String) -> Trivia {
    var pieces = Array(trivia.pieces)

    if let lastNewlineIndex = pieces.lastIndex(where: {
        if case .newlines = $0 { return true }
        if case .carriageReturns = $0 { return true }
        if case .carriageReturnLineFeeds = $0 { return true }
        return false
    }) {
        let afterNewline = lastNewlineIndex + 1
        while afterNewline < pieces.count {
            switch pieces[afterNewline] {
                case .spaces, .tabs: pieces.remove(at: afterNewline)
                default: break
            }
            if afterNewline < pieces.count {
                switch pieces[afterNewline] {
                    case .spaces, .tabs: continue
                    default: break
                }
            }
            break
        }
        if !indent.isEmpty {
            pieces.insert(.spaces(indent.count), at: afterNewline)
        }
    }

    return Trivia(pieces: pieces)
}

private func lineIndentation(of token: TokenSyntax) -> String {
    var current = token
    while !current.leadingTrivia.containsNewlines {
        guard let prev = current.previousToken(viewMode: .sourceAccurate) else { return "" }
        current = prev
    }
    return current.leadingTrivia.indentation
}
