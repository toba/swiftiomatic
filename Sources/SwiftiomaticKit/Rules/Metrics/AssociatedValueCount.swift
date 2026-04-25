import ConfigurationKit
import SwiftSyntax

/// Enum cases should not declare too many associated values.
final class AssociatedValueCount: LintSyntaxRule<AssociatedValueCountConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        for element in node.elements {
            guard let parameterClause = element.parameterClause else { continue }
            let count = parameterClause.parameters.count
            guard
                let severity = metricSeverity(
                    value: count,
                    warning: ruleConfig.warning,
                    error: ruleConfig.error
                )
            else { continue }
            diagnose(
                .tooManyAssociatedValues(
                    count: count,
                    limit: severity == .error ? ruleConfig.error : ruleConfig.warning
                ),
                on: Syntax(element),
                severity: severity
            )
        }
        return .skipChildren
    }
}

extension Finding.Message {
    fileprivate static func tooManyAssociatedValues(count: Int, limit: Int) -> Finding.Message {
        "enum case has \(count) associated values; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct AssociatedValueCountConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Enum cases with more than this many associated values emit a
    /// warning-severity finding.
    package var warning: Int = 5
    /// Enum cases with more than this many associated values emit an
    /// error-severity finding.
    package var error: Int = 6

    package var rewrite: Bool {
        get { false }
        set { }
    }

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
    }

    private enum CodingKeys: String, CodingKey {
        case lint, warning, error
    }
}
