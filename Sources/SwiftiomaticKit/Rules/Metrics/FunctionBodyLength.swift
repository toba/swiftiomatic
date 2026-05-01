import SwiftSyntax
import ConfigurationKit

/// Function bodies should not exceed a configurable line length.
///
/// Counts source lines inside the body, excluding the lines containing the opening and closing
/// braces. Comment-only and blank lines are excluded by default; tokens on the same line still
/// count that line.
///
/// Lint: emits `.warn` over the warning threshold and `.error` over the error threshold.
final class FunctionBodyLength: LintSyntaxRule<FunctionBodyLengthConfiguration>, @unchecked Sendable
{
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { check(body, on: Syntax(node.funcKeyword)) }
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { check(body, on: Syntax(node.initKeyword)) }
        return .visitChildren
    }

    override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body { check(body, on: Syntax(node.deinitKeyword)) }
        return .visitChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        if let accessorBlock = node.accessorBlock {
            check(accessorBlock, on: Syntax(node.subscriptKeyword))
        }
        return .visitChildren
    }

    private func check(_ node: some SyntaxProtocol, on anchor: Syntax) {
        let count = bodyLineCount(of: node, in: context.sourceLocationConverter)
        guard let severity = metricSeverity(
            value: count,
            warning: ruleConfig.warning,
            error: ruleConfig.error
        ) else { return }
        diagnose(
            .functionBodyTooLong(
                lines: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: anchor,
            severity: severity
        )
    }
}

fileprivate extension Finding.Message {
    static func functionBodyTooLong(lines: Int, limit: Int) -> Finding.Message {
        "function body has \(lines) lines; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct FunctionBodyLengthConfiguration: ThresholdRuleValue {
    package var enabled = true
    /// Function bodies longer than this many lines emit a warning-severity finding.
    package var warning: Int = 50
    /// Function bodies longer than this many lines emit an error-severity finding.
    package var error: Int = 100

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Bool.self, forKey: .enabled) { enabled = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
    }

    private enum CodingKeys: String, CodingKey {
        case enabled, warning, error
    }
}
