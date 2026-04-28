import SwiftSyntax

/// Drop `.enumerated()` from `for` loops where one half of the tuple pattern is unused.
///
/// - `for (_, x) in seq.enumerated()` → `for x in seq`
/// - `for (i, _) in seq.enumerated()` → `for i in seq.indices`
///
/// The rule only rewrites when the call is exactly `seq.enumerated()` with no further chaining,
/// no arguments, and no trailing closure. Closure-based usages (`seq.enumerated().map { ... }`)
/// are not handled because $0/$1 reference analysis is intricate; lint a separate rule when
/// that case becomes important.
///
/// Lint: A finding is raised at `enumerated`.
///
/// Rewrite: `.enumerated()` is removed (or replaced with `.indices`) and the binding pattern
///         is collapsed to a single identifier.
final class RedundantEnumerated: RewriteSyntaxRule<BasicRuleValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
        let parent = Syntax(node).parent
        let visited = super.visit(node)
        guard let concrete = visited.as(ForStmtSyntax.self) else { return visited }
        return Self.transform(concrete, parent: parent, context: context)
    }

    static func transform(
        _ node: ForStmtSyntax,
        parent: Syntax?,
        context: Context
    ) -> StmtSyntax {
        guard let tuple = node.pattern.as(TuplePatternSyntax.self),
            tuple.elements.count == 2,
            let first = tuple.elements.first,
            let second = tuple.elements.last,
            let call = node.sequence.as(FunctionCallExprSyntax.self),
            let member = call.calledExpression.as(MemberAccessExprSyntax.self),
            let base = member.base,
            member.declName.baseName.text == "enumerated",
            call.arguments.isEmpty,
            call.trailingClosure == nil,
            call.additionalTrailingClosures.isEmpty
        else {
            return StmtSyntax(node)
        }

        let firstUnused = first.pattern.is(WildcardPatternSyntax.self)
        let secondUnused = second.pattern.is(WildcardPatternSyntax.self)
        // If both are wildcards or neither, the rule doesn't apply.
        guard firstUnused != secondUnused else {
            return StmtSyntax(node)
        }

        var result = node

        if firstUnused {
            // `for (_, x) in seq.enumerated()` → `for x in seq`
            Self.diagnose(.dropEnumeratedIndexUnused, on: first.pattern, context: context)
            result.pattern = PatternSyntax(second.pattern.with(\.leadingTrivia, tuple.leadingTrivia)
                .with(\.trailingTrivia, tuple.trailingTrivia))
            result.sequence = ExprSyntax(base.with(\.leadingTrivia, call.leadingTrivia)
                .with(\.trailingTrivia, call.trailingTrivia))
        } else {
            // `for (i, _) in seq.enumerated()` → `for i in seq.indices`
            Self.diagnose(.useIndicesItemUnused, on: second.pattern, context: context)
            result.pattern = PatternSyntax(first.pattern.with(\.leadingTrivia, tuple.leadingTrivia)
                .with(\.trailingTrivia, tuple.trailingTrivia))
            var indicesAccess = member
            indicesAccess.declName = DeclReferenceExprSyntax(baseName: .identifier("indices"))
            // Drop the empty `()` from the call by replacing the FunctionCallExpr with the
            // member-access expression rooted at `.indices`.
            let indicesExpr = ExprSyntax(indicesAccess)
                .with(\.leadingTrivia, call.leadingTrivia)
                .with(\.trailingTrivia, call.trailingTrivia)
            result.sequence = indicesExpr
        }

        return StmtSyntax(result)
    }
}

extension Finding.Message {
    fileprivate static let dropEnumeratedIndexUnused: Finding.Message =
        "drop '.enumerated()'; the index is unused"

    fileprivate static let useIndicesItemUnused: Finding.Message =
        "use '.indices' instead of '.enumerated()'; the element is unused"
}
