import SwiftSyntax

/// Break before guard conditions.
package struct BeforeGuardConditions: LayoutRule {
    package static let key = "beforeGuardConditions"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description =
        "Break before guard conditions. When true, all conditions start on a new line below guard. When false, the first condition stays on the same line as guard."
    package static let defaultValue = true
}

extension TokenStream {
    func visitGuardStmt(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        after(node.guardKeyword, tokens: .space)

        // Add break groups, using open continuation breaks, around conditions so that continuations
        // inside of the conditions can stack in addition to continuations between the conditions.
        // When `lineBreakBeforeGuardConditions` is false, skip the first condition (like if-statements)
        // so it stays on the same line as `guard`.
        // The +6 alignment under the first condition only makes sense when the first condition
        // stays on the `guard` line (i.e., `beforeGuardConditions` is false). When conditions are
        // expected to wrap below `guard`, fall back to the normal continuation indent.
        let guardBreakKind: OpenBreakKind =
            config[AlignWrappedConditions.self] && !config[BeforeGuardConditions.self]
            ? .alignment(spaces: 6) : .continuation
        for (i, condition) in node.conditions.enumerated() {
            if i == 0 && !config[BeforeGuardConditions.self] { continue }

            // When the first condition is a compound expression (&&, ||, etc.), skip the
            // continuation break so the first token stays on the guard line — matching
            // if/while behavior. Inner operator breaks handle line wrapping with their own
            // continuation indentation (same precedence principle as assignment `=` breaks).
            if i == 0,
                case .expression(let expr) = condition.condition,
                shouldApplyBreakPrecedence(expr)
            { continue }

            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: guardBreakKind), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        // For an already-inline single-statement body (`else { stmt }`), wrap
        // `else { stmt }` in an outer group spanning past the closing brace so
        // the printer evaluates the whole inline form's length at the break
        // point. With a `.same` (elective) break, `else { stmt }` stays glued
        // to the closing condition when it fits, and drops to a fresh line at
        // base indent when it doesn't.
        //
        // For multi-line / multi-statement bodies, keep the original `.reset`
        // semantics so `else` stays visually separated from the wrapped
        // continuation lines.
        if node.body.hasInlineIntentSingleStatementBody
            && !config[AlignWrappedConditions.self]
        {
            before(
                node.elseKeyword,
                tokens: .break(.same, newlines: .elective(ignoresDiscretionary: true)),
                .open
            )
            after(node.elseKeyword, tokens: .space)
            before(
                node.body.leftBrace,
                tokens: .close,
                .printerControl(kind: .clearContinuation)
            )
        } else {
            before(
                node.elseKeyword,
                tokens: .break(.reset, newlines: .elective(ignoresDiscretionary: true)),
                .open
            )
            after(node.elseKeyword, tokens: .space)
            before(node.body.leftBrace, tokens: .close)
        }

        arrangeBracesAndContents(
            of: node.body,
            contentsKeyPath: \.statements,
            shouldResetBeforeLeftBrace: false
        )

        return .visitChildren
    }
}
