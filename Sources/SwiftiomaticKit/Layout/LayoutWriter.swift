import SwiftSyntax

// sm:ignore-file: fileLength, functionBodyLength

/// Compact-pipeline merge of all `TokenSyntax` rewrites. Each former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)` so users can still toggle individual behaviors via
/// configuration (the rule-name strings survive as configuration keys).
///
/// Per Phase 4b of `ddi-wtv` (sub-issue `95z-bgr` ), this replaces the per-rule
/// `StructuralFormatRule.visit(_ TokenSyntax)` overrides + the `static func transform` chain that
/// `CompactSyntaxRewriter` would otherwise generate for `TokenSyntax` . The generator's
/// `manuallyHandledNodeTypes` includes `TokenSyntax` , and the emitted `visit(_ TokenSyntax)`
/// override delegates to this free function.
///
/// Rule order is alphabetical by rule name. The token has already been post-traversed by
/// `super.visit` — its children (none, for a leaf token) are already done. Helpers used during
/// these rewrites live as `static` members on the original rule types and are forwarded to from
/// here.
///
/// Some rules from the merge list don't actually have token-level visits — their `visit` overrides
/// target structural nodes (e.g. `FunctionCallExprSyntax` , `IfExprSyntax` ). Those rules are noted
/// in comments so the audit is explicit but no work is done at the token level for them; their
/// structural-node merges happen in Phase 4c/4d/4e.
func rewriteToken(
    _ node: TokenSyntax,
    parent _: Syntax?,
    context: Context
) -> TokenSyntax {
    var result = node
    let parent = Syntax(node).parent

    // 1. BlankLinesAroundMark — inlined (no `static func transform` ). Adds blank lines
    //    before/after `// MARK:` comments in the token's leading trivia. Token-level: looks at
    //    leadingTrivia + previous/next token kind only.
    if context.shouldRewrite(BlankLinesAroundMark.self, at: Syntax(result)) {
        result = applyBlankLinesAroundMark(result, context: context)
    }

    // 2. FormatSpecialComments — ported. Normalizes TODO/MARK/FIXME comment formatting in leading
    //    and trailing trivia.
    if context.shouldRewrite(FormatSpecialComments.self, at: Syntax(result)) {
        result = FormatSpecialComments.transform(result, parent: parent, context: context)
    }

    // 3. LeadingDotOperators — ported. Uses a typed property on `Context` to thread pending trivia
    //    between adjacent token visits. The static transform already handles the state plumbing
    //    correctly.
    if context.shouldRewrite(LeadingDotOperators.self, at: Syntax(result)) {
        result = LeadingDotOperators.transform(result, parent: parent, context: context)
    }

    // 4. NestedCallLayout — NOT a token-level rewrite. The rule's `visit` overrides target
    //    `FunctionCallExprSyntax` . The only `visit(_ TokenSyntax)` in that file is on a private
    //    `IndentShiftRewriter` helper used internally by the rule, which the compact pipeline
    //    doesn't reach via this entry point. No-op here, kept for the merge audit. Phase 4c/4d/4e
    //    will port the FunctionCallExprSyntax visit.
    _ = context.shouldRewrite(NestedCallLayout.self, at: Syntax(result))

    // 5. RedundantBackticks — ported. Strips redundant backticks from identifier tokens. Uses
    //    captured pre-recursion parent for context analysis (member access, argument label, etc.).
    if context.shouldRewrite(RedundantBackticks.self, at: Syntax(result)) {
        result = RedundantBackticks.transform(result, parent: parent, context: context)
    }

    // 5a. ReflowComments — inlined (no `static func transform` ). Reflows contiguous `//` and `///`
    // comment runs in leading trivia to fit `lineLength` .
    if context.shouldRewrite(ReflowComments.self, at: Syntax(result)) {
        result = ReflowComments.reflow(result, context: context)
    }

    // 6. UppercaseAcronyms — inlined (no `static func transform` ). Replaces titlecased acronyms (
    //    `Url` , `Json` ) with fully uppercased forms ( `URL` , `JSON` ) inside identifier tokens.
    //    Pulls the configurable word list from `AcronymsConfiguration` .
    if context.shouldRewrite(UppercaseAcronyms.self, at: Syntax(result)) {
        result = applyUppercaseAcronyms(result, context: context)
    }

    // 7. WrapMultilineFunctionChains — NOT a token-level rewrite; the rule operates on
    //    `FunctionCallExprSyntax` (see
    //    `Rewrites/Exprs/FunctionCallExpr.swift::applyWrapMultilineFunctionChains` ).
    // 8. WrapMultilineStatementBraces — NOT a token-level rewrite. The rule's `visit` overrides
    //    target many statement / decl nodes (IfExprSyntax, GuardStmtSyntax, FunctionDeclSyntax,
    //    ClassDeclSyntax, …). The private `TokenStripper` is an internal helper. No-op here; the
    //    structural merges happen in Phase 4c/4d/4e.
    _ = context.shouldRewrite(WrapMultilineStatementBraces.self, at: Syntax(result))

    // 9. WrapSingleLineComments — ported. Word-wraps over-long `//` and `///` comments in leading
    //    trivia. Run AFTER FormatSpecialComments so directive detection (TODO/MARK/FIXME) sees
    //    normalized prefixes, matching the legacy pipeline's alphabetical ordering coincidence (
    //    `Format…` < `Wrap…` ).
    if context.shouldRewrite(WrapSingleLineComments.self, at: Syntax(result)) {
        result = WrapSingleLineComments.transform(result, parent: parent, context: context)
    }

    return result
}

