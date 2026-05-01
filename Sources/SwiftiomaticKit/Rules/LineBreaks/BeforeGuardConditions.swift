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

        // Outer consistent group: once any condition wraps, every condition wraps. Only meaningful
        // with multiple conditions; a single condition has no inter-element break to coordinate,
        // and an extra group can perturb the surrounding `else` heuristic.
        if node.conditions.count > 1 {
            before(
                node.conditions.firstToken(viewMode: .sourceAccurate),
                tokens: .open(.consistent)
            )
        }

        // Add break groups, using open continuation breaks, around conditions so that continuations
        // inside of the conditions can stack in addition to continuations between the conditions.
        // When `lineBreakBeforeGuardConditions` is false, skip the first condition (like
        // if-statements) so it stays on the same line as `guard` . The +6 alignment under the first
        // condition only makes sense when the first condition stays on the `guard` line (i.e.,
        // `beforeGuardConditions` is false). When conditions are expected to wrap below `guard` ,
        // fall back to the normal continuation indent.
        let guardBreakKind: OpenBreakKind = config[AlignWrappedConditions.self]
            && !config[BeforeGuardConditions.self]
            ? .alignment(spaces: 6)
            : .continuation

        for (i, condition) in node.conditions.enumerated() {
            if i == 0, !config[BeforeGuardConditions.self] { continue }

            // When the first condition is a compound expression (&&, ||, etc.), skip the
            // continuation break so the first token stays on the guard line — matching if/while
            // behavior. Inner operator breaks handle line wrapping with their own continuation
            // indentation (same precedence principle as assignment `=` breaks).
            if i == 0,
               case let .expression(expr) = condition.condition,
               shouldApplyBreakPrecedence(expr)
            {
                continue
            }

            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: guardBreakKind), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        // Close the consistent group AFTER the per-condition close breaks above. afterMap appends
        // groups in declaration order but emits them reversed, so adding `.close` after the loop
        // emits it BEFORE the last condition's `.break(.close)` . This pops the consistent group's
        // force-break flag before the close break is evaluated, so the close break — and the
        // subsequent break before `else` — see the outer (unforced) state and can stay inline when
        // the inline body fits.
        if node.conditions.count > 1 {
            after(node.conditions.lastToken(viewMode: .sourceAccurate), tokens: .close)
        }

        // For an already-inline single-statement body ( `else { stmt }` ), wrap `else { stmt }` in
        // an outer `.open(.inconsistent)` group spanning past the closing brace so the printer
        // evaluates the inline form's length at the break point: glue to the closing condition when
        // it fits, drop `else` to base indent when it doesn't.
        //
        // For multi-line / multi-statement bodies, keep the `.reset` semantics so `else` stays
        // visually separated from the wrapped continuation lines.
        if node.body.isInlineSingleStatementBody {
            before(
                node.elseKeyword,
                tokens: .printerControl(kind: .clearContinuation),
                .break(.same, size: 1, newlines: .elective(ignoresDiscretionary: true)),
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
