import SwiftSyntax

// sm:ignore-file: fileLength, functionBodyLength

/// Compact-pipeline merge of all `SourceFileSyntax` rewrites. Each former
/// rule's logic is gated on `context.shouldFormat(<RuleType>.self, node:)` so
/// users can still toggle individual behaviors via configuration
/// (the rule-name strings survive as configuration keys).
///
/// Per Phase 4a of `ddi-wtv` (sub-issue `49k-dtg`), this replaces the per-rule
/// `RewriteSyntaxRule.visit(_ SourceFileSyntax)` overrides + the
/// `static func transform` chain that `CompactStageOneRewriter` would otherwise
/// generate for `SourceFileSyntax`. The generator now emits a single `visit`
/// override that delegates to this free function (see
/// `CompactStageOneRewriterGenerator.manuallyHandledNodeTypes`).
///
/// Rule order is alphabetical by rule name. Pre-scan / state-setup blocks
/// (formerly `willEnter(_ SourceFileSyntax, context:)`) run first so that
/// `Context.ruleState` is populated before any rewrites are attempted.
/// SourceFile-level rewrites then run in the same alphabetical order.
///
/// Helpers used during these rewrites are kept on the original rule types so
/// the legacy `RewritePipeline` path (still active during the transition)
/// continues to compile. We forward to those `static` helpers from here.
func rewriteSourceFile(
    _ node: SourceFileSyntax,
    parent: Syntax?,
    context: Context
) -> SourceFileSyntax {
    var result = node

    // willEnter hooks (file-level pre-scan) are emitted by the generator
    // BEFORE super.visit, so descendants observe the populated state. They
    // are NOT called from this function.

    // MARK: SourceFile rewrites (alphabetical)

    // 1. EnsureLineBreakAtEOF: ensure file ends with exactly one newline.
    if context.shouldFormat(EnsureLineBreakAtEOF.self, node: Syntax(result)) {
        result = ensureLineBreakAtEOF(result, context: context)
    }

    // 2. NoForceTry: file-level pre-scan — populate `importsXCTest` so test
    //    classes can be identified during traversal. Helpers in
    //    `Rewrites/Exprs/NoForceTryHelpers.swift`.
    if context.shouldFormat(NoForceTry.self, node: Syntax(result)) {
        noForceTryVisitSourceFile(result, context: context)
    }

    // 3. NoForceUnwrap: file-level pre-scan — populate `importsXCTest` so
    //    test classes can be identified during traversal. Helpers in
    //    `Rewrites/Exprs/NoForceUnwrapHelpers.swift`.
    if context.shouldFormat(NoForceUnwrap.self, node: Syntax(result)) {
        noForceUnwrapVisitSourceFile(result, context: context)
    }

    // 4. PreferEnvironmentEntry: rewrite `EnvironmentValues` extensions to
    //    use `@Entry` and remove the matched `EnvironmentKey` types.
    if context.shouldFormat(PreferEnvironmentEntry.self, node: Syntax(result)) {
        result = PreferEnvironmentEntry.transform(result, parent: nil, context: context)
    }

    // 5. RedundantAccessControl: replace `fileprivate` with `private` in
    //    single-type files (the per-decl ACL stripping for redundant
    //    `internal`/`public`/extension-matching ACL still runs against the
    //    decl nodes via the generator-emitted dispatch).
    if context.shouldFormat(RedundantAccessControl.self, node: Syntax(result)) {
        result = RedundantAccessControl.transform(result, parent: nil, context: context)
    }

    // 6. URLMacro: if any `URL(string:)!` was rewritten to `#URL(...)` during
    //    the descent (recorded via `ruleState.madeReplacements`), insert the
    //    configured module import at the top of the file.
    if context.shouldFormat(URLMacro.self, node: Syntax(result)) {
        result = URLMacro.transform(result, parent: nil, context: context)
    }

    return result
}

// MARK: - EnsureLineBreakAtEOF (inlined)
//
// The original rule has no `static func transform` because its only behavior
// is the `visit(_ SourceFileSyntax)` override. Inlined here verbatim. The
// `Finding.Message` extensions in the rule file are `fileprivate`, so we
// duplicate the two message strings locally (kept verbatim with the
// originals — `Finding.Message` equality is not load-bearing).

extension Finding.Message {
    fileprivate static let eofAddTrailingNewline: Finding.Message =
        "add trailing newline at end of file"

    fileprivate static let eofRemoveExtraTrailingNewlines: Finding.Message =
        "remove extra trailing newlines at end of file"
}

private func ensureLineBreakAtEOF(
    _ node: SourceFileSyntax,
    context: Context
) -> SourceFileSyntax {
    let eof = node.endOfFileToken
    let newlineCount = eof.leadingTrivia.pieces.reduce(0) { count, piece in
        if case .newlines(let n) = piece { return count + n }
        return count
    }

    if newlineCount == 1 { return node }

    if newlineCount == 0 {
        EnsureLineBreakAtEOF.diagnose(.eofAddTrailingNewline, on: eof, context: context)
        var result = node
        result.endOfFileToken = eof.with(\.leadingTrivia, .newline)
        return result
    }

    // Multiple trailing newlines — reduce to exactly one.
    EnsureLineBreakAtEOF.diagnose(.eofRemoveExtraTrailingNewlines, on: eof, context: context)
    var result = node
    result.endOfFileToken = eof.with(\.leadingTrivia, .newline)
    return result
}
