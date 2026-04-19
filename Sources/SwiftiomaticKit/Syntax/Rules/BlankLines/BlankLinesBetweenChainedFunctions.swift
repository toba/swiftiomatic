import SwiftSyntax

/// Remove blank lines between chained function calls.
///
/// Method chains like `.map { ... }.filter { ... }` are a single logical expression. Blank lines
/// between chain elements break the visual continuity. Linebreaks are preserved — only the
/// extra blank lines are removed. Comments between chain elements are also preserved.
///
/// Lint: If there are blank lines between chained member accesses, a lint warning is raised.
///
/// Format: The blank lines are removed, keeping linebreaks and comments.
final class BlankLinesBetweenChainedFunctions: RewriteSyntaxRule {
    override class var group: ConfigurationGroup? { .blankLines }
    override class var defaultHandling: RuleHandling { .off }

    override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
        let visited = super.visit(node)
        guard let memberAccess = visited.as(MemberAccessExprSyntax.self) else { return visited }

        // Only act on chains — the base must be a function call or another member access.
        guard
            memberAccess.base?.is(FunctionCallExprSyntax.self) == true
                || memberAccess.base?.is(MemberAccessExprSyntax.self) == true
        else { return visited }

        let period = memberAccess.period
        let trivia = period.leadingTrivia

        // Check if there are blank lines (any .newlines piece > 1).
        let hasBlankLines = trivia.pieces.contains { piece in
            if case .newlines(let n) = piece { return n > 1 }
            return false
        }
        guard hasBlankLines else { return visited }

        diagnose(.removeBlankLinesBetweenChainedCalls, on: period)

        // Reduce all multi-newlines to single newlines.
        let cleaned = Trivia(
            pieces: trivia.pieces.map { piece in
                if case .newlines(let n) = piece, n > 1 { return .newlines(1) }
                return piece
            }
        )

        let newPeriod = period.with(\.leadingTrivia, cleaned)
        return ExprSyntax(memberAccess.with(\.period, newPeriod))
    }
}

extension Finding.Message {
    fileprivate static let removeBlankLinesBetweenChainedCalls: Finding.Message =
        "remove blank lines between chained function calls"
}
