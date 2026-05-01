import SwiftSyntax

/// Prefer `min()` / `max()` over `sorted().first` / `sorted().last` .
///
/// `sorted()` is O(n log n); `min()` / `max()` are O(n) and avoid the intermediate sorted array.
///
/// Lint: warns on `xs.sorted().first` and `xs.sorted().last` (and the `sorted(by:)` variants).
/// `sorted(byKeyPath:)` , `sorted(byKeyPath:ascending:)` , and chains where `first` / `last` is
/// itself called as a method (e.g. `first(where:)` ) are intentionally not flagged.
final class PreferMinMax: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .collections }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let name = node.declName.baseName.text
        guard name == "first" || name == "last",
              // Skip `xs.sorted().first(where:)` / `xs.sorted().last { ... }` — they're method calls.
              node.parent?.is(FunctionCallExprSyntax.self) != true,
              let sortedCall = node.base?.as(FunctionCallExprSyntax.self),
              let sortedMember = sortedCall.calledExpression.as(MemberAccessExprSyntax.self),
              sortedMember.declName.baseName.text == "sorted" else { return .visitChildren }

        // Allow no arguments or a single `by:` argument; reject `byKeyPath:` , `ascending:` , etc.
        let labels = sortedCall.arguments.map { $0.label?.text }
        guard labels.isEmpty || labels == ["by"] else { return .visitChildren }

        diagnose(.preferMinMax(useFirst: name == "first"), on: node.declName)
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func preferMinMax(useFirst: Bool) -> Finding.Message {
        useFirst
            ? "prefer 'min()' over 'sorted().first'"
            : "prefer 'max()' over 'sorted().last'"
    }
}
