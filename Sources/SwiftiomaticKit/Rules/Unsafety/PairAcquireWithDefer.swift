import ConfigurationKit
import SwiftSyntax

/// Flag acquire-style calls that aren't followed by a `defer { release() }` in the same scope
/// when the scope has at least one early exit (`return` / `throw` / `break` / `continue`) after
/// the acquire. Pairing the cleanup as a `defer` immediately after the acquire is Swift's
/// idiomatic way to guarantee the release runs even when a later refactor introduces a new
/// early exit. Without it, the release line at the end of the function is silently skipped.
///
/// Configurable via `pairs` (acquire + release name list). The default catalog covers
/// well-known Apple framework pairs (lock/unlock, beginEditing/endEditing, saveGState/
/// restoreGState, etc.). Matching is by member-call name only — false positives on
/// same-named methods from unrelated types are expected and can be suppressed with
/// `// sm:ignore PairAcquireWithDefer` .
///
/// Flag-only — auto-inserting the `defer` is unsafe in general because the release's
/// arguments (`objc_sync_exit(obj)`, `os_signpost(.end, … , label)`) can't always be
/// inferred from the acquire site.
///
/// Source: https://ioscodereview.com/issues/issue-79-defer-done-right-instruments-is-back-and-wwdc-is-one-week-away/.
final class PairAcquireWithDefer: LintSyntaxRule<PairAcquireWithDeferConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .unsafety }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        checkScope(node)
        return .visitChildren
    }

    /// Scans a single code block (the items between `{` and `}` for a function, closure,
    /// accessor, or nested block). For each acquire call, decide whether the rest of the
    /// scope satisfies the pairing rule.
    private func checkScope(_ items: CodeBlockItemListSyntax) {
        let pairs = ruleConfig.pairs
        guard !pairs.isEmpty else { return }
        let acquireByName = Dictionary(uniqueKeysWithValues: pairs.map { ($0.acquire, $0.release) })

        let elements = Array(items)
        for (idx, item) in elements.enumerated() {
            guard let call = extractCall(item),
                  let match = matchedAcquireName(call, in: acquireByName) else { continue }
            let releaseName = acquireByName[match.name]!
            let remainder = elements.dropFirst(idx + 1)

            if scopeHasMatchingDefer(remainder, releaseName: releaseName) { continue }
            guard scopeHasEarlyExit(remainder) else { continue }
            diagnose(.missingDefer(acquire: match.name, release: releaseName), on: match.anchor)
        }
    }

    /// Pull a `FunctionCallExprSyntax` out of a `CodeBlockItemSyntax` whose item is just a
    /// bare expression (statement-position call). Returns nil for declarations or wrapped
    /// expressions.
    private func extractCall(_ item: CodeBlockItemSyntax) -> FunctionCallExprSyntax? {
        guard case .expr(let expr) = item.item else { return nil }
        return expr.as(FunctionCallExprSyntax.self)
    }

    /// Match the called expression's terminal name against the catalog. Accepts either a
    /// bare function call (`lock()`) or a member call (`obj.beginEditing()`).
    private func matchedAcquireName(
        _ call: FunctionCallExprSyntax,
        in catalog: [String: String]
    ) -> (name: String, anchor: Syntax)? {
        if let member = call.calledExpression.as(MemberAccessExprSyntax.self) {
            let name = member.declName.baseName.text
            guard catalog[name] != nil else { return nil }
            return (name, Syntax(member.declName))
        }
        if let ident = call.calledExpression.as(DeclReferenceExprSyntax.self) {
            let name = ident.baseName.text
            guard catalog[name] != nil else { return nil }
            return (name, Syntax(ident))
        }
        return nil
    }

    /// Returns true if any item in the trailing slice is a `defer { … }` whose body invokes
    /// the named release function (member or free). Base matching is intentionally relaxed —
    /// the same release name reaching the same scope is taken as evidence of a paired
    /// cleanup.
    private func scopeHasMatchingDefer(
        _ remainder: ArraySlice<CodeBlockItemSyntax>,
        releaseName: String
    ) -> Bool {
        for item in remainder {
            guard case .stmt(let stmt) = item.item,
                  let deferStmt = stmt.as(DeferStmtSyntax.self) else { continue }
            if blockMentionsCall(deferStmt.body.statements, named: releaseName) { return true }
        }
        return false
    }

    /// Recursively scan a statement list (and any nested blocks within it) for a call to the
    /// given function name. Used inside `defer` bodies, which are usually one-liners but may
    /// contain wrapping logic.
    private func blockMentionsCall(_ items: CodeBlockItemListSyntax, named name: String) -> Bool {
        let finder = CallNameFinder(target: name, viewMode: .sourceAccurate)
        finder.walk(items)
        return finder.found
    }

    /// True if the trailing slice contains any statement-level early exit at the *same scope*.
    /// Nested functions and closure bodies don't count — those exits leave the inner scope, not
    /// the scope the acquire is in.
    private func scopeHasEarlyExit(_ remainder: ArraySlice<CodeBlockItemSyntax>) -> Bool {
        for item in remainder {
            let finder = EarlyExitFinder(viewMode: .sourceAccurate)
            finder.walk(item)
            if finder.found { return true }
        }
        return false
    }
}

