import SwiftSyntax
import ConfigurationKit

/// Functions and initializers should not declare too many parameters.
final class ParameterCount: LintSyntaxRule<ParameterCountConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        check(parameters: node.signature.parameterClause.parameters, on: Syntax(node.funcKeyword))
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        check(parameters: node.signature.parameterClause.parameters, on: Syntax(node.initKeyword))
        return .visitChildren
    }

    private func check(parameters: FunctionParameterListSyntax, on anchor: Syntax) {
        let total = parameters.count
        let count: Int
        count = ruleConfig.ignoresDefaultParameters
            ? parameters.reduce(0) { $0 + ($1.defaultValue == nil ? 1 : 0) }
            : total
        guard let severity = metricSeverity(
            value: count,
            warning: ruleConfig.warning,
            error: ruleConfig.error
        ) else { return }
        diagnose(
            .tooManyParameters(
                count: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: anchor,
            severity: severity
        )
    }
}

fileprivate extension Finding.Message {
    static func tooManyParameters(count: Int, limit: Int) -> Finding.Message {
        "function has \(count) parameters; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct ParameterCountConfiguration: ThresholdRuleValue {
    package var enabled = true
    /// Functions with more than this many parameters emit a warning-severity finding.
    package var warning: Int = 5
    /// Functions with more than this many parameters emit an error-severity finding.
    package var error: Int = 8
    /// When `true` , parameters with a default value don't count toward the limit.
    package var ignoresDefaultParameters = true

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Bool.self, forKey: .enabled) { enabled = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .ignoresDefaultParameters) {
            ignoresDefaultParameters = v
        }
    }

    private enum CodingKeys: String, CodingKey {
        case enabled, warning, error, ignoresDefaultParameters
    }
}
