import SwiftSyntax

// sm:ignore fileLength, functionBodyLength

/// Compact-pipeline merge of all `SourceFileSyntax` rewrites. Each former rule's logic is gated on
/// `context.shouldRewrite(<RuleType>.self, at:)` so users can still toggle individual behaviors via
/// configuration (the rule-name strings survive as configuration keys).
///
/// Rule order is alphabetical by rule name. Pre-scan / state-setup blocks (formerly
/// `willEnter(_ SourceFileSyntax, context:)` ) run first so that a typed property on `Context` is
/// populated before any rewrites are attempted. SourceFile-level rewrites then run in the same
/// alphabetical order.
///
/// Helpers used during these rewrites live as `static` members on the original rule types; we
/// forward to them from here.
func rewriteSourceFile(
    _ node: SourceFileSyntax,
    parent _: Syntax?,
    context: Context
) -> SourceFileSyntax {
    var result = node

    // willEnter hooks (file-level pre-scan) are emitted by the generator
    // BEFORE super.visit, so descendants observe the populated state. They
    // are NOT called from this function.

    // MARK: SourceFile rewrites (alphabetical)

    // 1. BreakAtEndOfFile: ensure file ends with exactly one newline.
    if context.shouldRewrite(BreakAtEndOfFile.self, at: Syntax(result)) {
        result = ensureLineBreakAtEOF(result, context: context)
    }

    // 2. NoForceTry: file-level pre-scan — populate `importsXCTest` so test classes can be
    //    identified during traversal.
    if context.shouldRewrite(NoForceTry.self, at: Syntax(result)) {
        setImportsXCTest(context: context, sourceFile: result)
    }

    // 3. NoForceUnwrap: file-level pre-scan — populate `importsXCTest` so test classes can be
    //    identified during traversal. Helpers in `Rewrites/Exprs/NoForceUnwrapHelpers.swift` .
    if context.shouldRewrite(NoForceUnwrap.self, at: Syntax(result)) {
        NoForceUnwrap.visitSourceFile(result, context: context)
    }

    // 4. UseAtEntryNotEnvironmentKey: rewrite `EnvironmentValues` extensions to use `@Entry` and remove
    //    the matched `EnvironmentKey` types.
    if context.shouldRewrite(UseAtEntryNotEnvironmentKey.self, at: Syntax(result)) {
        result = UseAtEntryNotEnvironmentKey.transform(result, original: node, parent: nil, context: context)
    }

    // 5. DropRedundantAccessControl: replace `fileprivate` with `private` in single-type files (the
    //    per-decl ACL stripping for redundant `internal` / `public` /extension-matching ACL still
    //    runs against the decl nodes via the generator-emitted dispatch).
    if context.shouldRewrite(DropRedundantAccessControl.self, at: Syntax(result)) {
        result = DropRedundantAccessControl.transform(result, original: node, parent: nil, context: context)
    }

    // 6. UseURLMacroForURLLiterals: if any `URL(string:)!` was rewritten to `#URL(...)` during the descent (recorded
    //    via `ruleState.madeReplacements` ), insert the configured module import at the top of the
    //    file.
    if context.shouldRewrite(UseURLMacroForURLLiterals.self, at: Syntax(result)) {
        result = UseURLMacroForURLLiterals.transform(result, original: node, parent: nil, context: context)
    }

    return result
}

// MARK: - BreakAtEndOfFile (inlined)
//
// The original rule has no `static func transform` because its only behavior
// is the `visit(_ SourceFileSyntax)` override. Inlined here verbatim. The
// `Finding.Message` extensions in the rule file are `fileprivate`, so we
// duplicate the two message strings locally (kept verbatim with the
// originals — `Finding.Message` equality is not load-bearing).

fileprivate extension Finding.Message {
    static let eofAddTrailingNewline: Finding.Message = "add trailing newline at end of file"

    static let eofRemoveExtraTrailingNewlines: Finding.Message =
        "remove extra trailing newlines at end of file"
}

private func ensureLineBreakAtEOF(
    _ node: SourceFileSyntax,
    context: Context
) -> SourceFileSyntax {
    let eof = node.endOfFileToken
    let pieces = eof.leadingTrivia.pieces
    let newlineCount = pieces.reduce(0) { count, piece in
        if case let .newlines(n) = piece { return count + n }
        return count
    }

    if newlineCount == 1 { return node }

    BreakAtEndOfFile.diagnose(
        newlineCount == 0 ? .eofAddTrailingNewline : .eofRemoveExtraTrailingNewlines,
        on: eof, context: context
    )

    // Preserve any non-newline trivia (e.g. a trailing `// MARK:` comment) and emit exactly one
    // newline at the end.
    var rebuilt: [TriviaPiece] = []
    rebuilt.reserveCapacity(pieces.count + 1)

    for piece in pieces {
        if case .newlines = piece { continue }
        rebuilt.append(piece)
    }
    rebuilt.append(.newlines(1))

    var result = node
    result.endOfFileToken = eof.with(\.leadingTrivia, Trivia(pieces: rebuilt))
    return result
}
