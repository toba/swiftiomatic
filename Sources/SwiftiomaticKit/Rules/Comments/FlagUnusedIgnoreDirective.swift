import SwiftSyntax

/// Flags `// sm:ignore` directives whose listed rules suppressed nothing.
///
/// Stale ignore directives accumulate as code evolves: a rule renamed, a finding stops firing,
/// or a typo'd rule name was never valid. This rule walks every `// sm:ignore Rule1, Rule2`
/// directive after all other passes and emits a finding for each rule name whose hit count
/// stayed at zero.
///
/// Bare `// sm:ignore` (all rules) is never flagged: proving "no rule fired" requires running
/// every rule against every node in the directive's range, which would be expensive and noisy.
///
/// See issue `ekr-k5l`.
final class FlagUnusedIgnoreDirective: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .comments }

    /// Empty pre-visit: needed only to register this rule on `SourceFileSyntax` in the generated
    /// pipeline (the rule collector keys dispatch off `visit`, not `visitPost`). All work happens
    /// in `visitPost`, after every other rule has stamped its hits on `RuleMask`.
    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind { .visitChildren }

    /// Runs after every other rule has visited the file (and stamped hits on `RuleMask`'s
    /// directives). For each subset directive, emit one finding per unused rule name.
    override func visitPost(_ node: SourceFileSyntax) {
        for directive in context.ruleMask.directives {
            guard case let .subset(ruleNames) = directive.scope else { continue }
            for name in ruleNames where directive.hitsPerRule[name] == nil {
                emitUnusedFinding(for: name, at: directive.location)
            }
        }
    }

    private func emitUnusedFinding(for ruleName: String, at location: SourceLocation) {
        guard context.findingEmitter.isAttached else { return }
        let severity = context.severity(of: Self.self)
        guard severity.isActive else { return }
        context.findingEmitter.emit(
            .unusedIgnoreDirective(ruleName: ruleName),
            category: SyntaxFindingCategory(ruleType: Self.self),
            severity: severity,
            location: Finding.Location(location)
        )
    }
}

fileprivate extension Finding.Message {
    static func unusedIgnoreDirective(ruleName: String) -> Finding.Message {
        "'// sm:ignore' lists '\(ruleName)' but it suppresses nothing here; remove it"
    }
}
