import ConfigurationKit
import SwiftSyntax

/// Tuples with many elements are hard to read; consider a struct instead.
final class TupleSize: LintSyntaxRule<TupleSizeConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
        check(count: node.elements.count, on: Syntax(node))
        return .visitChildren
    }

    private func check(count: Int, on anchor: Syntax) {
        guard
            let severity = metricSeverity(
                value: count,
                warning: ruleConfig.warning,
                error: ruleConfig.error
            )
        else { return }
        diagnose(
            .tupleTooLarge(
                count: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: anchor,
            severity: severity
        )
    }
}

extension Finding.Message {
    fileprivate static func tupleTooLarge(count: Int, limit: Int) -> Finding.Message {
        "tuple has \(count) elements; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct TupleSizeConfiguration: ThresholdRuleValue {
    package var enabled: Bool = true
    /// Tuples with more than this many elements emit a warning-severity finding.
    package var warning: Int = 3
    /// Tuples with more than this many elements emit an error-severity finding.
    package var error: Int = 4

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
