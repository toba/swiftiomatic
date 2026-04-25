import ConfigurationKit
import SwiftSyntax

/// Function bodies should have bounded cyclomatic complexity.
///
/// Counts decision points (`if`, `for`, `while`, `guard`, `repeat`, `switch case`,
/// `catch`, `fallthrough`) within each function or initializer body. Nested
/// functions and initializers are excluded — they get their own measurement.
///
/// Lint: emits `.warn` when complexity exceeds the warning threshold and
///       `.error` when it exceeds the error threshold.
final class CyclomaticComplexity: LintSyntaxRule<CyclomaticComplexityConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            evaluate(body: body, anchor: Syntax(node.funcKeyword))
        }
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        if let body = node.body {
            evaluate(body: body, anchor: Syntax(node.initKeyword))
        }
        return .visitChildren
    }

    private func evaluate(body: CodeBlockSyntax, anchor: Syntax) {
        let visitor = ComplexityVisitor(
            ignoresCaseStatements: ruleConfig.ignoresCaseStatements
        )
        visitor.walk(body)
        let complexity = visitor.complexity

        guard
            let severity = metricSeverity(
                value: complexity,
                warning: ruleConfig.warning,
                error: ruleConfig.error
            )
        else { return }

        diagnose(
            .complexityTooHigh(
                complexity: complexity,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: anchor,
            severity: severity
        )
    }
}

private final class ComplexityVisitor: SyntaxVisitor {
    var complexity = 0
    let ignoresCaseStatements: Bool

    init(ignoresCaseStatements: Bool) {
        self.ignoresCaseStatements = ignoresCaseStatements
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_: ForStmtSyntax) { complexity += 1 }
    override func visitPost(_: IfExprSyntax) { complexity += 1 }
    override func visitPost(_: GuardStmtSyntax) { complexity += 1 }
    override func visitPost(_: RepeatStmtSyntax) { complexity += 1 }
    override func visitPost(_: WhileStmtSyntax) { complexity += 1 }
    override func visitPost(_: CatchClauseSyntax) { complexity += 1 }

    override func visitPost(_: SwitchCaseSyntax) {
        if !ignoresCaseStatements { complexity += 1 }
    }

    override func visitPost(_: FallThroughStmtSyntax) {
        if !ignoresCaseStatements { complexity -= 1 }
    }

    override func visit(_: FunctionDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
    override func visit(_: InitializerDeclSyntax) -> SyntaxVisitorContinueKind { .skipChildren }
}

extension Finding.Message {
    fileprivate static func complexityTooHigh(complexity: Int, limit: Int) -> Finding.Message {
        "function has cyclomatic complexity \(complexity); limit is \(limit)"
    }
}

// MARK: - Configuration

package struct CyclomaticComplexityConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Functions whose cyclomatic complexity exceeds this value emit a
    /// warning-severity finding.
    package var warning: Int = 10
    /// Functions whose cyclomatic complexity exceeds this value emit an
    /// error-severity finding.
    package var error: Int = 20
    /// When `true`, individual `case` clauses inside a `switch` don't add to
    /// complexity (only the `switch` itself counts).
    package var ignoresCaseStatements: Bool = false

    package var rewrite: Bool {
        get { false }
        set { }  // lint-only
    }

    package init() {}

    package init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let v = try c.decodeIfPresent(Lint.self, forKey: .lint) { lint = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .warning) { warning = v }
        if let v = try c.decodeIfPresent(Int.self, forKey: .error) { error = v }
        if let v = try c.decodeIfPresent(Bool.self, forKey: .ignoresCaseStatements) {
            ignoresCaseStatements = v
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lint
        case warning
        case error
        case ignoresCaseStatements
    }
}
