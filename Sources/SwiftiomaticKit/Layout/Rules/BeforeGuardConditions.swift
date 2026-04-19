import SwiftSyntax

/// Break before guard conditions.
package struct BeforeGuardConditions: LayoutRule {
    package static let key = "beforeGuardConditions"
    package static let group: ConfigurationGroup? = .lineBreaks
    package static let description =
        "Break before guard conditions. When true, all conditions start on a new line below guard. When false, the first condition stays on the same line as guard."
    package static let defaultValue = true
}

// MARK: - TokenStream

extension TokenStream {
    func visitGuardStmt(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        after(node.guardKeyword, tokens: .space)

        // Add break groups, using open continuation breaks, around conditions so that continuations
        // inside of the conditions can stack in addition to continuations between the conditions.
        // When `lineBreakBeforeGuardConditions` is false, skip the first condition (like if-statements)
        // so it stays on the same line as `guard`.
        for (i, condition) in node.conditions.enumerated() {
            if i == 0 && !config[BeforeGuardConditions.self] { continue }
            before(
                condition.firstToken(viewMode: .sourceAccurate),
                tokens: .break(.open(kind: .continuation), size: 0)
            )
            after(
                condition.lastToken(viewMode: .sourceAccurate),
                tokens: .break(.close(mustBreak: false), size: 0)
            )
        }

        before(node.elseKeyword, tokens: .break(.reset), .open)
        after(node.elseKeyword, tokens: .space)
        before(node.body.leftBrace, tokens: .close)

        arrangeBracesAndContents(
            of: node.body,
            contentsKeyPath: \.statements,
            shouldResetBeforeLeftBrace: false
        )

        return .visitChildren
    }
}
