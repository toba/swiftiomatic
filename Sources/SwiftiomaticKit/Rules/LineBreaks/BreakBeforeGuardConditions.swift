import SwiftSyntax

/// Break before guard conditions.
package struct BreakBeforeGuardConditions: LayoutRule {
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
        // `breakBeforeGuardConditions` is false). When conditions are expected to wrap below
        // `guard` , fall back to the normal continuation indent. When the first condition is a
        // member-access chain and stays inline (breakBefore=false), the chain's contextual breaks
        // fire at continuation indent (+4). Using alignment(+6) for subsequent conditions would
        // create a mismatch. Fall back to continuation so all wrapped lines use the same indent.
        let firstConditionIsChain = !config[BreakBeforeGuardConditions.self]
            && node.conditions.first.map { conditionContainsMemberChain($0) } == true
        let guardBreakKind: OpenBreakKind = config[AlignWrappedConditions.self]
            && !config[BreakBeforeGuardConditions.self]
            && !firstConditionIsChain
            ? .alignment(spaces: 6)
            : .continuation

        for (i, condition) in node.conditions.enumerated() {
            if i == 0, !config[BreakBeforeGuardConditions.self] { continue }

            // When the first condition is a compound expression (&&, ||, etc.), skip the
            // continuation break so the first token stays on the guard line — matching if/while
            // behavior. Inner operator breaks handle line wrapping with their own continuation
            // indentation (same precedence principle as assignment `=` breaks).
            if i == 0,
               case let .expression(expr) = condition.condition,
               shouldApplyBreakPrecedence(expr) { continue }

            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: guardBreakKind), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        // A body that is a single statement already written inline in source ( `else { stmt }` with
        // no newline after `{` or before `}` ) is an inline-attach candidate: we want the whole
        // `else { stmt }` to stay glued to the closing condition when it fits, and to drop to its
        // own line at base indent as a unit when it doesn't. (In `inline` mode `LayoutSingleLineBodies`
        // collapses multi-line bodies first, so this also covers originally-wrapped bodies.)
        let bodyIsInlineSingleStmt = node.body.isInlineSingleStatementBody
            && (node.body.statements.first.map { !$0.leadingTrivia.containsNewlines } ?? false)
            && !node.body.rightBrace.leadingTrivia.containsNewlines

        if node.conditions.count > 1, bodyIsInlineSingleStmt {
            // Close the consistent conditions group BEFORE the last condition's per-condition
            // close-break. `afterMap` reverses same-token declarations on emit, so declaring the
            // `.close` here emits it FIRST — popping the group's force-break flag before that close
            // break (and the break before `else` ) is evaluated. Mirrors the `if` inline-body trick
            // in `visitIfExpr` . Without it, a wrapped condition forces `else` onto its own line.
            after(node.conditions.lastToken(viewMode: .sourceAccurate), tokens: .close)

            // Open the else group BEFORE the break so the break's chunk spans the entire
            // `else { stmt }` (up to the matching `.close` after the right brace). The break then
            // fires only when the whole inline form overflows — gluing `else { stmt }` to the
            // closing condition when it fits and dropping it as a unit to base indent when it
            // doesn't.
            before(
                node.elseKeyword,
                tokens: .open,
                .printerControl(kind: .clearContinuation),
                .break(.same, size: 1, newlines: .elective(ignoresDiscretionary: true))
            )
            after(node.elseKeyword, tokens: .space)
            after(node.body.rightBrace, tokens: .close)
        } else {
            // Place the break-before-else INSIDE the consistent conditions group so that whenever
            // any inner condition wraps (firing the consistent group's force-break), this break
            // also fires and pushes `else` onto its own line at base indent. When conditions all
            // fit inline, the group never fires and the elective break stays glued.
            //
            // Token order before `elseKeyword` for the multi-condition path: .break(.same) ← inside
            // consistent group, fires when group breaks .close ← closes consistent group .open ←
            // opens else group
            if node.conditions.count > 1 {
                before(
                    node.elseKeyword,
                    tokens: .break(.same, size: 1, newlines: .elective(ignoresDiscretionary: true)),
                    .close,
                    .open
                )
            } else {
                before(
                    node.elseKeyword,
                    tokens: .break(.reset, newlines: .elective(ignoresDiscretionary: true)),
                    .open
                )
            }

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
