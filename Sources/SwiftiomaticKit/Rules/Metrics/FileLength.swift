import ConfigurationKit
import SwiftSyntax

/// Files should not exceed a configurable total line count.
final class FileLength: LintSyntaxRule<FileLengthConfiguration>, @unchecked Sendable {
    override class var group: ConfigurationGroup? { .metrics }

    override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        let converter = context.sourceLocationConverter
        let endLine = node.endLocation(converter: converter).line
        let count: Int
        if ruleConfig.ignoreCommentOnlyLines {
            var meaningful = Set<Int>()
            for token in node.tokens(viewMode: .sourceAccurate) {
                meaningful.insert(token.startLocation(converter: converter).line)
            }
            count = meaningful.count
        } else {
            count = endLine
        }

        guard
            let severity = metricSeverity(
                value: count,
                warning: ruleConfig.warning,
                error: ruleConfig.error
            )
        else { return .skipChildren }
        diagnose(
            .fileTooLong(
                lines: count,
                limit: severity == .error ? ruleConfig.error : ruleConfig.warning
            ),
            on: node,
            severity: severity
        )
        return .skipChildren
    }
}

extension Finding.Message {
    fileprivate static func fileTooLong(lines: Int, limit: Int) -> Finding.Message {
        "file has \(lines) lines; limit is \(limit)"
    }
}

// MARK: - Configuration

package struct FileLengthConfiguration: SyntaxRuleValue {
    package var lint: Lint = .warn
    /// Files with more than this many lines emit a warning-severity finding.
    package var warning: Int = 400
    /// Files with more than this many lines emit an error-severity finding.
    package var error: Int = 1000
    /// When `true`, lines that contain only a comment (or whitespace) don't
    /// count toward the line total.
    package var ignoreCommentOnlyLines: Bool = false

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
        if let v = try c.decodeIfPresent(Bool.self, forKey: .ignoreCommentOnlyLines) {
            ignoreCommentOnlyLines = v
        }
    }

    private enum CodingKeys: String, CodingKey {
        case lint, warning, error, ignoreCommentOnlyLines
    }
}
