import ConfigurationKit
import SwiftSyntax

/// Closures should not exceed a configurable body line length.
final class ClosureBodyLength: LintSyntaxRule<ClosureBodyLengthConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let count = bodyLineCount(of: node, in: context.sourceLocationConverter)
        guard
            let severity = metricSeverity(
                value: count,
                warning: ruleConfig.warning,
                error: ruleConfig.error
            )
        else { return .visitChildren }
        diagnose(
            .closureBodyTooLong(
                lines: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: node.leftBrace,
            severity: severity
        )
        return .visitChildren
    }
}

extension Finding.Message {
    fileprivate static func closureBodyTooLong(lines: Int, limit: Int) -> Finding.Message {
        "closure body has \(lines) lines; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct ClosureBodyLengthConfiguration: ThresholdRuleValue {
    package var enabled: Bool = true
    /// Closure bodies longer than this many lines emit a warning-severity finding.
    package var warning: Int = 30
    /// Closure bodies longer than this many lines emit an error-severity finding.
    package var error: Int = 50

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