// MARK: - BlankLinesAroundMark (inlined)
//
// The original rule has no `static func transform`. Inlined verbatim from
// `BlankLinesAroundMark.visit(_ TokenSyntax)` — only the leading-trivia /
// neighbor-token logic. The `Finding.Message` extensions in the rule file
// are `fileprivate`, so the message strings are duplicated locally.

fileprivate extension Finding.Message {
    static let insertBlankLineBeforeMark: Finding.Message = "insert blank line before MARK comment"

    static let insertBlankLineAfterMark: Finding.Message = "insert blank line after MARK comment"
}

private func applyBlankLinesAroundMark(
    _ token: TokenSyntax,
    context: Context
) -> TokenSyntax {
    // Cheap precheck on the original Trivia to avoid materialising a `[TriviaPiece]`
    // for the common case where this token has no `// MARK:` comment.
    guard token.leadingTrivia.pieces.contains(where: isMarkComment) else { return token }

    var pieces = Array(token.leadingTrivia.pieces)
    guard let markIndex = pieces.firstIndex(where: isMarkComment) else { return token }

    var changed = false

    // Add blank line BEFORE MARK — skip at start of scope (after `{` ).
    let prevToken = token.previousToken(viewMode: .sourceAccurate)
    let isAtStartOfScope = prevToken?.tokenKind == .leftBrace

    if !isAtStartOfScope, let idx = findNewlinesAroundMark(markIndex, in: pieces, before: true) {
        if case let .newlines(n) = pieces[idx], n < 2 {
            BlankLinesAroundMark.diagnose(
                .insertBlankLineBeforeMark,
                on: token,
                context: context,
                anchor: .leadingTrivia(markIndex)
            )
            pieces[idx] = .newlines(n + 1)
            changed = true
        }
    }

    // Add blank line AFTER MARK — skip at end of scope (before `}` ) or end of file.
    let isAtEndOfScope = token.tokenKind == .rightBrace
    let isAtEndOfFile = token.tokenKind == .endOfFile

    if !isAtEndOfScope, !isAtEndOfFile {
        if let idx = findNewlinesAroundMark(markIndex, in: pieces, before: false) {
            if case let .newlines(n) = pieces[idx], n < 2 {
                BlankLinesAroundMark.diagnose(
                    .insertBlankLineAfterMark,
                    on: token,
                    context: context
                )
                pieces[idx] = .newlines(n + 1)
                changed = true
            }
        }
    }

    guard changed else { return token }
    return token.with(\.leadingTrivia, Trivia(pieces: pieces))
}

private func isMarkComment(_ piece: TriviaPiece) -> Bool {
    if case let .lineComment(text) = piece { return text.hasPrefix("// MARK:") }
    return false
}

/// Walks `pieces` outward from `markIndex` in the requested direction, skipping
/// spaces and tabs, returning the index of the first `.newlines` piece found.
/// Returns `nil` if any other trivia kind (or the boundary of `pieces`) is
/// reached first.
private func findNewlinesAroundMark(
    _ markIndex: Int,
    in pieces: [TriviaPiece],
    before: Bool
) -> Int? {
    var j = before ? markIndex - 1 : markIndex + 1
    let step = before ? -1 : 1
    while j >= 0, j < pieces.count {
        if case .newlines = pieces[j] { return j }
        if pieces[j].isSpaceOrTab { j += step; continue }
        return nil
    }
    return nil
}

// MARK: - UppercaseAcronyms (inlined)
//
// The original rule has no `static func transform`. Inlined from
// `UppercaseAcronyms.visit(_ TokenSyntax)`. Pulls the configurable word list
// from `AcronymsConfiguration`. The `Finding.Message` is duplicated locally.

fileprivate extension Finding.Message {
    static let capitalizeAcronymInToken: Finding.Message = "capitalize acronyms in identifier"
}

private func applyUppercaseAcronyms(
    _ token: TokenSyntax,
    context: Context
) -> TokenSyntax {
    guard case let .identifier(text) = token.tokenKind else { return token }
    // Identifiers with no uppercase letter at all can never contain a
    // titlecased acronym substring — short-circuit before iterating the
    // acronym list.
    guard text.contains(where: \.isUppercase) else { return token }

    var result = text
    for pair in context.preparedAcronyms {
        result = replaceAcronym(pair.titlecased, with: pair.uppercased, in: result)
    }
    guard result != text else { return token }

    UppercaseAcronyms.diagnose(.capitalizeAcronymInToken, on: token, context: context)
    return token.with(\.tokenKind, .identifier(result))
}

private func replaceAcronym(
    _ titlecased: String,
    with uppercased: String,
    in text: String
) -> String {
    var result = ""
    var index = text.startIndex

    while index < text.endIndex {
        let remaining = text[index...]

        if remaining.hasPrefix(titlecased) {
            let afterMatch = text.index(index, offsetBy: titlecased.count)
            if isAcronymBoundary(text, at: afterMatch) {
                result += uppercased
                index = afterMatch
                continue
            }
        }
        // Also skip already-uppercased acronyms so we don't double-process
        if remaining.hasPrefix(uppercased) {
            let afterMatch = text.index(index, offsetBy: uppercased.count)
            result += uppercased
            index = afterMatch
            continue
        }
        result.append(text[index])
        index = text.index(after: index)
    }
    return result
}

private func isAcronymBoundary(_ text: String, at index: String.Index) -> Bool {
    guard index < text.endIndex else { return true }
    let char = text[index]
    if char.isUppercase { return true }
    // Handle plural: "Ids" → "IDs"
    if char == "s" {
        let next = text.index(after: index)
        return next >= text.endIndex || text[next].isUppercase
    }
    return false
}
