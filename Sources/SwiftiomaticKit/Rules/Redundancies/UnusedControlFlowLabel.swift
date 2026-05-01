import SwiftSyntax

/// A label on a loop or switch ( `outer: while …` , `label: switch …` ) is only useful if it's
/// referenced by an inner `break label` / `continue label` . An unreferenced label is dead syntax —
/// usually a leftover from refactoring.
///
/// Lint: When a `LabeledStmt` carries a label that no nested `break` or `continue` uses, a warning
/// is raised on the label.
final class UnusedControlFlowLabel: LintSyntaxRule<LintOnlyValue>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .redundancies }

    override func visit(_ node: LabeledStmtSyntax) -> SyntaxVisitorContinueKind {
        let collector = LabelReferenceCollector(viewMode: .sourceAccurate)
        collector.walk(node)
        if !collector.labels.contains(node.label.text) {
            diagnose(.unusedLabel(node.label.text), on: node.label)
        }
        return .visitChildren
    }
}

private final class LabelReferenceCollector: SyntaxVisitor {
    var labels: Set<String> = []

    override func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
        if let label = node.label?.text { labels.insert(label) }
        return .visitChildren
    }

    override func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
        if let label = node.label?.text { labels.insert(label) }
        return .visitChildren
    }
}

fileprivate extension Finding.Message {
    static func unusedLabel(_ name: String) -> Finding.Message {
        "control flow label '\(name)' is never referenced — remove it"
    }
}