/// Walks a syntax tree looking for any function call (member or free) whose terminal name
/// matches `target`. Does not descend into nested function or closure bodies — a release call
/// inside a callback wouldn't pair with the outer-scope acquire.
private final class CallNameFinder: SyntaxVisitor {
    let target: String
    var found = false

    init(target: String, viewMode: SyntaxTreeViewMode) {
        self.target = target
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if found { return .skipChildren }
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
           member.declName.baseName.text == target
        {
            found = true
            return .skipChildren
        }
        if let ident = node.calledExpression.as(DeclReferenceExprSyntax.self),
           ident.baseName.text == target
        {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

/// Walks a syntax tree looking for any statement that exits the enclosing function scope
/// (`return`, `throw`, `break`, `continue`). Does not descend into nested function or closure
/// bodies — an inner-closure `return` doesn't skip the outer-scope release.
private final class EarlyExitFinder: SyntaxVisitor {
    var found = false

    override func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }

    override func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }

    override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }

    override func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
        found = true
        return .skipChildren
    }

    /// A `try` without `?` or `!` propagates the error to the caller — for the purpose of
    /// pairing acquire/release this counts as an early exit. `try?` / `try!` don't propagate
    /// and are not flagged.
    override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
        if node.questionOrExclamationMark == nil {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension Finding.Message {
    static func missingDefer(acquire: String, release: String) -> Finding.Message {
        "'\(acquire)' has no paired 'defer { \(release)() }' in this scope — a later 'return' or 'throw' will silently skip the cleanup"
    }
}

// MARK: - Configuration

/// A configurable acquire/release pair. The catalog matches by terminal name only, so
/// member calls (`obj.beginEditing()`) and free functions (`objc_sync_enter(obj)`) both
/// participate as long as the name matches.
package struct AcquireReleasePair: Sendable, Codable, Equatable {
    package var acquire: String
    package var release: String

    package init(acquire: String, release: String) {
        self.acquire = acquire
        self.release = release
    }
}

package struct PairAcquireWithDeferConfiguration: SyntaxRuleValue {
    package var rewrite = false
    package var lint: Lint = .warn
    /// Pairs to check. Defaults to a catalog of well-known Apple framework
    /// acquire/release names. Configuration replaces the catalog wholesale rather than
    /// appending — set this to extend with project-specific pairs (re-listing the
    /// defaults if you want to keep them).
    package var pairs: [AcquireReleasePair] = AcquireReleasePair.defaults

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Bool.self, forKey: .rewrite) { rewrite = v }
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent([AcquireReleasePair].self, forKey: .pairs) { pairs = v }
    }

    private enum CodingKeys: String, CodingKey { case rewrite, lint, pairs }
}

extension AcquireReleasePair {
    fileprivate static let defaults: [AcquireReleasePair] = [
        .init(acquire: "lock", release: "unlock"),
        .init(acquire: "objc_sync_enter", release: "objc_sync_exit"),
        .init(acquire: "beginUpdates", release: "endUpdates"),
        .init(acquire: "beginEditing", release: "endEditing"),
        .init(acquire: "saveGState", release: "restoreGState"),
        .init(acquire: "beginGrouping", release: "endGrouping"),
        .init(
            acquire: "startAccessingSecurityScopedResource",
            release: "stopAccessingSecurityScopedResource"
        ),
    ]
}
