import SwiftSyntax

/// Flag `coll.firstIndex(of: ...)` (or `firstIndex(where:)`) called inside a `for x in coll` loop
/// where the receiver matches the loop's iterated sequence — a textbook O(n²) pattern. Typical fix:
/// enumerate the index alongside the element (`for (index, x) in coll.enumerated()`) or build a
/// `[Element: Index]` lookup table outside the loop.
///
/// Receiver matching is identifier-based and conservative: only fires when the leftmost identifier
/// of the `firstIndex` receiver equals the leftmost identifier of the `for-in` sequence expression.
/// Nested loops and closures introduce their own scope and are reported (or not) by their own
/// visit.
final class NoFirstIndexOfInForLoop: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }

    override func visit(_ node: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        guard let sequenceName = leftmostIdentifier(of: node.sequence) else {
            return .visitChildren
        }
        let collector = FirstIndexCallCollector(receiver: sequenceName, viewMode: .sourceAccurate)
        collector.walk(node.body.statements)
        for hit in collector.matches { diagnose(.firstIndexInForLoop(hit.method), on: hit.anchor) }
        return .visitChildren
    }

    private func leftmostIdentifier(of expr: ExprSyntax) -> String? {
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text }

        if let member = expr.as(MemberAccessExprSyntax.self), let base = member.base {
            return leftmostIdentifier(of: base)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return leftmostIdentifier(of: call.calledExpression)
        }
        return nil
    }
}

private final class FirstIndexCallCollector: SyntaxVisitor {
    let receiver: String
    var matches: [(anchor: TokenSyntax, method: String)] = []

    init(receiver: String, viewMode: SyntaxTreeViewMode) {
        self.receiver = receiver
        super.init(viewMode: viewMode)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let member = node.calledExpression.as(MemberAccessExprSyntax.self),
            member.declName.baseName.text == "firstIndex",
            let baseName = leftmostIdentifier(of: member.base),
            baseName == receiver
        {
            matches.append((member.declName.baseName, member.declName.baseName.text))
        }
        return .visitChildren
    }

    private func leftmostIdentifier(of expr: ExprSyntax?) -> String? {
        guard let expr else { return nil }
        if let ref = expr.as(DeclReferenceExprSyntax.self) { return ref.baseName.text }
        if let member = expr.as(MemberAccessExprSyntax.self) {
            return leftmostIdentifier(of: member.base)
        }
        if let call = expr.as(FunctionCallExprSyntax.self) {
            return leftmostIdentifier(of: call.calledExpression)
        }
        return nil
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

fileprivate extension Finding.Message {
    static func firstIndexInForLoop(_ method: String) -> Finding.Message {
        "'.\(method)' on the iterated collection inside a 'for' loop is O(n²) — use '.enumerated()' for the index or precompute a '[Element: Index]' lookup outside the loop"
    }
}
