import SwiftSyntax

/// Start adjacent awaits together with `async let` when they do not use each other's results.
///
/// Two `let x = try await …` statements in a row run one after another. The second call starts
/// only when the first one ends. When the second call does not read what the first one returns,
/// `async let` starts both calls at once and the function waits only for the slower one.
///
/// The rule reports only bindings. An await whose result the code drops, such as
/// `try await store.save()` , usually has to finish before the next call, so the rule leaves it
/// alone. A binding that reads a name the earlier binding declares depends on it and is not
/// reported. `Task.sleep` is not reported, because it waits on purpose.
///
/// Lint: Two or more adjacent `let` or `var` bindings each await a value, and no later binding
/// reads a name an earlier one declares.
final class UseAsyncLetForIndependentAwaits: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .idioms }
    override class var guidance: GuidanceLevel { .consider }

    override func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
        var run: [AwaitedBinding] = []

        func flush() {
            if run.count >= 2, let first = run.first { diagnose(.useAsyncLet, on: first.decl) }
            run = []
        }

        for item in node {
            guard let binding = AwaitedBinding(item) else {
                flush()
                continue
            }
            let declared = run.reduce(into: Set<String>()) { $0.formUnion($1.names) }

            if !run.isEmpty, !binding.reads.isDisjoint(with: declared) {
                flush()
            }
            run.append(binding)
        }
        flush()
        return .visitChildren
    }
}

/// A `let` or `var` statement whose value comes from one top-level await
private struct AwaitedBinding {
    let decl: VariableDeclSyntax
    /// The names the binding declares
    let names: Set<String>
    /// The names its value reads
    let reads: Set<String>

    init?(_ item: CodeBlockItemSyntax) {
        guard case let .decl(declSyntax) = item.item,
              let decl = declSyntax.as(VariableDeclSyntax.self),
              !decl.modifiers.contains(where: { $0.name.tokenKind == .keyword(.async) }),
              let binding = decl.bindings.firstAndOnly,
              let value = binding.initializer?.value else { return nil }

        var expression = value
        if let tryExpr = expression.as(TryExprSyntax.self) { expression = tryExpr.expression }
        guard let awaitExpr = expression.as(AwaitExprSyntax.self),
              !Self.isSleep(awaitExpr.expression) else { return nil }

        self.decl = decl
        names = Set(
            binding.pattern.tokens(viewMode: .sourceAccurate)
                .filter { $0.tokenKind.isIdentifier }
                .map(\.text))
        reads = Set(
            value.tokens(viewMode: .sourceAccurate)
                .filter { $0.tokenKind.isIdentifier }
                .map(\.text))
    }

    private static func isSleep(_ expression: ExprSyntax) -> Bool {
        guard let call = expression.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self) else {
            return false
        }
        return member.declName.baseName.text == "sleep"
            && member.base?.trimmedDescription == "Task"
    }
}

private extension TokenKind {
    var isIdentifier: Bool {
        if case .identifier = self { return true }
        return false
    }
}

fileprivate extension Finding.Message {
    static let useAsyncLet: Finding.Message = """
        these awaits do not use each other's results but run one after another. Start them \
        together with 'async let'
        """
}
